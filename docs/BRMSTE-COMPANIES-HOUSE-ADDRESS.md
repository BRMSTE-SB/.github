# BRMSTE LTD · Companies House address update

**Operator:** Dr. Shravan Bansal · **BRMSTE LTD** · Companies House **15310393** · control id **XQ8-863K-2223**

Canonical address (registered office + PSC correspondence):

**Unit 5 Sherrington Way, Lister Road, Basingstoke, England, RG22 4DQ**

| Field | Live GOV.UK (2026-06-26) | Action |
|-------|--------------------------|--------|
| Registered office | Basingstoke (AD01 filed 24 Oct 2025) | Aligned — no AD01 needed unless correcting |
| PSC correspondence (Mr Shravan Bansal) | Apartment 38, Alberts Court, London NW1 6EL | **File PSC04** to Basingstoke |

Public links:

- [Company overview](https://find-and-update.company-information.service.gov.uk/company/15310393)
- [Persons with significant control](https://find-and-update.company-information.service.gov.uk/company/15310393/persons-with-significant-control)
- [Filing history](https://find-and-update.company-information.service.gov.uk/company/15310393/filing-history)

Register: [data/brmste-ltd-companies-house-register.json](../data/brmste-ltd-companies-house-register.json)

## Mac Fort Knox

Add BRMSTE company authentication code:

```
COMPANIES-HOUSE-BRMSTE-AUTH-CODE.txt
```

Import:

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
```

## API — compare live vs canonical

```bash
bash scripts/file-companies-house-brmste-api.sh compare-address
```

## API — OAuth (registered office scope for 15310393)

```bash
bash scripts/file-companies-house-brmste-api.sh oauth-url
bash scripts/file-companies-house-brmste-api.sh exchange --code 'YOUR_CALLBACK_CODE'
```

Sign in with your Companies House account and enter the **BRMSTE LTD** 6-character authentication code when prompted.

## API — sync registered office (AD01 via ROA API)

```bash
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-brmste-api.sh update-address --mark-filed
```

If live registered office already matches canonical Basingstoke, this skips ROA filing and records PSC04 as pending.

## PSC04 — correspondence address (web)

Companies House API Filing exposes **Registered Office Address** via OAuth; **PSC04** (change PSC details / correspondence address) is filed via WebFiling or PSC filing integrations.

1. Sign in at [File changes to a company](https://www.gov.uk/file-changes-to-a-company-with-companies-house)
2. Select **BRMSTE LTD** · **15310393**
3. Choose **Change a person with significant control (PSC) details** (form **PSC04**)
4. Update **correspondence address** for **Mr Shravan Bansal** to:

   Unit 5 Sherrington Way, Lister Road, Basingstoke, England, RG22 4DQ

5. Submit and confirm acceptance on the filing history

After PSC04 is accepted, run:

```bash
python3 scripts/bootstrap-brmste-address-register.py --psc-filed
node scripts/sync-corpus-to-website.mjs
```

## Sweep

`scripts/full-public-sweep.sh` step **17d** validates the address register against canonical Basingstoke fields.
