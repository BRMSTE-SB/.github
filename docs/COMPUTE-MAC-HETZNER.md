# Compute routing · Kohinoor Mac + Hetzner (not cloud agents)

**BRMSTE LTD · human-open lane**

Cloud Cursor agents run on ephemeral VMs with limited egress and **no SSH to the Hetzner fleet**. Heavy or long-running work belongs on **THE KOHINOOR MAC** or **Hetzner nodes** — not on the cloud agent CPU.

## Where to run what

| Task | Run on | Command / doc |
|------|--------|----------------|
| `wrangler dev` / header checks | **Kohinoor Mac** | `bash scripts/run-on-kohinoor-mac.sh wrangler-dev` |
| Graphify build / query | **Kohinoor Mac** | `bash scripts/run-on-kohinoor-mac.sh graphify-update` |
| Aikido security scan | **Kohinoor Mac** (desktop Cursor MCP) | `bash scripts/run-on-kohinoor-mac.sh aikido-scan` |
| Desktop theme sync | **Kohinoor Mac** | `bash scripts/sync-desktop-coming-soon-theme.sh` |
| CF Worker deploy | **Kohinoor Mac** (Cloudflare-builds MCP) or **GitHub Actions** | [DEPLOY-COMING-SOON.md](../DEPLOY-COMING-SOON.md) |
| Hetzner fleet deploy (md-render) | **Kohinoor Mac** → SSH fleet | `bash scripts/deploy-md-render-hetzner.sh` |
| Collect fleet JSON + logos | **Kohinoor Mac** | `bash scripts/download-all-hetzner-to-mac.sh` |
| CF inventory / worker code read | **Cloud agent OK** | `Cloudflare-bindings` MCP (read-only) |
| Git edits, docs, PRs | **Cloud agent OK** | normal git workflow |

## One command on THE KOHINOOR MAC

From a cloned repo (or after `git pull`):

```bash
bash scripts/run-on-kohinoor-mac.sh help
bash scripts/run-on-kohinoor-mac.sh all          # wrangler smoke + graphify + optional aikido
bash scripts/run-on-kohinoor-mac.sh wrangler-dev   # local :8787 preview
bash scripts/run-on-kohinoor-mac.sh verify-headers # no-store on JSON + /health
bash scripts/run-on-kohinoor-mac.sh deploy-ci      # trigger GitHub Actions deploy workflow
```

## Hetzner fleet

SSH to `brmste-*` nodes is **Mac-only** (Fort Knox). Cloud agents cannot reach the fleet.

- Fleet list: [docs/HETZNER-MAC-COLLECT.md](HETZNER-MAC-COLLECT.md)
- MD render origin deploy: `bash scripts/deploy-md-render-hetzner.sh`
- Default build node for dry-runs: `brmste-foundry-pool` or `brmste-leading` (operator choice)

## Cloud agent allowed scope

Agents on Cursor Cloud may:

- Edit source, commit, open PRs
- Call **read-only** MCP (`Cloudflare-bindings`, `Cloudflare-observability`, docs servers)
- Document Mac/Hetzner run steps for the operator

Agents must **not**:

- Run `wrangler dev`, `npm run build`, `graphify update`, or long test loops on the cloud VM
- Ask for API tokens in chat (MCP / CI secrets only)
- Attempt SSH to Hetzner from the cloud VM

## Pending operator actions (fresh data + v5)

1. Merge [PR #57](https://github.com/BRMSTE-SB/.github/pull/57) (fresh JSON / `/health` headers)
2. On **Kohinoor Mac**: connect **Cloudflare-builds** MCP **or** run `bash scripts/run-on-kohinoor-mac.sh deploy-ci`
3. Verify: `curl -s https://brmste.com/health` → `"page":"brmste-coming-soon-v5"` and JSON manifests → `Cache-Control: no-store`

BRMSTE LTD · Shravan Bansal · GB2607860
