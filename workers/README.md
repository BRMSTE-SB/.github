# BRMSTE Quantum GI Worker

Cloudflare Worker bridging IBM Quantum, IBM COS (`brmste-coming-soon`), WatsonX, and Bitcoin anchor attestation.

| Item | Value |
|------|-------|
| Worker name | `brmste-quantum-gi` |
| Account | `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` |
| KV binding | `MINE_EVENTS` → `e1e23aa1d33448ffa1a1dd8b3938961e` |
| Secret | `IBM_QUANTUM_API_KEY` (wrangler secret put — never in repo) |

## Deploy

```bash
export CF_API_TOKEN=<operator-token>
export CF_ACCOUNT_ID=7ea6547b1d6eb1cbd6d0ac5cf960ce2a
bash scripts/deploy-quantum-gi-worker.sh
printf '%s' "$IBM_QUANTUM_API_KEY" | npx wrangler secret put IBM_QUANTUM_API_KEY --config workers/wrangler.toml
```

Dry run: agent shell — `scripts/deploy-quantum-gi-worker.sh --dry-run` (operator does not bash).

## Key routes

| Route | Method | Purpose |
|-------|--------|---------|
| `/health` | GET | Liveness |
| `/substrate/quantum/status.json` | GET | Full quantum + anchor status |
| `/quantum/backends` | GET | Heron r2 backend list |
| `/quantum/attest` | POST | Submit ISA-native Bell circuit |
| `/coin` | GET | `brmste-coin.json` from IBM COS |
| `/watsonx/models` | GET | WatsonX model discovery |

Cron triggers (see `wrangler.toml`): hourly attestation, daily job sync.

See [docs/BRMSTE_IBM_CF_FULL_REPORT.md](../docs/BRMSTE_IBM_CF_FULL_REPORT.md) for architecture and error-1517 fix details.
