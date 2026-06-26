# BRMSTE LTD · Companies House address — Basingstoke + Horseferry Road only

**Operator:** Dr. Shravan Bansal · **BRMSTE LTD** · Companies House **15310393** · control id **XQ8-863K-2223**

Only these two addresses are permitted on the BRMSTE LTD lane:

| Role | Address | Form |
|------|---------|------|
| **Registered office** | Unit 5 Sherrington Way, Lister Road, Basingstoke, England, **RG22 4DQ** | AD01 (already filed 24 Oct 2025) |
| **PSC + director correspondence** | **70 Horseferry Road**, London, England, **SW1P 2FE** | PSC04 + CH01 |

**Not allowed:** NW1 (Alberts Court, Palgrave Gardens, Annes Court), or any address other than the two above.

Public links:

- [Company overview](https://find-and-update.company-information.service.gov.uk/company/15310393)
- [PSC register](https://find-and-update.company-information.service.gov.uk/company/15310393/persons-with-significant-control)
- [Officers](https://find-and-update.company-information.service.gov.uk/company/15310393/officers)

Register: [data/brmste-ltd-companies-house-register.json](../data/brmste-ltd-companies-house-register.json)

## Mac Fort Knox

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-brmste-api.sh compare-address
```

## Registered office (Basingstoke) — API

```bash
bash scripts/file-companies-house-brmste-api.sh oauth-url
bash scripts/file-companies-house-brmste-api.sh exchange --code 'YOUR_CALLBACK_CODE'
bash scripts/file-companies-house-brmste-api.sh update-address --mark-filed
```

Skips AD01 when live ROA already matches Basingstoke.

## PSC04 + CH01 (Horseferry Road) — WebFiling

1. [File changes to a company](https://www.gov.uk/file-changes-to-a-company-with-companies-house)
2. Company **BRMSTE LTD** · **15310393**
3. **PSC04** — Mr Shravan Bansal correspondence → **70 Horseferry Road, London, SW1P 2FE**
4. **CH01** — Director Shravan Bansal correspondence → same Horseferry Road address

After Companies House accepts both:

```bash
python3 scripts/bootstrap-brmste-address-register.py --psc-filed
node scripts/sync-corpus-to-website.mjs
```
