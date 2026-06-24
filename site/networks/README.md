# BRMSTE Networks — `brmste.com/networks`

The production page for **BRMSTE Networks**. It is a single self-contained
`index.html` that pulls **live** Bitcoin & Lightning telemetry **client-side**
from [mempool.space](https://mempool.space) (CORS-enabled), so it needs **no
backend** and works the moment it is served on `brmste.com/networks`.

- Vision constant `8^8 = 2^24 = 16,777,216` is self-verified in the browser.
- Live Lightning node/channel/capacity figures + the declared on-chain address
  status (shown honestly — an empty address reads "Unfunded").
- Brand-matched to the BRMSTE gold / emerald / obsidian system.

## Files

| File | Purpose |
|------|---------|
| `index.html` | The page (self-contained: inline CSS/SVG/JS, no dependencies) |
| `worker.js` | Cloudflare Worker that serves the page at `/networks` |
| `wrangler.toml` | Worker config + route `brmste.com/networks*` |

## Deploy — pick one

### Option A — Cloudflare Worker route (recommended, no SPA changes)

Because `brmste.com` is already fronted by Cloudflare, a Worker bound to the
route `brmste.com/networks*` intercepts that path at the edge **before** the SPA
origin — so you add `/networks` without modifying the main site repo.

```bash
cd site/networks
npx wrangler login            # or set CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID
npx wrangler deploy
```

Or run the **Deploy BRMSTE Networks (Cloudflare)** GitHub Action
(`.github/workflows/deploy-networks.yml`) after adding these secrets:

- `CLOUDFLARE_API_TOKEN` — token with *Workers Scripts: Edit* and access to the
  `brmste.com` zone (*Workers Routes: Edit*).
- `CLOUDFLARE_ACCOUNT_ID` — the account that owns the `brmste.com` zone.

### Option B — drop into the brmste.com site repo

Copy `index.html` to the site's published output as `/networks/index.html`
(e.g. `public/networks/index.html` for a Vite build), then redeploy the site.
No other changes are required — the page is standalone.

### Option C — Cloudflare Pages project + route

Deploy this folder as a Pages project and map `brmste.com/networks` to it via a
Pages custom-domain path / Cloudflare route.

## Verify after deploy

```bash
curl -sI https://brmste.com/networks | head -n1      # expect HTTP/2 200
```

Then open `https://brmste.com/networks` — the tiles populate from
`mempool.space` within a second and refresh every 60s.

## Local preview

```bash
cd site && python3 -m http.server 8099
# open http://localhost:8099/networks/
```
