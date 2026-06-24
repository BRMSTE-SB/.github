# BRMSTE Brainstem · Non-Invasive Neural Edge — `site/neural`

The live edge console for [`NEURAL.md`](../../NEURAL.md): real, dependency-free EEG signal
processing in the browser. Default source is a clearly-labelled **synthetic** generator; link a
non-invasive sensor and the identical pipeline runs on the live stream.

## Files

| File | Role |
|------|------|
| `index.html` | Self-contained edge console UI (inline CSS + SVG, no external assets). |
| `app.js` | UI controller — scope, spectrum, band meters, classifier, device link. |
| `dsp.js` | DSP core — FFT, EEG band power, ratio indices, synthetic source. Pure functions. |
| `dsp.test.mjs` | Node verification of the DSP (no dependencies). |
| `worker.js` / `wrangler.toml` / `.assetsignore` | Cloudflare deploy of `brmste.com/neural*`. |

## Run locally

```bash
node dsp.test.mjs                 # -> "DSP TESTS PASSED"
python3 -m http.server 8099       # open http://localhost:8099/
```

`index.html` loads the DSP as an ES module, so **serve the folder over HTTP** (above) rather
than opening it via `file://`. There is **no backend** — everything runs client-side, and the
real Web Serial / Web Bluetooth device link additionally requires this secure context.

## What is real vs synthetic (honesty doctrine)

- **Real:** the FFT, band powers (δ θ α β γ), and indices — verified by `dsp.test.mjs` and by
  the in-page **DSP SELF-TEST** badge (a 10 Hz tone must resolve to the α band in your browser).
- **Synthetic (default):** a seeded oscillator + noise generator, labelled
  *"SYNTHETIC SOURCE — NOT A REAL BRAIN"* in the UI. It exists so the DSP can be exercised
  without a person attached. It is never presented as a recording.
- **Real device path:** **Link device** opens a vendor-neutral **Web Serial** link (one numeric
  µV sample per line) and feeds the live stream through the same `analyze()` pipeline.

## Deploy (`brmste.com/neural`)

Three options, in order of least effort:

1. **Drop-in static host.** Copy `index.html`, `app.js`, `dsp.js` into the brmste.com site's
   `public/neural/`. No backend required.
2. **Cloudflare Workers (this repo).** Add repo/org secrets `CLOUDFLARE_API_TOKEN` and
   `CLOUDFLARE_ACCOUNT_ID` (account holding the `brmste.com` zone), then run the
   **Deploy BRMSTE Neural Edge** workflow. It serves the `[assets]` at `brmste.com/neural*`.
3. **Manual wrangler.** `cd site/neural && npx wrangler deploy`.

> The deploy workflow is **gated**: with no Cloudflare secrets it validates the DSP and skips
> the publish step rather than failing. This agent's token is scoped to `.github`, so going
> live on the brmste.com host must be done by an operator with the Cloudflare zone.

---

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**
*CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS*
