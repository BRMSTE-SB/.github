// BRMSTE Brainstem · Non-Invasive Neural Edge — DSP core
// Real, dependency-free digital signal processing for surface (non-invasive) neural signals.
// Pure functions only: identical results in the browser and in Node (see dsp.test.mjs).
//
// TRUTH AND HONESTY: the maths here is real. The default in-browser signal source is a
// clearly-labelled SYNTHETIC generator (not a brain). When a non-invasive device is linked
// over Web Serial / Web Bluetooth, these exact functions run over the real sensor stream.

/**
 * In-place iterative radix-2 Cooley–Tukey FFT (forward transform, sign = -1).
 * @param {Float64Array|number[]} re real part (length must be a power of two)
 * @param {Float64Array|number[]} im imaginary part (same length)
 */
export function fft(re, im) {
  const n = re.length;
  if (n <= 1) return;
  if ((n & (n - 1)) !== 0) throw new Error("FFT length must be a power of two");

  // Bit-reversal permutation.
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      const tr = re[i]; re[i] = re[j]; re[j] = tr;
      const ti = im[i]; im[i] = im[j]; im[j] = ti;
    }
  }

  // Danielson–Lanczos butterflies.
  for (let len = 2; len <= n; len <<= 1) {
    const ang = (-2 * Math.PI) / len;
    const wlenRe = Math.cos(ang);
    const wlenIm = Math.sin(ang);
    for (let i = 0; i < n; i += len) {
      let wRe = 1;
      let wIm = 0;
      for (let k = 0; k < len >> 1; k++) {
        const a = i + k;
        const b = a + (len >> 1);
        const vRe = re[b] * wRe - im[b] * wIm;
        const vIm = re[b] * wIm + im[b] * wRe;
        re[b] = re[a] - vRe;
        im[b] = im[a] - vIm;
        re[a] += vRe;
        im[a] += vIm;
        const nwRe = wRe * wlenRe - wIm * wlenIm;
        wIm = wRe * wlenIm + wIm * wlenRe;
        wRe = nwRe;
      }
    }
  }
}

/** Largest power of two <= n. */
export function largestPow2(n) {
  return 1 << Math.floor(Math.log2(n));
}

/**
 * One-sided power spectral density of a real signal.
 * Applies a Hann window to reduce spectral leakage, then FFT.
 * @returns {{freqs:Float64Array, power:Float64Array, fftSize:number, binWidth:number}}
 */
export function powerSpectrum(signal, sampleRate, { window = "hann" } = {}) {
  const n2 = largestPow2(signal.length);
  const re = new Float64Array(n2);
  const im = new Float64Array(n2);

  // Hann window + coherent-gain normalisation so amplitudes stay comparable.
  let coherentGain = 1;
  if (window === "hann") {
    let wsum = 0;
    for (let i = 0; i < n2; i++) {
      const w = 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (n2 - 1));
      re[i] = signal[i] * w;
      wsum += w;
    }
    coherentGain = wsum / n2;
  } else {
    for (let i = 0; i < n2; i++) re[i] = signal[i];
  }

  fft(re, im);

  const half = n2 >> 1;
  const freqs = new Float64Array(half);
  const power = new Float64Array(half);
  const norm = 1 / (n2 * Math.max(coherentGain, 1e-9));
  for (let i = 0; i < half; i++) {
    freqs[i] = (i * sampleRate) / n2;
    power[i] = (re[i] * re[i] + im[i] * im[i]) * norm;
  }
  return { freqs, power, fftSize: n2, binWidth: sampleRate / n2 };
}

/** Sum spectral power across the half-open band [lo, hi) Hz. */
export function bandPower(freqs, power, lo, hi) {
  let sum = 0;
  for (let i = 0; i < freqs.length; i++) {
    if (freqs[i] >= lo && freqs[i] < hi) sum += power[i];
  }
  return sum;
}

/** Canonical clinical EEG bands (Hz). */
export const EEG_BANDS = {
  delta: [0.5, 4],
  theta: [4, 8],
  alpha: [8, 12],
  beta: [12, 30],
  gamma: [30, 45],
};

/** Human-readable interpretation of the dominant band (heuristic, not a diagnosis). */
export const BAND_STATE = {
  delta: { label: "Deep / sleep", glyph: "δ" },
  theta: { label: "Drowsy / meditative", glyph: "θ" },
  alpha: { label: "Relaxed / eyes-closed", glyph: "α" },
  beta: { label: "Focused / engaged", glyph: "β" },
  gamma: { label: "High cognitive load", glyph: "γ" },
};

/**
 * Full analysis of a windowed signal: absolute + relative band powers, the dominant
 * frequency, and standard EEG ratio indices.
 */
