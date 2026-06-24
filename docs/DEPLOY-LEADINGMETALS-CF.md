# leadingmetals.com — Vercel → Cloudflare cutover

**AD LEADING LIMITED · Companies House 13817062**  
**Worker:** `brmste-com-coming-soon` · **Surface:** Leading Metals green ops at apex

## Current state (verified 2026-06-24)

| Check | Result |
|-------|--------|
| Nameservers | Cloudflare (`eoin`, `kehlani`) |
| Apex A record | `76.76.21.21` → **Vercel** |
| `Server` header | `Vercel` |
| `/health` on Vercel | `NOT_FOUND` |

DNS is on Cloudflare but **traffic still routes to Vercel**. Cutover = fix DNS + deploy worker + attach route.

## What the worker does

On hostname `leadingmetals.com` or `www.leadingmetals.com`:

- `/` → `leadingmetals.html` (green recycling + mining + LSE tickers)
- `/api/gi/leadingmetals/tickers` → ticker JSON
- `/health` → `{ "surface": "leadingmetals", "page": "brmste-coming-soon-v5" }`

Other BRMSTE zones keep coming-soon / brand behaviour.

## Cutover steps

### 1. Remove from Vercel

No Vercel MCP in this agent environment — do manually:

```bash
# CLI (if project linked)
vercel domains rm leadingmetals.com
vercel domains rm www.leadingmetals.com
```

Or: [Vercel Dashboard](https://vercel.com/dashboard) → your project → **Domains** → Remove `leadingmetals.com`.

### 2. Deploy worker (GitHub Actions — recommended)

1. Merge branch with `coming-soon/**` changes to `main`
2. Ensure secrets: `CF_API_TOKEN`, `CF_ACCOUNT_ID` (`7ea6547b1d6eb1cbd6d0ac5cf960ce2a`)
3. **Actions → BRMSTE Coming Soon — Deploy to All CF Zones → Run workflow**

Or locally from Kohinoor Mac:

```bash
export CF_API_TOKEN="..."
export CF_ACCOUNT_ID="7ea6547b1d6eb1cbd6d0ac5cf960ce2a"
cd coming-soon && npm ci && npm run deploy
```

### 3. DNS cutover (remove Vercel IP)

```bash
export CF_API_TOKEN="..."
bash scripts/cutover-leadingmetals-vercel-to-cf.sh --dry-run   # preview
bash scripts/cutover-leadingmetals-vercel-to-cf.sh             # execute
```

This script:

- Deletes A/CNAME records pointing at Vercel (`76.76.21.21` or `vercel` in content)
- Creates **proxied** apex + `www` A records (`192.0.2.1`, orange-cloud)
- Attaches Worker route `*leadingmetals.com/*` → `brmste-com-coming-soon`

### 4. Verify

```bash
curl -s https://leadingmetals.com/health | jq
# expect: .surface == "leadingmetals", .page == "brmste-coming-soon-v5"

curl -sI https://leadingmetals.com/ | grep -i server
# expect: cloudflare (not Vercel)

curl -sI https://leadingmetals.com/ | grep -i x-brmste-surface
# expect: leadingmetals
```

## All domains strategy

| Platform | Role |
|----------|------|
| **Cloudflare Workers** | Primary edge for all BRMSTE zones (38+) via `deploy-coming-soon-all-zones.sh` |
| **Vercel** | **Disconnect** — leadingmetals.com and other CF-owned domains should not dual-host |
| **Git** | `BRMSTE-SB/.github` → `coming-soon/` → `npm run deploy` + route scripts |

Sync zone inventory:

```bash
CF_API_TOKEN=... bash scripts/sync-cf-zones-to-manifest.sh
# writes domains/manifest.json
```

## Vercel MCP note

Vercel MCP is **not configured** in this cloud agent. Domain management here is **Cloudflare-first**:

- DNS + Worker routes via `CF_API_TOKEN`
- Remove Vercel attachments manually or via Vercel CLI on Kohinoor Mac
- Do not run Vercel and CF Worker on the same apex simultaneously

## Related docs

- [DEPLOY-COMING-SOON.md](../DEPLOY-COMING-SOON.md) — all-zone worker deploy
- [AD-LEADING-LSE.md](./AD-LEADING-LSE.md) — tickers + green ops
- [METRALLIUM-OPS.md](./METRALLIUM-OPS.md) — mining field programme

---

BRMSTE LTD · GB2607860 · AD LEADING LIMITED · 13817062
