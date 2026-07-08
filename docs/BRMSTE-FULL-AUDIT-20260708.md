# BRMSTE Full Audit + Wire Report (redacted)

**Generated:** 2026-07-08 · BRMSTE LTD · CH 15310393  
**Sign line:** CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

> This public copy has all API keys, tokens, and credential values **removed**.
> Wire secrets via `scripts/wire-all-secrets.sh` with env vars, or Cloudflare/IBM dashboards.

---

## API endpoint status (live test results)

| Service | Status | Detail |
|---------|--------|--------|
| Grok / xAI | LIVE | grok-4.3 responded · 9 models available |
| CoinMarketCap | LIVE | BTC, ETH, USDT, BNB, USDC confirmed |
| Mempool Enterprise | LIVE | fastest: 2 sat/vB · economy: 1 sat/vB |
| Solana (brmste.ai) | LIVE | public RPC slot confirmed |
| Etherscan v2 | LIVE | ETH supply confirmed |
| Serper | 403 | Key rejected — likely expired or wrong tier |
| Anthropic | 401 | Keys rotated — generate new at console.anthropic.com |
| Helius/Solana RPC | 401 | JWT token used instead of RPC key |
| IBM Cloud IAM | BXNIM0415E | Previous API key revoked — generate new |

---

## BRMSTE live worker endpoints

| Endpoint | HTTP | Notes |
|----------|------|-------|
| brmste.ai/mine/stats | 200 | v2.7-tri-chain-hydrate |
| brmste.ai/substrate/capabilities | 200 | silo-operator/v1 |
| brmste.ai/api/sol/health | 200 | Solana functional |
| brmste.ai/api/eth/compete | 200 | gold_standard_commercial |
| brmste.com/substrate/hydrate | 404 | Route not bound |
| brmste.com/substrate/etoro/lane.json | 404 | eToro routes not bound |
| admin.brmste.ai/api/health | 403 | CF Access OTP (correct) |

---

## CF worker inventory

| Worker | KV | Secrets to wire |
|--------|-----|-----------------|
| brmste-mine | BRMSTE_MINE_EVENTS | CMC, Etherscan, Mempool, XAI |
| brmste-glass | — | CMC, Etherscan, Mempool, XAI |
| brmste-admin | BRMSTE_MINE_EVENTS | XAI |
| brmste-shop | — | Stripe, XAI |
| brmste-serper | BRMSTE_MINE_EVENTS | Serper, XAI |
| brmste-etoro | — | ETORO_USER_KEY, ETORO_API_KEY, XAI |
| brmste-786x-voyager | — | IBM_QUANTUM_API_KEY, XAI |
| brmste-quantum-gi | BRMSTE_MINE_EVENTS | IBM_QUANTUM_API_KEY |

KV namespace `BRMSTE_MINE_EVENTS`: `e1e23aa1d33448ffa1a1dd8b3938961e`

---

## Priority action list

| # | Action | URL |
|---|--------|-----|
| 1 | New CF API token | dash.cloudflare.com/profile/api-tokens |
| 2 | New IBM API key | cloud.ibm.com/iam/apikeys |
| 3 | IBM plan upgrade (if over limit) | quantum.cloud.ibm.com |
| 4 | eToro x-api-key | etoro.com/settings → API |
| 5 | Rotate Anthropic key | console.anthropic.com/settings/keys |
| 6 | Helius RPC key | dev.helius.xyz/dashboard |
| 7 | Serper key check | serper.dev/dashboard |

---

## After CF token — run sequence

```bash
export CF_API_TOKEN=<operator-token>
export CF_ACCOUNT_ID=7ea6547b1d6eb1cbd6d0ac5cf960ce2a
export XAI_API_KEY=<from-operator-store>
export ETORO_USER_KEY=<from-operator-store>
export ETORO_API_KEY=<from-operator-store>
export IBM_QUANTUM_API_KEY=<from-operator-store>
bash scripts/wire-all-secrets.sh
bash scripts/deploy-quantum-gi-worker.sh
curl -s https://brmste.com/health | python3 -m json.tool
```

See also: [BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md](BRMSTE_FULL_DEPLOYMENT_RUNBOOK.md) · [DEPLOY-IBM-QUANTUM.md](../DEPLOY-IBM-QUANTUM.md)
