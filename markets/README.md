# Markets surface — BusinessScience.ai, Inc. (NASDAQ: BRMS)

Institutional, regulated-grade replacement for `businessscience.ai/markets/`.

This is a self-contained static surface (no build step, no framework) that renders:

- a headline **NASDAQ: BRMS** listing band with live price, change and sparkline;
- a consolidated **cross-exchange** quotes table;
- **commodity programmes** (clearly labelled as non-listed reference programmes);
- jurisdiction / registration coverage; and
- full **regulatory disclosures** and issuer identity.

> **BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

## Why this exists

The previous `/markets/` page showed empty placeholders (`—`, an empty table) with no
live data and a non-institutional presentation. This surface fixes that:

- **Live tickers** wired to the authorized **BizStrat™** feed (see _Live data_ below).
- **No fabricated prices.** When no authorized quote is available the page shows an
  explicit _“Awaiting authorized feed”_ state — a hard requirement for a regulated
  investor surface.
- **Institutional design language** (typography, disclosures, restraint) aligned with
  large-asset-manager investor surfaces.

## Files

| File                  | Purpose                                                      |
| --------------------- | ----------------------------------------------------------- |
| `index.html`          | Markets page markup and section structure                   |
| `assets/styles.css`   | Institutional stylesheet (responsive, reduced-motion aware) |
| `assets/config.js`    | **Single integration point** — issuer, feed, instruments    |
| `assets/markets.js`   | Data layer: fetch, refresh, session state, rendering        |

## Live data

1. Open `assets/config.js`.
2. Set `feed.endpoint` to your authorized BizStrat™ quote endpoint. The page substitutes
   `{symbols}` with a comma-separated symbol list.
3. The endpoint should return JSON. Each instrument may use any of these field aliases:

   ```json
   {
     "symbol": "BRMS",
     "mic": "XNAS",
     "price": 0.0,
     "change": 0.0,
     "changePercent": 0.0,
     "currency": "USD",
     "asOf": "2026-06-19T20:00:00Z",
     "source": "BizStrat™ API",
     "history": [0.0, 0.0, 0.0]
   }
   ```

   If your provider uses a different envelope, adjust `normalizeQuotes()` in
   `assets/markets.js` — rendering logic stays untouched.

4. Populate the registered **ISIN(s)** in `config.js` once allocated.

Refresh cadence is `feed.refreshSeconds` (default 15s). The NASDAQ session indicator
(pre-market / open / after-hours / closed) is computed client-side in US/Eastern time.

## Deploy

Static hosting — copy the `markets/` directory to the web root so it serves at
`https://businessscience.ai/markets/`. No server runtime is required; only the quote
endpoint must be reachable (same-origin or CORS-enabled). **Never embed feed secrets in
`config.js`** — gate the feed behind an authenticated session and set
`feed.withCredentials: true` if required.

## Compliance notes

- Brand assets are inline SVG only (no third-party hotlinked logos), satisfying the
  BRMSTE brand/patent gate.
- All disclosures, issuer identity and patent references are present in the page footer
  and the _Important information_ section.
