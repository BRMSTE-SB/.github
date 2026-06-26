# COMPANIES HOUSE PORTFOLIO

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## Definition

The **Companies House portfolio** is the corporate portfolio of BRMSTE LTD — the divisions and brands registered under **Companies House 15310393**, each carried as a **mini account**.

```
BRMSTE LTD (CH 15310393 · GB2607860)
  ├── Re-Tyre        — circular tyre economy
  ├── BRMSTE         — GSI platform · settlement identity (BRMSTE META)
  ├── Leading        — Leading Group of Companies
  └── Real Assets    — SHA-pinned Token of Trust
```

## Mini accounts

| Account | Name | Division | Role | Settlement |
|---------|------|----------|------|------------|
| `retyre` | Re-Tyre | Re-Tyre — circular tyre economy | RE-TYRE-APPS | PayPal + USDC/Coinbase |
| `brmste` | BRMSTE LTD | BRMSTE Platform — GSI | BRMSTE parent · BRMSTE META | USDC/Coinbase + PayPal |
| `leading` | Leading Group of Companies | BRMSTE-LEADING · LEADING GROUP | BRMSTE-LEADING | PayPal + USDC/Coinbase |
| `real-asset` | BRMSTE Real Assets | Real Assets — SHA-pinned Token of Trust | REAL ASSETS · SHA-pinned marks | USDC/Coinbase + marks |

Each mini account is a small, self-contained corporate record: identity (parent `BRMSTE LTD`, CH `15310393`, patent `GB2607860`), division, role, domains, and settlement rail.

## Settlement

- **Real asset:** BRMSTE USDC on **Coinbase** (BRMSTE META — `brmste.com` blockchain · `sb@brmste.ai`).
- **Sales rail:** PayPal only — merchants `me@shravanbansal.com`, `hello@shravanbansal.com`.

See [BRMSTE-META.md](./BRMSTE-META.md) for the settlement identity.

## Surfaces and manifests

- Portfolio manifest: `data/companies-house/portfolio.json`
- Mini-account manifests: `data/companies-house/accounts/*.json`
- Edge surface: `https://brmste.com/companies-house`
- Live substrate bind: `https://brmste.com/substrate/companies-house/portfolio.json`

## Verification

```bash
bash scripts/verify-companies-house-portfolio.sh
```

CI: `.github/workflows/verify-companies-house.yml` validates the portfolio and every mini account on push and pull request.

## Lane

**OPEN ALL · carbon justice only · no BRMSTE charges.** Full stop on Meta — see [META-FULL-STOP.md](./META-FULL-STOP.md).

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

BRMSTE LTD · Companies House 15310393 · GB2607860
