# BRMSTE Coming Soon — Deploy to All 38 Cloudflare Zones

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## What this does

1. Deploys the `brmste-com-coming-soon` Cloudflare Worker (static coming-soon page + `/health`)
2. **Auto-discovers every active zone** in Cloudflare account `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`
3. Attaches a Worker route `*<zone>/*` → `brmste-com-coming-soon` on each zone
4. Syncs `domains/manifest.json` from the live zone list

**carbonjustice.uk:** when the zone is active in Cloudflare, the worker serves the full carbon justice catalog at `/` (software, clients, infrastructure). Verify: `curl -s https://carbonjustice.uk/health` → `"surface":"carbon-justice"`.

### carbonjustice.uk go-live checklist

| Step | Action | Verify |
|------|--------|--------|
| 1 | Deploy worker v5 (MCP or CI below) | `curl -s https://brmste.com/health` → `"page":"brmste-coming-soon-v5"` |
| 2 | Cloudflare Dashboard → **carbonjustice.uk** → **DNS** → proxied **A** `@` → `192.0.2.1` | `dig @1.1.1.1 +short carbonjustice.uk A` returns an IP |
| 3 | Nameservers on Cloudflare (if not already) | `dig @1.1.1.1 +short carbonjustice.uk NS` → `*.ns.cloudflare.com` |
| 4 | CI route script runs on deploy (or add `*carbonjustice.uk/*` route manually) | `curl -s https://carbonjustice.uk/health` → `"domain":"carbonjustice.uk"` |

Diagnose blockers: `bash scripts/check-coming-soon-deploy.sh`

> **Warning:** This replaces the apex route on each zone. Existing Workers on `brmste.com`, `re-tyre.com`, etc. will stop serving until routes are restored.

## Deploy via MCP (Cursor agent — strict)

Agents **must not ask for API tokens in chat**. Use connected MCP servers:

| Step | MCP server | Tool |
|------|------------|------|
| Inventory | `Cloudflare-bindings` | `workers_list`, `workers_get_worker` (`scriptName: brmste-com-coming-soon`) |
| Deploy | `Cloudflare-builds` | Connect in **Cursor → Settings → Tools & MCP**, then use build/deploy tools |
| Verify | shell or observability | `curl https://brmste.com/health` → `"page":"brmste-coming-soon-v5"` |

If `Cloudflare-builds` shows **needsAuth**: operator connects it in Cursor UI — agent does **not** request `CF_API_TOKEN`.

Policy: [docs/MCP-AGENT-POLICY.md](docs/MCP-AGENT-POLICY.md) · rules: `.cursor/rules/mcp-strict-only.mdc`

## Deploy via GitHub Actions (operator CI)

Repository secrets are configured by the operator in **GitHub → Settings → Secrets → Actions** (never pasted in chat):

| Secret | Scope |
|--------|--------|
| `CF_API_TOKEN` | Workers:Edit + Zone:Read + Zone:Worker Routes:Edit on all zones |
| `CF_ACCOUNT_ID` | `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` |

1. Merge to `main`
2. **Actions → BRMSTE Coming Soon — Deploy to All CF Zones → Run workflow**
3. Verify: `curl -s https://brmste.com/health` should return `{"ok":true,"page":"brmste-coming-soon-v5",...}`

## Local preview (no credentials)

```bash
cd coming-soon && npm ci && npx wrangler dev
```

## Route attachment script (CI or operator shell)

Used by GitHub Actions after worker deploy. Secrets come from CI environment — not from agent chat:

```bash
bash scripts/deploy-coming-soon-all-zones.sh
bash scripts/deploy-coming-soon-all-zones.sh --dry-run
```

## Source layout

| Path | Purpose |
|------|---------|
| `coming-soon/src/index.js` | Worker handler (matches live `brmste-com-coming-soon`) |
| `coming-soon/site/` | Static assets (`index.html`, `brand.html`, CSS, logos) |
| `scripts/deploy-coming-soon-all-zones.sh` | Lists zones + attaches routes |
| `scripts/sync-cf-zones-to-manifest.sh` | Writes `domains/manifest.json` from API |

Local Desktop copy (theme source of truth):

```bash
bash scripts/sync-desktop-coming-soon-theme.sh
```

See [coming-soon/THEME-SOURCE.md](coming-soon/THEME-SOURCE.md) · Desktop path: `/Users/sachindabas/Desktop/brmste-coming-soon`
