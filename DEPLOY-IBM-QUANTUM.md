# DEPLOY-IBM-QUANTUM · agent lane

**BRMSTE LTD · Companies House 15310393 · GB2607860 · INV. G06N3/045**

**OPERATOR DOESNT BASH** — agents deploy via MCP; CI deploys on merge. Operator only connects MCP.

## Agent deploy (MCP-first)

1. **Cloudflare-bindings** → `workers_list` / `workers_get_worker` (`brmste-quantum-gi`)
2. **Cloudflare-builds** → deploy worker (must be connected in Cursor)
3. **Cloudflare-builds** or wrangler in **agent shell** → wire secrets (never ask operator to paste keys)
4. Verify: `curl https://brmste.ai/quantum/health` or observability MCP

## CI deploy (merge to main)

Repository secrets in GitHub Settings — not in chat. Workflows run automatically; operator does not bash.

## What agents run (not the operator)

| Script | Agent / CI only |
|--------|-----------------|
| `scripts/deploy-quantum-gi-worker.sh` | Cloud agent shell |
| `scripts/wire-all-secrets.sh` | Cloud agent (needs MCP-connected CF) |
| `scripts/configure-ibm-quantum-fleet.sh` | Cloud agent shell |
| `scripts/deploy-ibm-full.sh` | CI or agent with IBM MCP/env |
| `scripts/verify-full-https.sh` | Cloud agent shell |
| `scripts/submit_isa_circuit.py` | Cloud agent shell |

## Operator one-time setup (no bash)

**Cursor → Settings → Tools & MCP → Connect:**

- Cloudflare-bindings
- Cloudflare-builds
- Cloudflare-observability

Then ask the agent to deploy — do not run wrangler locally.

## Starmind · INV. G06N3/045

Verifiable multi-model AI consensus — [STARMIND-MYSTERY.md](STARMIND-MYSTERY.md) · [substrate/starmind/mystery.json](https://brmste.com/substrate/starmind/mystery.json)

## Blockers

1. **Cloudflare-builds MCP** needsAuth — operator connects MCP only
2. **GitHub Actions minutes** exhausted on BRMSTE-SB org
3. **BRM API IBM_SERVICE_CRN** invalid on Code Engine (error 1241) — agent or CI redeploy

See [docs/BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md](docs/BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md).
