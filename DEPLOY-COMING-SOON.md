# BRMSTE Coming Soon — Deploy to All 38 Cloudflare Zones

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## What this does

1. Deploys the `brmste-com-coming-soon` Cloudflare Worker (static coming-soon page + `/health`)
2. **Auto-discovers every active zone** in Cloudflare account `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`
3. Attaches a Worker route `*<zone>/*` → `brmste-com-coming-soon` on each zone
4. Syncs `domains/manifest.json` from the live zone list

> **Warning:** This replaces the apex route on each zone. Existing Workers on `brmste.com`, `re-tyre.com`, etc. will stop serving until routes are restored.

## Prerequisites

| Secret | Scope |
|--------|--------|
| `CF_API_TOKEN` | Workers:Edit + Zone:Read + Zone:Worker Routes:Edit on all zones |
| `CF_ACCOUNT_ID` | `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` |

Add these in **GitHub → BRMSTE-SB/.github → Settings → Secrets → Actions**.

## Deploy via GitHub Actions (recommended)

1. Merge this branch to `main`
2. **Actions → BRMSTE Coming Soon — Deploy to All CF Zones → Run workflow**
3. Verify: `curl -s https://brmste.com/health` should return `{"ok":true,"page":"brmste-coming-soon-v3",...}`

## Deploy locally (from THE KOHINOOR MAC)

```bash
export CF_API_TOKEN="..."   # from Cloudflare dashboard
export CF_ACCOUNT_ID="7ea6547b1d6eb1cbd6d0ac5cf960ce2a"

cd coming-soon && npm ci && npm run deploy
cd .. && bash scripts/deploy-coming-soon-all-zones.sh
```

Dry-run routes first:

```bash
CF_API_TOKEN="..." bash scripts/deploy-coming-soon-all-zones.sh --dry-run
```

## Source layout

| Path | Purpose |
|------|---------|
| `coming-soon/src/index.js` | Worker handler (matches live `brmste-com-coming-soon`) |
| `coming-soon/site/` | Static assets (`index.html`, `brand.html`, CSS, logos) |
| `scripts/deploy-coming-soon-all-zones.sh` | Lists zones + attaches routes |
| `scripts/sync-cf-zones-to-manifest.sh` | Writes `domains/manifest.json` from API |

Local Desktop copy: sync `coming-soon/site/` with `/Users/sachindabas/Desktop/brmste-coming-soon` before deploy if you have newer assets there.
