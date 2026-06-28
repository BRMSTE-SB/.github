# Banking · HSBC UK fiat rail

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## Definition

**HSBC UK** is the **fiat custody rail** for BRMSTE corporate banking — GBP account information and settlement under UK Open Banking (PSD2).

```
BRMSTE banking rails = eToro (trading valuation) · Coinbase (USDC settlement) · HSBC UK (GBP fiat)
```

| Rail | Provider | Role | Currency |
|------|----------|------|----------|
| **Trading** | eToro | Live net worth valuation from PnL | USD |
| **Settlement** | Coinbase | BRMSTE USDC on/off-ramp | USDC |
| **Fiat** | HSBC UK | Corporate GBP custody · Open Banking AIS | GBP |

## HSBC UK · fiat rail

| Field | Value |
|-------|-------|
| **Provider** | HSBC UK Bank plc |
| **Entity** | BRMSTE LTD · CH 15310393 |
| **Standard** | UK Open Banking (PSD2) |
| **Environment** | Real only — no sandbox substitution on production banking surfaces |
| **Developer portal** | [develop.hsbc.com](https://develop.hsbc.com/) |
| **DevHub** | [develop.hsbc.com/hsbc-devhub](https://develop.hsbc.com/hsbc-devhub) |

Register on the HSBC Developer Portal, then use **DevHub** to create a project and obtain sandbox credentials (client ID, certificates, encryption keys) for UK Open Banking API integration.

## Surfaces

| Surface | URL |
|---------|-----|
| Banking valuation | [brmste.com/banking](https://brmste.com/banking) |
| Net worth API | [brmste.com/api/banking/networth](https://brmste.com/api/banking/networth) |
| HSBC rail manifest | [brmste.com/public/banking/rails/hsbc.json](https://brmste.com/public/banking/rails/hsbc.json) |

Machine manifest: `data/banking/rails/hsbc.json`

Parent banking manifest: `data/banking/networth-valuation.json`

## Verify

```bash
bash scripts/verify-banking-manifest.sh
```

## Related

- [BANKING-HSBC-P2P.md](./BANKING-HSBC-P2P.md) — HSBC BRMSTE peer-to-peer domestic payments (PIS)
- [BRMSTE-META.md](./BRMSTE-META.md) — USDC · Coinbase settlement (not Meta Platforms)
- [COMPANIES-HOUSE-PORTFOLIO.md](./COMPANIES-HOUSE-PORTFOLIO.md) — BRMSTE LTD corporate portfolio
