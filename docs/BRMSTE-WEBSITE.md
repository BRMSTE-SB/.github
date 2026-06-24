# BRMSTE.com website · Nemotron Ultra

**Domain:** [brmste.com](https://brmste.com)  
**Builder:** NVIDIA **Nemotron 3 Ultra** (`nvidia/nemotron-3-ultra-550b-a55b`)  
**Operator:** Dr. Shravan Bansal · BRMSTE LTD

## Stack

| Path | Purpose |
|------|---------|
| `website/` | Vite + React static site |
| `website/src/data/generated-content.json` | Site copy (Nemotron-generated or static fallback) |
| `data/nemotron-ultra-lane.json` | Nemotron Ultra lane register |
| `scripts/nemotron-ultra-build.mjs` | Generate content via NVIDIA API |

## Local dev

```bash
cd website
npm install
npm run dev
```

Open http://localhost:5173

## Generate content with Nemotron Ultra

Add to Fort Knox (never commit):

```
NEMOTRON_API_KEY=nvapi-...
```

Or Mac key file: `NEMOTRON-ULTRA.txt` in your AI keys folder.

```bash
set -a && source .env.fort-knox && set +a
node scripts/nemotron-ultra-build.mjs
cd website && npm run build
```

## Deploy (Netlify)

```bash
cd website
npm ci && npm run build
```

Publish directory: `website/dist`  
Config: `website/netlify.toml`

## Brand

Canonical logos only — see [BRAND.md](../BRAND.md).

BRMSTE LTD · GB2607860
