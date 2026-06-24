// BRMSTE Brainstem · Non-Invasive Neural Edge — UI controller.
// Wires the verified DSP core (./dsp.js) to a live scope, spectrum, band meters and
// classifier. Default source is a clearly-labelled SYNTHETIC generator. A non-invasive
// device (Web Serial / Web Bluetooth) runs the identical pipeline.

import {
  analyze,
  powerSpectrum,
  EEG_BANDS,
  BAND_STATE,
  makeSyntheticSampler,
  generateSyntheticEEG,
} from "./dsp.js";

const FS = 256; // Hz — analysis sample rate
const WINDOW_SEC = 2;
const WINDOW = FS * WINDOW_SEC; // 512 samples
const BAND_ORDER = ["delta", "theta", "alpha", "beta", "gamma"];
const BAND_RANGE_LABEL = {
  delta: "0.5–4",
  theta: "4–8",
  alpha: "8–12",
  beta: "12–30",
  gamma: "30–45",
};
const GOLD = "#d4af37";
const GOLD_SOFT = "#f5e6b8";
const GREEN = "#10b981";
const GRID = "rgba(212,175,55,0.12)";

const $ = (id) => document.getElementById(id);

const state = {
  running: true,
  source: "synthetic", // 'synthetic' | 'device'
  stateName: "relaxed",
  fs: FS,
  tAbs: 0,
  ring: new Float64Array(WINDOW),
  write: 0,
  filled: 0,
  sampler: makeSyntheticSampler({ state: "relaxed", seed: 11 }),
  lastTs: 0,
  device: null,
};

function pushSample(v) {
  state.ring[state.write] = v;
  state.write = (state.write + 1) % WINDOW;
  if (state.filled < WINDOW) state.filled++;
}

/** Fill the whole ring from the current synthetic sampler (seamless, continues tAbs). */
function prefillRing() {
  state.ring = new Float64Array(WINDOW);
  state.write = 0;
  state.filled = 0;
  for (let i = 0; i < WINDOW; i++) {
    pushSample(state.sampler.sample(state.tAbs));
    state.tAbs += 1 / state.fs;
  }
}

/** Return the analysis window oldest→newest. */
function getWindow() {
  const out = new Float64Array(WINDOW);
  for (let i = 0; i < WINDOW; i++) {
    out[i] = state.ring[(state.write + i) % WINDOW];
  }
  return out;
}

// ── Band meters (built once) ────────────────────────────────────────────────
function buildBands() {
  const host = $("bands");
  host.innerHTML = "";
  for (const name of BAND_ORDER) {
    const row = document.createElement("div");
    row.className = "band-row";
    row.innerHTML = `
      <div class="nm">${name} <small>${BAND_RANGE_LABEL[name]}Hz</small></div>
      <div class="meter"><span id="meter-${name}"></span></div>
      <div class="pct" id="pct-${name}">0%</div>`;
    host.appendChild(row);
  }
}

// ── Canvas sizing (crisp on HiDPI) ──────────────────────────────────────────
function fitCanvas(cv) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const w = cv.clientWidth || 640;
  const h = cv.clientHeight || (cv.id === "scope" ? 220 : 200);
  cv.width = Math.round(w * dpr);
  cv.height = Math.round(h * dpr);
  const ctx = cv.getContext("2d");
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  return { ctx, w, h };
}

function drawScope(signal) {
  const cv = $("scope");
  const { ctx, w, h } = fitCanvas(cv);
  ctx.clearRect(0, 0, w, h);

  // centre grid
  ctx.strokeStyle = GRID;
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(0, h / 2);
  ctx.lineTo(w, h / 2);
  ctx.stroke();

  let max = 1e-6;
  for (let i = 0; i < signal.length; i++) max = Math.max(max, Math.abs(signal[i]));
  const scale = (h / 2 - 12) / max;

  const grad = ctx.createLinearGradient(0, 0, w, 0);
  grad.addColorStop(0, GREEN);
  grad.addColorStop(1, GOLD);
  ctx.strokeStyle = grad;
  ctx.lineWidth = 1.6;
  ctx.beginPath();
  for (let i = 0; i < signal.length; i++) {
    const x = (i / (signal.length - 1)) * w;
    const y = h / 2 - signal[i] * scale;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  }
  ctx.stroke();
}

