# BRMSTE IBM Quantum × Cloudflare — Deploy Guide

**BRMSTE LTD · Companies House 15310393 · GB2607860**

Index for the IBM Quantum GI worker, Code Engine BRM API, and operator runbooks delivered 2026-07-08.

## What was integrated

| Path | Purpose |
|------|---------|
| `workers/brmste-quantum-gi.js` | Cloudflare Worker — quantum/coin/COS/WatsonX routes |
| `workers/wrangler.toml` | Worker config, KV binding, cron triggers |
| `brmste-brm-api/main.py` | Flask BRM API for IBM Code Engine |
| `scripts/submit_isa_circuit.py` | CLI: submit ISA-native Bell circuit (fixes error 1517) |
| `scripts/deploy-quantum-gi-worker.sh` | Deploy worker via wrangler |
| `scripts/wire-all-secrets.sh` | Wire CF worker secrets from env (no keys in repo) |
| `scripts/deploy-ibm-full.sh` | Build + deploy BRM API to IBM Code Engine |
| `scripts/brmste-full-finetune.sh` | Fine-tune orchestration (Together/OpenAI/WatsonX) |

## Documentation

| Doc | Content |
|-----|---------|
| [docs/BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md](docs/BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md) | Master runbook — blockers, PR triage, Hetzner fleet |
| [docs/BRMSTE_IBM_CF_FULL_REPORT.md](docs/BRMSTE_IBM_CF_FULL_REPORT.md) | IBM × CF integration report, architecture, error 1517 |
| [docs/BRMSTE-FULL-AUDIT-20260708.md](docs/BRMSTE-FULL-AUDIT-20260708.md) | API audit (redacted) + wire priority list |
| [docs/brmste_skill.md](docs/brmste_skill.md) | BRMSTE patent/codebase assistant skill |
| [docs/BRMSTE_MULTICLOUD_ISV_PACK.pdf](docs/BRMSTE_MULTICLOUD_ISV_PACK.pdf) | Multicloud ISV pack |

## Current Cloudflare status

Worker `brmste-quantum-gi` is **deployed** on account `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` (38 workers total).

Set `IBM_QUANTUM_API_KEY` via wrangler before quantum routes will respond:

```bash
export CF_API_TOKEN=<operator-token>
printf '%s' "$IBM_QUANTUM_API_KEY" | npx wrangler secret put IBM_QUANTUM_API_KEY --config workers/wrangler.toml
```

## Quick deploy (operator)

```bash
# 1. Wire secrets (env-driven — see scripts/wire-all-secrets.sh)
export CF_API_TOKEN=... CF_ACCOUNT_ID=7ea6547b1d6eb1cbd6d0ac5cf960ce2a
export IBM_QUANTUM_API_KEY=...
bash scripts/wire-all-secrets.sh

# 2. Deploy quantum GI worker
bash scripts/deploy-quantum-gi-worker.sh

# 3. Submit ISA attestation job (CLI)
python3 scripts/submit_isa_circuit.py --backend ibm_kingston

# 4. Deploy BRM API to IBM Code Engine
export IBM_API_KEY=...
bash scripts/deploy-ibm-full.sh
```

## Critical blockers (from runbook)

1. **GitHub Actions minutes exhausted** on BRMSTE-SB org — upgrade Team plan or wait for cycle reset
2. **ETORO secrets missing** in GitHub Actions — blocks `deploy-coming-soon.yml` banking step
3. **IBM API key revoked** — generate new at cloud.ibm.com/iam/apikeys

Agents use **MCP** for Cloudflare deploy — never collect tokens in chat. See [docs/MCP-AGENT-POLICY.md](docs/MCP-AGENT-POLICY.md).

## Secrets doctrine

All secret **values** live on Cloudflare (`wrangler secret put`), IBM Code Engine secrets, or GitHub Actions secrets — **never in this public repo**.
