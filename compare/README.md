# Peer comparison surface — IBM vs BRMSTE vs META

A self-contained, institutional-grade comparison surface that benchmarks **BRMSTE**
(NASDAQ: BRMS — markets identity *BusinessScience.ai, Inc.*) against two listed
technology incumbents: **International Business Machines** (NYSE: IBM) and
**Meta Platforms** (NASDAQ: META).

> **BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

It renders, with no build step and no framework:

- a **live quote band** (IBM / BRMS / META) wired to the authorized BizStrat™ feed;
- a **side-by-side comparison matrix** of dated, source-attributed static facts;
- an **intellectual-property posture** section (the dimension on which BRMSTE is
  differentiated by a granted patent); and
- **sources & disclosures**, with full issuer identity and patent references.

## Integrity rules (non-negotiable)

- **No fabricated market data.** Prices, changes and market caps appear **only** when
  the authorized BizStrat™ feed returns a quote. Until then every card shows an explicit
  _“Awaiting authorized feed”_ state — the same hard rule used by the BRMSTE `markets/`
  surface.
- **Static facts are dated and attributed.** Every figure in the matrix is labelled
  “as reported” and is traceable to an issuer filing or public register (see _Sources_).
- **No third-party trademarked logos.** Each issuer is represented by an inline-SVG
  monogram tile generated from `config.js`. No external image URLs are hotlinked, so the
  surface stays within the BRMSTE brand/patent gate (`scripts/git-worker-brand-patent-gate.sh`).

## Files

| File                  | Purpose                                                          |
| --------------------- | --------------------------------------------------------------- |
| `index.html`          | Page markup and section structure                               |
| `assets/styles.css`   | Institutional stylesheet (responsive, reduced-motion aware)     |
| `assets/config.js`    | **Single integration point** — issuers, facts, feed, sources    |
| `assets/compare.js`   | Data layer: render, feed polling, GOV.UK filings, degradation   |
| `assets/govuk-live.json` | Live Companies House snapshot (GOV.UK) — sync via `fca/sync_govuk_live.py` |

## Live data

### Market quotes (BizStrat™)

1. Open `assets/config.js`.
2. Set `feed.endpoint` to your authorized BizStrat™ quote endpoint. The page substitutes
   `{symbols}` with a comma-separated symbol list (`IBM,BRMS,META`).
3. The endpoint should return JSON; each instrument may use these field aliases:

   ```json
   {
     "symbol": "IBM",
     "mic": "XNYS",
     "price": 0.0,
     "change": 0.0,
     "changePercent": 0.0,
     "currency": "USD",
     "asOf": "2026-06-24T15:00:00Z",
     "source": "BizStrat™ API"
   }
   ```

   If your provider uses a different envelope, adjust `normalizeQuotes()` in
   `assets/compare.js` — the rendering logic stays untouched.

Refresh cadence is `feed.refreshSeconds` (default 30s). **Never embed feed secrets in
`config.js`** — gate the feed behind an authenticated session and set
`feed.withCredentials: true` if required.

## Comparison data — as reported

| Dimension       | IBM                                  | BRMSTE                                             | META                                  |
| --------------- | ------------------------------------ | -------------------------------------------------- | ------------------------------------- |
| Listing         | NYSE: IBM                            | NASDAQ: BRMS                                        | NASDAQ: META (Class A)                |
| Founded / reg.  | 1911 (incorporated New York)         | UK Companies House 15310393                        | 2004 (IPO 2012; renamed Meta 2021)    |
| Headquarters    | Armonk, New York, USA                | United Kingdom                                     | Menlo Park, California, USA           |
| Headcount       | 264,300 full-time (31 Dec 2025)      | Early-stage · not publicly disclosed               | 77,986 (31 Mar 2026)                  |
| IP posture      | Multi-decade US patent leader        | Granted patent **GB2607860** · PCT/GB2026/050406   | Large product / AI / Reality Labs IP  |
| ISIN            | US4592001014                         | Awaiting allocation                                | US30303M1027                          |
| FCA / UK reg.   | Not applicable · US SEC primary      | **Application in progress** (FCA Connect · PSD individual form · sb@brmste.ai) · not authorised until granted | Not applicable · US SEC primary       |

### Sources

- **IBM** — Form 10-K (FY2025) and company profile: incorporated in New York on
  16 June 1911 as the Computing-Tabulating-Recording Co.; common stock listed NYSE: IBM;
  264,300 full-time employees as of 31 December 2025; ISIN US4592001014.
- **Meta Platforms** — Form 10-K (FY2025) and Q1 2026 results: incorporated in Delaware
  July 2004; Class A common stock listed NASDAQ: META; 77,986 employees as of
  31 March 2026; ISIN US30303M1027.
- **BRMSTE** — BRMSTE LTD, UK Companies House registration **15310393**; granted patent
  **GB2607860** (11 October 2023); international application **PCT/GB2026/050406**.
  Markets identity per the BRMSTE-SB `markets/` surface (NASDAQ: BRMS /
  *BusinessScience.ai, Inc.*).
- **BRMSTE — FCA** — Payment institution application **in progress** via
  [FCA Connect](https://connect.fca.org.uk/) (ApplicationId `a0wSk00000BgPYLIA3`);
  PSD individual form; main contact **sb@brmste.ai**. An application in progress is
  **not** authorisation — BRMSTE LTD is not on the FCA Financial Services Register and
  has **no FRN** until permission is granted. Matches brmste.com edge status
  `AWAITING_FCA_FRN`.

## Deploy

Static hosting — copy the `compare/` directory to the web root so it serves at, e.g.,
`/compare/`. No server runtime is required; only the quote endpoint must be reachable
(same-origin or CORS-enabled).

## Compliance notes

- Brand assets are inline SVG only (no third-party hotlinked logos), satisfying the
  BRMSTE brand/patent gate.
- All disclosures, issuer identity and patent references are present in the page footer
  and the _Sources & basis_ section.
- This surface is informational only and is **not** investment advice or an offer of
  securities. IBM and Meta marks are the property of their respective owners and appear
  here solely for factual comparison.
