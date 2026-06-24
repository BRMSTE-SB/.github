// BRMSTE Brainstem · Non-Invasive Neural Edge — DSP verification.
// Pure-Node tests (no dependencies). Run: `node dsp.test.mjs`
// These prove the signal-processing maths is real: known inputs -> known band outputs.

import assert from "node:assert/strict";
import {
  fft,
  powerSpectrum,
  analyze,
  EEG_BANDS,
  generateSyntheticEEG,
} from "./dsp.js";

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (err) {
    console.error(`FAIL  ${name}`);
    console.error(String(err && err.stack ? err.stack : err));
    process.exitCode = 1;
  }
}

/** Build a pure cosine tone. */
function tone(freq, sampleRate, n, amp = 1) {
  const s = new Float64Array(n);
  for (let i = 0; i < n; i++) s[i] = amp * Math.cos((2 * Math.PI * freq * i) / sampleRate);
  return s;
}

console.log("BRMSTE Neural Edge — DSP tests\n");

// 1. FFT delta function -> flat magnitude spectrum (sanity of the transform itself).
test("fft: unit impulse has flat magnitude across all bins", () => {
  const N = 8;
  const re = new Float64Array(N);
  const im = new Float64Array(N);
  re[0] = 1;
  fft(re, im);
  for (let i = 0; i < N; i++) {
    const mag = Math.hypot(re[i], im[i]);
    assert.ok(Math.abs(mag - 1) < 1e-9, `bin ${i} magnitude ${mag} != 1`);
  }
});

// 2. FFT of a pure on-bin tone -> single spectral line at the right bin.
test("fft: pure tone resolves to a single bin", () => {
  const N = 64;
  const k = 5; // 5 cycles across the window
  const re = new Float64Array(N);
  const im = new Float64Array(N);
  for (let i = 0; i < N; i++) re[i] = Math.cos((2 * Math.PI * k * i) / N);
  fft(re, im);
  let domIdx = -1;
  let domMag = -1;
  for (let i = 0; i < N >> 1; i++) {
    const mag = Math.hypot(re[i], im[i]);
    if (mag > domMag) {
      domMag = mag;
      domIdx = i;
    }
  }
  assert.equal(domIdx, k, `expected peak at bin ${k}, got ${domIdx}`);
});

// 3. Dominant-frequency detection: a 10 Hz tone is reported as ~10 Hz.
test("analyze: 10 Hz tone -> dominantFreq ~= 10 Hz and alpha band dominates", () => {
  const fs = 256;
  const s = tone(10, fs, fs); // 1 s window, 10 Hz lands exactly on a 1 Hz bin
  const a = analyze(s, fs);
  assert.ok(Math.abs(a.dominantFreq - 10) <= a.binWidth + 1e-9, `dominantFreq=${a.dominantFreq}`);
  assert.equal(a.dominantBand, "alpha", `dominantBand=${a.dominantBand}`);
  assert.ok(a.relative.alpha > 0.6, `alpha relative power too low: ${a.relative.alpha}`);
});

// 4. Each canonical band can be selectively excited by its centre tone.
test("analyze: tones map to the correct EEG band", () => {
  const fs = 256;
  const cases = [
    [2.5, "delta"],
    [6, "theta"],
    [10, "alpha"],
    [20, "beta"],
    [38, "gamma"],
  ];
  for (const [f, expected] of cases) {
    const a = analyze(tone(f, fs, fs), fs);
    assert.equal(a.dominantBand, expected, `${f} Hz -> ${a.dominantBand}, expected ${expected}`);
  }
});

// 5. Power is strictly positive for a real signal, zero for silence.
test("powerSpectrum: silence has ~zero power, signal has positive power", () => {
  const fs = 256;
  const silence = new Float64Array(fs);
  const ps0 = powerSpectrum(silence, fs);
  let sum0 = 0;
  for (const p of ps0.power) sum0 += p;
  assert.ok(sum0 < 1e-9, `silence power should be ~0, got ${sum0}`);

  const ps1 = powerSpectrum(tone(10, fs, fs), fs);
  let sum1 = 0;
  for (const p of ps1.power) sum1 += p;
  assert.ok(sum1 > 0, "tone power should be > 0");
});

// 6. Synthetic states behave physiologically: focused is more "beta/focused" than relaxed.
test("synthetic: focused state has higher focus index than relaxed state", () => {
  const fs = 256;
  const relaxed = analyze(generateSyntheticEEG({ sampleRate: fs, durationSec: 2, state: "relaxed", seed: 7 }), fs);
  const focused = analyze(generateSyntheticEEG({ sampleRate: fs, durationSec: 2, state: "focused", seed: 7 }), fs);
  assert.ok(
    focused.focusIndex > relaxed.focusIndex,
    `focused focusIndex (${focused.focusIndex.toFixed(3)}) should exceed relaxed (${relaxed.focusIndex.toFixed(3)})`,
  );
  assert.ok(
    relaxed.calmIndex > focused.calmIndex,
    `relaxed calmIndex (${relaxed.calmIndex.toFixed(3)}) should exceed focused (${focused.calmIndex.toFixed(3)})`,
  );
});

// 7. Relaxed (eyes-closed) synthetic signal should read as alpha-dominant.
test("synthetic: relaxed state is alpha-dominant", () => {
  const fs = 256;
  const relaxed = analyze(generateSyntheticEEG({ sampleRate: fs, durationSec: 2, state: "relaxed", seed: 3 }), fs);
  assert.equal(relaxed.dominantBand, "alpha", `relaxed dominantBand=${relaxed.dominantBand}`);
});

// 8. Determinism: same seed -> identical buffer.
test("synthetic: deterministic for a fixed seed", () => {
  const a = generateSyntheticEEG({ seed: 42 });
  const b = generateSyntheticEEG({ seed: 42 });
  assert.equal(a.length, b.length);
  for (let i = 0; i < a.length; i++) assert.equal(a[i], b[i]);
});

// 9. Band table is well-formed and contiguous from 0.5 to 45 Hz.
test("EEG_BANDS: contiguous, ascending, covers 0.5–45 Hz", () => {
  const order = ["delta", "theta", "alpha", "beta", "gamma"];
  let prevHi = 0.5;
  for (const name of order) {
    const [lo, hi] = EEG_BANDS[name];
    assert.equal(lo, prevHi, `${name} lo ${lo} should equal previous hi ${prevHi}`);
    assert.ok(hi > lo, `${name} hi ${hi} must exceed lo ${lo}`);
    prevHi = hi;
  }
  assert.equal(prevHi, 45, "bands should reach 45 Hz");
});

console.log(`\n${passed} test(s) passed.`);
if (process.exitCode) console.error("\nDSP TESTS FAILED");
else console.log("DSP TESTS PASSED");