function drawSpectrum(signal) {
  const cv = $("spectrum");
  const { ctx, w, h } = fitCanvas(cv);
  ctx.clearRect(0, 0, w, h);

  const { freqs, power } = powerSpectrum(signal, state.fs);
  const fMax = 45;
  let pMax = 1e-9;
  let nBins = 0;
  for (let i = 0; i < freqs.length; i++) {
    if (freqs[i] > fMax) break;
    pMax = Math.max(pMax, power[i]);
    nBins = i + 1;
  }

  // band background shading + labels
  const bandFill = {
    delta: "rgba(255,255,255,0.03)",
    theta: "rgba(16,185,129,0.05)",
    alpha: "rgba(212,175,55,0.08)",
    beta: "rgba(16,185,129,0.05)",
    gamma: "rgba(255,255,255,0.03)",
  };
  const xOf = (f) => (f / fMax) * w;
  for (const name of BAND_ORDER) {
    const [lo, hi] = EEG_BANDS[name];
    ctx.fillStyle = bandFill[name];
    ctx.fillRect(xOf(lo), 0, xOf(Math.min(hi, fMax)) - xOf(lo), h);
    ctx.fillStyle = "rgba(138,160,189,0.6)";
    ctx.font = "10px ui-monospace, monospace";
    ctx.fillText(name[0].toUpperCase(), (xOf(lo) + xOf(Math.min(hi, fMax))) / 2 - 3, h - 5);
  }

  // baseline
  ctx.strokeStyle = GRID;
  ctx.beginPath();
  ctx.moveTo(0, h - 16);
  ctx.lineTo(w, h - 16);
  ctx.stroke();

  // filled spectrum
  const grad = ctx.createLinearGradient(0, 0, w, 0);
  grad.addColorStop(0, "rgba(16,185,129,0.85)");
  grad.addColorStop(1, "rgba(212,175,55,0.85)");
  ctx.fillStyle = grad;
  ctx.beginPath();
  ctx.moveTo(0, h - 16);
  for (let i = 0; i < nBins; i++) {
    const x = xOf(freqs[i]);
    const y = h - 16 - (power[i] / pMax) * (h - 28);
    ctx.lineTo(x, y);
  }
  ctx.lineTo(xOf(freqs[nBins - 1] || 0), h - 16);
  ctx.closePath();
  ctx.fill();
}

function updateBands(a) {
  for (const name of BAND_ORDER) {
    const pct = Math.round((a.relative[name] || 0) * 100);
    const meter = $(`meter-${name}`);
    const lbl = $(`pct-${name}`);
    if (meter) meter.style.width = `${Math.max(0, Math.min(100, pct))}%`;
    if (lbl) lbl.textContent = `${pct}%`;
  }
}

function updateReadouts(a) {
  $("roDom").textContent = a.dominantFreq.toFixed(1);
  $("roFocus").textContent = a.focusIndex.toFixed(2);
  $("roCalm").textContent = a.calmIndex.toFixed(2);
  $("roFs").textContent = state.fs;
  const st = a.state || BAND_STATE.alpha;
  $("stateGlyph").textContent = st.glyph;
  const lab = $("stateLabel");
  lab.firstChild ? (lab.firstChild.textContent = st.label) : (lab.textContent = st.label);
  $("stateSrc").textContent = state.source === "device" ? "live device" : "synthetic source";
}

// ── Main render tick ────────────────────────────────────────────────────────
function tick(ts) {
  if (state.running) {
    if (state.source === "synthetic") {
      if (!state.lastTs) state.lastTs = ts;
      let dt = (ts - state.lastTs) / 1000;
      state.lastTs = ts;
      if (dt > 0.1) dt = 0.1; // clamp after tab-switch / first frame
      let n = Math.round(dt * state.fs);
      if (n < 1) n = 1;
      if (n > WINDOW) n = WINDOW;
      for (let i = 0; i < n; i++) {
        pushSample(state.sampler.sample(state.tAbs));
        state.tAbs += 1 / state.fs;
      }
    }
    const win = getWindow();
    drawScope(win);
    drawSpectrum(win);
    const a = analyze(win, state.fs);
    updateBands(a);
    updateReadouts(a);
  }
  requestAnimationFrame(tick);
}

// ── Controls ────────────────────────────────────────────────────────────────
function setSource(src) {
  state.source = src;
  for (const b of $("sourceSeg").children) b.classList.toggle("active", b.dataset.src === src);
  $("synthChip").classList.toggle("show", src === "synthetic");
  for (const b of $("stateSeg").children) b.disabled = src !== "synthetic";
  if (src === "device") {
    connectDevice();
  } else {
    $("deviceMsg").textContent = "";
    $("liveDot").classList.add("live");
    prefillRing();
  }
}

function setStateName(name) {
  state.stateName = name;
  state.sampler = makeSyntheticSampler({ state: name, seed: 11 });
  for (const b of $("stateSeg").children) b.classList.toggle("active", b.dataset.state === name);
  if (state.source === "synthetic") prefillRing();
}

