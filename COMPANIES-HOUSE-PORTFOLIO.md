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

CARBON JUSTICE UK LIMITED (CH 17304635) — related legal entity · carbon justice accountability
  └── AD SPECTRUM LIMITED (CH 15155883) — operator-group entity · dormant accounts filed to 30 Sep 2025
```

## Related legal entities

| Entity | Companies House | Role | Incorporated |
|--------|-----------------|------|--------------|
| CARBON JUSTICE UK LIMITED | [17304635](https://find-and-update.company-information.service.gov.uk/company/17304635) | Carbon justice legal entity · OPEN ALL accountability | 26 June 2026 |
| AD SPECTRUM LIMITED | [15155883](https://find-and-update.company-information.service.gov.uk/company/15155883) | Operator-group entity · dormant AA filed 29 Jun 2026 | 22 September 2023 |

Entity manifest: `data/companies-house/entities/carbon-justice-uk.json` · Catalog: `data/carbon-justice/catalog.json` · Surface: [carbonjustice.uk](https://carbonjustice.uk) · Policy: [CARBON-JUSTICE.md](./CARBON-JUSTICE.md)

AD SPECTRUM manifest: `data/companies-house/entities/ad-spectrum-limited.json` · Filing: `data/companies-house/filings/ad-spectrum-accounts-2025.json` · Policy: [docs/AD-SPECTRUM-COMPANIES-HOUSE-ACCOUNTS.md](./docs/AD-SPECTRUM-COMPANIES-HOUSE-ACCOUNTS.md)

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