export function analyze(signal, sampleRate) {
  const { freqs, power, binWidth, fftSize } = powerSpectrum(signal, sampleRate);

  const bands = {};
  let total = 0;
  for (const [name, [lo, hi]] of Object.entries(EEG_BANDS)) {
    bands[name] = bandPower(freqs, power, lo, hi);
    total += bands[name];
  }

  const relative = {};
  for (const name of Object.keys(bands)) {
    relative[name] = total > 0 ? bands[name] / total : 0;
  }

  // Dominant frequency restricted to the physiological 0.5–45 Hz window.
  let domIdx = -1;
  let domPow = -1;
  for (let i = 0; i < freqs.length; i++) {
    if (freqs[i] >= 0.5 && freqs[i] <= 45 && power[i] > domPow) {
      domPow = power[i];
      domIdx = i;
    }
  }
  const dominantFreq = domIdx >= 0 ? freqs[domIdx] : 0;

  // Dominant band by relative power.
  let domBand = "alpha";
  let best = -1;
  for (const name of Object.keys(relative)) {
    if (relative[name] > best) {
      best = relative[name];
      domBand = name;
    }
  }

  const eps = 1e-12;
  const focusIndex = bands.beta / (bands.alpha + bands.theta + eps);
  const calmIndex = bands.alpha / (bands.alpha + bands.beta + eps);
  const engagement = (bands.beta + bands.gamma) / (bands.alpha + bands.theta + eps);

  return {
    bands,
    relative,
    total,
    dominantFreq,
    dominantBand: domBand,
    state: BAND_STATE[domBand],
    focusIndex,
    calmIndex,
    engagement,
    binWidth,
    fftSize,
  };
}

// ── Honest synthetic signal source ───────────────────────────────────────────
// A SYNTHETIC generator. It is NOT a brain. It exists so the edge DSP can be
// exercised and verified without a person or a sensor attached.

/** Deterministic, seedable PRNG (mulberry32) so synthetic output is reproducible. */
export function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Per-band oscillation amplitudes for canonical mental states. */
export const PROFILES = {
  relaxed: { delta: 8, theta: 6, alpha: 22, beta: 5, gamma: 2 }, // eyes-closed α
  focused: { delta: 5, theta: 5, alpha: 7, beta: 20, gamma: 8 }, // engaged β
  drowsy: { delta: 20, theta: 16, alpha: 8, beta: 3, gamma: 1 }, // δ/θ heavy
  neutral: { delta: 10, theta: 8, alpha: 10, beta: 9, gamma: 4 },
};

/** Representative centre frequency for each band's oscillator. */
export const BAND_CENTERS = {
  delta: 2.5,
  theta: 6,
  alpha: 10,
  beta: 20,
  gamma: 38,
};

/**
 * Generate a fixed-length synthetic EEG-like buffer (microvolt scale).
 * Sum of per-band sinusoids + broadband noise. Deterministic for a given seed.
 */
export function generateSyntheticEEG({
  sampleRate = 256,
  durationSec = 2,
  state = "relaxed",
  custom = null,
  seed = 1,
  noise = 6,
} = {}) {
  const n = Math.round(sampleRate * durationSec);
  const amp = custom || PROFILES[state] || PROFILES.neutral;
  const rnd = mulberry32(seed);
  const phase = {};
  for (const k of Object.keys(BAND_CENTERS)) phase[k] = rnd() * 2 * Math.PI;

  const out = new Float64Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / sampleRate;
    let v = 0;
    for (const k of Object.keys(BAND_CENTERS)) {
      v += amp[k] * Math.sin(2 * Math.PI * BAND_CENTERS[k] * t + phase[k]);
    }
    v += (rnd() * 2 - 1) * noise;
    out[i] = v;
  }
  return out;
}

/**
 * Continuous synthetic sampler for streaming/animation. `sample(t)` returns the
 * value at absolute time t (seconds), so a scope can scroll smoothly.
 */
export function makeSyntheticSampler({ state = "relaxed", custom = null, seed = 1, noise = 6 } = {}) {
  const amp = custom || PROFILES[state] || PROFILES.neutral;
  const rnd = mulberry32(seed);
  const phase = {};
  for (const k of Object.keys(BAND_CENTERS)) phase[k] = rnd() * 2 * Math.PI;
  return {
    amp,
    sample(t) {
      let v = 0;
      for (const k of Object.keys(BAND_CENTERS)) {
        v += amp[k] * Math.sin(2 * Math.PI * BAND_CENTERS[k] * t + phase[k]);
      }
      v += (rnd() * 2 - 1) * noise;
      return v;
    },
  };
}