function setRunning(run) {
  state.running = run;
  state.lastTs = 0;
  $("runBtn").textContent = run ? "Pause" : "Resume";
  $("liveDot").classList.toggle("live", run && state.source === "synthetic");
}

// ── Real non-invasive device link (honest, degrades cleanly) ────────────────
async function connectDevice() {
  const msg = $("deviceMsg");
  const hasSerial = "serial" in navigator;
  const hasBluetooth = "bluetooth" in navigator;

  if (!hasSerial && !hasBluetooth) {
    msg.innerHTML =
      "This browser exposes neither <b>Web Serial</b> nor <b>Web Bluetooth</b>, so a non-invasive sensor can't be linked here. The synthetic source stays active. Use Chrome/Edge on desktop over HTTPS with a sensor attached.";
    setSource("synthetic");
    return;
  }

  if (hasSerial) {
    try {
      msg.textContent = "Requesting a Web Serial device (numeric µV stream, one sample per line)…";
      const port = await navigator.serial.requestPort();
      await port.open({ baudRate: 115200 });
      state.device = port;
      $("liveDot").classList.add("live");
      msg.innerHTML = "Linked over <b>Web Serial</b> — analysing the live surface stream (assuming " + FS + " Hz).";
      readSerial(port);
      return;
    } catch (err) {
      msg.innerHTML =
        "No serial device selected (" + escapeHtml(err.message || String(err)) +
        "). Staying on the synthetic source. The Web Serial link is the supported reference path for a real non-invasive rig.";
      setSource("synthetic");
      return;
    }
  }

  // Bluetooth present but no Serial: honest about device-specific GATT decoding.
  msg.innerHTML =
    "<b>Web Bluetooth</b> is available but BLE EEG headsets use device-specific GATT encodings; " +
    "this reference ships the vendor-neutral <b>Web Serial</b> numeric link. Synthetic source stays active.";
  setSource("synthetic");
}

async function readSerial(port) {
  const decoder = new TextDecoderStream();
  port.readable.pipeTo(decoder.writable).catch(() => {});
  const reader = decoder.readable.getReader();
  let buf = "";
  try {
    while (port.readable && state.source === "device") {
      const { value, done } = await reader.read();
      if (done) break;
      buf += value;
      let nl;
      while ((nl = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        const num = parseFloat(line);
        if (!Number.isNaN(num)) pushSample(num);
      }
    }
  } catch {
    /* link dropped */
  } finally {
    reader.releaseLock();
  }
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]),
  );
}

// ── In-browser DSP self-test (visible proof the maths runs client-side) ──────
function selfTest() {
  const el = $("selftest");
  try {
    const N = 256;
    const tone = new Float64Array(N);
    for (let i = 0; i < N; i++) tone[i] = Math.cos((2 * Math.PI * 10 * i) / FS); // 10 Hz
    const aTone = analyze(tone, FS);
    const okTone = aTone.dominantBand === "alpha" && Math.abs(aTone.dominantFreq - 10) <= aTone.binWidth + 1e-6;

    const relaxed = analyze(generateSyntheticEEG({ sampleRate: FS, state: "relaxed", seed: 5 }), FS);
    const focused = analyze(generateSyntheticEEG({ sampleRate: FS, state: "focused", seed: 5 }), FS);
    const okStates = focused.focusIndex > relaxed.focusIndex && relaxed.dominantBand === "alpha";

    if (okTone && okStates) {
      el.className = "selftest pass";
      el.innerHTML =
        "✓ DSP SELF-TEST PASS — 10 Hz tone → " + aTone.dominantFreq.toFixed(1) +
        " Hz (α); focused focus-index " + focused.focusIndex.toFixed(2) +
        " &gt; relaxed " + relaxed.focusIndex.toFixed(2) + ". FFT runs in your browser.";
    } else {
      el.className = "selftest fail";
      el.textContent = "✗ DSP SELF-TEST FAIL — tone=" + okTone + " states=" + okStates;
    }
  } catch (err) {
    el.className = "selftest fail";
    el.textContent = "✗ DSP SELF-TEST ERROR — " + (err.message || err);
  }
}

// ── Boot ────────────────────────────────────────────────────────────────────
function init() {
  buildBands();
  selfTest();
  setSource("synthetic");
  setStateName("relaxed");
  setRunning(true);

  $("sourceSeg").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-src]");
    if (b) setSource(b.dataset.src);
  });
  $("stateSeg").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-state]");
    if (b && !b.disabled) setStateName(b.dataset.state);
  });
  $("runBtn").addEventListener("click", () => setRunning(!state.running));
  window.addEventListener("resize", () => {
    if (state.filled) {
      const w = getWindow();
      drawScope(w);
      drawSpectrum(w);
    }
  });

  requestAnimationFrame(tick);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
