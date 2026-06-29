# BRMSTE Coming Soon — Deploy to Vercel

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## What this does

1. Deploys the `vercel-coming-soon` static site (BRMSTE brand, collider favicon, `/brand`, `/health`)
2. Targets Vercel-hosted domains such as **`leadingmetals.com`** (listed in `data/hetzner/hydrated-logos.json` as off-Cloudflare)
3. Aligns favicon fleet with the SHA-pinned BRMSTE Carbon Collider Token (`brmste-favicon.svg`, `favicon.svg`)

## Prerequisites

| Secret | Scope |
|--------|--------|
| `VERCEL_TOKEN` | Vercel account token with deploy access |
| `VERCEL_ORG_ID` | Team or user ID |
| `VERCEL_PROJECT_ID` | Project linked to `leadingmetals.com` (or your Vercel project) |

Add these in **GitHub → BRMSTE-SB/.github → Settings → Secrets → Actions**.

Create a token at [vercel.com/account/tokens](https://vercel.com/account/tokens).

Link the project once locally (THE KOHINOOR MAC):

```bash
cd vercel-coming-soon
npm ci
npx vercel link
# copy .vercel/project.json orgId + projectId into GitHub secrets
```

## Deploy via GitHub Actions (recommended)

1. Merge the Vercel workflow branch to `main`
2. **Actions → BRMSTE Vercel Coming Soon → Run workflow**
3. Verify:

```bash
curl -s https://leadingmetals.com/health
curl -sI https://leadingmetals.com/brmste-favicon.svg | head -5
```

Expected health JSON includes `"page":"brmste-coming-soon-v4-vercel"`.

## Deploy locally

```bash
export VERCEL_TOKEN="..."
cd vercel-coming-soon && npm ci && npm run deploy
```

## MCP in Cursor

To manage deployments from Cursor via MCP, authorize Vercel MCP first: [docs/VERCEL-MCP.md](docs/VERCEL-MCP.md)

## Source layout

| Path | Purpose |
|------|---------|
| `vercel-coming-soon/public/` | Static HTML, CSS, BRMSTE assets, collider favicon |
| `vercel-coming-soon/api/health.js` | `/api/health` JSON probe |
| `vercel-coming-soon/vercel.json` | Rewrites, security headers |
| `.cursor/mcp.json` | Official Vercel MCP URL for Cursor |
| `scripts/verify-vercel-coming-soon.sh` | Post-deploy verification |

Local Desktop copy: keep `vercel-coming-soon/public/` in sync with `coming-soon/site/` when brand assets change.
