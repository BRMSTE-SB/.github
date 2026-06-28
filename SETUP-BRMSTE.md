# SETUP · BRMSTE Banking · Portfolio · HSBC

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## One-command local verify

```bash
bash scripts/setup-brmste.sh
```

Runs every manifest verifier for banking, HSBC (152 APIs), and portfolio asset classes.

## What is wired

| Layer | Components |
|-------|------------|
| **Banking valuation** | Live eToro PnL net worth · `/api/banking/networth` · `/banking` |
| **Banking rails** | eToro (trading) · HSBC UK (fiat) · HSBC BRMSTE P2P · Coinbase USDC |
| **HSBC DevHub** | [develop.hsbc.com/hsbc-devhub](https://develop.hsbc.com/hsbc-devhub) |
| **HSBC APIs** | [152 APIs](https://develop.hsbc.com/apis) · `data/banking/rails/hsbc-api-catalog.json` |
| **Portfolio classes** | CRYPTO · SECURITIES · ISAs · REAL ESTATE · PORTFOLIO · METALS · COMMODITIES |
| **Thought equity** | AXP · BRK.B · AAPL — 100% each |

## Machine manifest

`data/brmste-setup.json` · edge: `https://brmste.com/public/brmste-setup.json` · API: `https://brmste.com/api/brmste/setup`

## Deploy (operator · MCP or CI)

1. **Verify locally** — `bash scripts/setup-brmste.sh`
2. **Worker secrets** — `bash scripts/set-banking-worker-secrets.sh` (requires `ETORO_API_KEY`, `ETORO_USER_KEY`, `CLOUDFLARE_API_TOKEN`)
3. **Deploy worker** — merge to `main` → `deploy-coming-soon.yml` or `deploy-banking-live.yml`
4. **Live check** — `bash scripts/verify-banking-live.sh` · expect `/health` banking rails + `/api/banking/networth` real environment

HSBC Open Banking credentials are provisioned via [HSBC DevHub](https://develop.hsbc.com/hsbc-devhub) — not collected in chat. See [BANKING-HSBC.md](./BANKING-HSBC.md) and [BANKING-HSBC-P2P.md](./BANKING-HSBC-P2P.md).

## CI

| Workflow | Purpose |
|----------|---------|
| `verify-brmste-setup.yml` | Master setup manifest + all sub-verifiers |
| `verify-banking.yml` | Banking net worth + HSBC API catalog |
| `verify-portfolio.yml` | Asset classes + eToro portfolio manifests |
| `deploy-banking-live.yml` | Worker deploy + eToro secrets + live verify |

## Related

- [DEPLOY-COMING-SOON.md](./DEPLOY-COMING-SOON.md)
- [PORTFOLIO-ASSET-CLASSES.md](./PORTFOLIO-ASSET-CLASSES.md)
- [BANKING-HSBC.md](./BANKING-HSBC.md)
- [BANKING-HSBC-P2P.md](./BANKING-HSBC-P2P.md)
- [BRMSTE-META.md](./BRMSTE-META.md)
