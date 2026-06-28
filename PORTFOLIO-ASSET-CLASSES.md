# Portfolio · Asset classes

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## Headline

```
CRYPTO · SECURITIES · ISAs · REAL ESTATE · PORTFOLIO · METALS · COMMODITIES
```

Canonical taxonomy for BRMSTE portfolio surfaces — each class maps to an open-lane manifest, division, or execution rail.

## Asset classes

| Class | Label | Role | Primary surface |
|-------|-------|------|-----------------|
| **Crypto** | CRYPTO | BRMSTE USDC · Coinbase settlement | [brmste-meta.json](data/brmste-meta.json) |
| **Securities** | SECURITIES | Listed equities · eToro real | [AXP · BRK.B · AAPL](data/portfolios/axp-brk-aapl-100.json) |
| **ISAs** | ISAs | UK tax wrappers · GBP · HSBC + eToro | [brmste.com/banking](https://brmste.com/banking) |
| **Real Estate** | REAL ESTATE | Real assets · SHA-pinned marks | [brmste.com/collider](https://brmste.com/collider) |
| **Portfolio** | PORTFOLIO | Thought-equity bundles · live net worth | [brmste.com/portfolio](https://brmste.com/portfolio) |
| **Metals** | METALS | Leading Metals commerce | [leadingmetals.com](https://leadingmetals.com) |
| **Commodities** | COMMODITIES | Commodity sleeve · Leading Metalloys | [leadingmetalloys.com](https://leadingmetalloys.com) |

## Rails by class

| Class | Execution / custody |
|-------|---------------------|
| Crypto | Coinbase · USDC · BRMSTE META |
| Securities | eToro PnL · real environment · leverage 1× |
| ISAs | HSBC UK fiat · UK Open Banking · GBP |
| Real Estate | BRMSTE Real Assets mini account · USDC/coinbase |
| Portfolio | eToro sleeves + `/api/banking/networth` |
| Metals | Leading Group · PayPal + USDC/coinbase |
| Commodities | Leading Group · metals adjacency |

## Surfaces

| Surface | URL |
|---------|-----|
| Portfolio | [brmste.com/portfolio](https://brmste.com/portfolio) |
| Asset-class catalog | [brmste.com/public/portfolios/asset-classes.json](https://brmste.com/public/portfolios/asset-classes.json) |
| Banking valuation | [brmste.com/banking](https://brmste.com/banking) |

Machine manifest: `data/portfolios/asset-classes.json`

## Verify

```bash
bash scripts/verify-portfolio-asset-classes.sh
bash scripts/verify-portfolio-manifest.sh
```

## Related

- [COMPANIES-HOUSE-PORTFOLIO.md](./COMPANIES-HOUSE-PORTFOLIO.md) — corporate mini accounts
- [BANKING-HSBC.md](./BANKING-HSBC.md) — HSBC UK fiat rail
- [BRMSTE-META.md](./BRMSTE-META.md) — crypto settlement identity
