# GOV.UK Companies House API · Harrods · UBS · Amex · Airbus · Blackstone · Siemens · Mercedes · Bugatti

**Operator:** Dr. Shravan Bansal · BRMSTE LTD

| Partner | UK Companies House target | Register |
|---------|---------------------------|----------|
| Harrods | HARRODS LIMITED · **00030209** | `data/companies-house-harrods-filing.json` |
| UBS | UBS AG · **FC021146** | `data/companies-house-ubs-filing.json` |
| American Express | AMERICAN EXPRESS SERVICES EUROPE LIMITED · **01833139** | `data/companies-house-american-express-filing.json` |
| Airbus | AIRBUS OPERATIONS LIMITED · **03468788** | `data/companies-house-airbus-filing.json` |
| Blackstone | THE BLACKSTONE GROUP INTERNATIONAL LIMITED · **03949032** | `data/companies-house-blackstone-filing.json` |
| Siemens | SIEMENS PLC · **00727817** | `data/companies-house-siemens-filing.json` |
| Mercedes-Benz | MERCEDES-BENZ UK LIMITED · **02448457** | `data/companies-house-mercedes-filing.json` |
| Bugatti | BUGATTI MOLSHEIM LIMITED · **02180021** | `data/companies-house-bugatti-filing.json` |
| **BRMSTE LTD** | **BRMSTE LTD · 15310393** | `data/brmste-ltd-companies-house-register.json` |

Companies House API Filing uses **OAuth 2.0 + company authentication code** — not API key alone.

## BRMSTE LTD address (15310393)

Canonical: **Unit 5 Sherrington Way, Lister Road, Basingstoke, RG22 4DQ** (registered office)

Correspondence (PSC + director): **Apartment 97, 70 Horseferry Road, London, SW1P 2FE** only — no NW1.

```bash
bash scripts/file-companies-house-brmste-api.sh compare-address
bash scripts/file-companies-house-brmste-api.sh oauth-url
bash scripts/file-companies-house-brmste-api.sh update-address --mark-filed
```

PSC04 correspondence address: see [docs/BRMSTE-COMPANIES-HOUSE-ADDRESS.md](BRMSTE-COMPANIES-HOUSE-ADDRESS.md)

Auth code env: `COMPANIES_HOUSE_BRMSTE_AUTH_CODE`


## Developer Hub · live API key (application `6a3e63f98941ddfd0fd9ec24`)

Create a **live** public-data API key (read company profile, ROA compare):

[Add live API key](https://developer.company-information.service.gov.uk/manage-applications/6a3e63f98941ddfd0fd9ec24/api-key/add/live) · [Update live API key](https://developer.company-information.service.gov.uk/manage-applications/6a3e63f98941ddfd0fd9ec24/update/live)

1. Sign in at the link above and create the key (copy once — it is not shown again).
2. Save to Mac Fort Knox only:

   `Companies House/COMPANIES-HOUSE-API-KEY.txt`

3. Import and verify:

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
bash scripts/verify-companies-house-api-key.sh brmste
bash scripts/file-companies-house-brmste-api.sh compare-address
```

**Note:** API key is **read-only**. Filing (AD01, PSC04 via API) still needs OAuth + `COMPANIES_HOUSE_BRMSTE_AUTH_CODE` from the same Developer Hub app (OAuth web client + redirect URI).

## Live streaming (filings accepted in real time): separate Streaming API key — see [docs/COMPANIES-HOUSE-LIVE-STREAMING.md](COMPANIES-HOUSE-LIVE-STREAMING.md) and `data/brmste-live-companies-house-endpoints.json`.

**Cloudflare Worker (live sync + filing):** [docs/CLOUDFLARE-COMPANIES-HOUSE-LIVE.md](CLOUDFLARE-COMPANIES-HOUSE-LIVE.md) · `bash scripts/deploy-companies-house-worker-mac.sh`

OAuth redirect (Worker): `https://brmste.com/api/ch/oauth/callback` (also register in Developer Hub alongside localhost Mac callback).

Manage app: [developer.company-information.service.gov.uk/manage-applications/6a3e63f98941ddfd0fd9ec24](https://developer.company-information.service.gov.uk/manage-applications/6a3e63f98941ddfd0fd9ec24)

## Developer Hub setup

1. Register at [developer.company-information.service.gov.uk](https://developer.company-information.service.gov.uk)
2. Create **API key** (public data — read company profile)
3. Create **OAuth Web client** with redirect URI:
   ```
   http://127.0.0.1:8765/companies-house/callback
   ```
4. Store credentials in Fort Knox (never commit)

## Mac Fort Knox import

```
/Users/sachindabas/Desktop/API keys - Copy/Companies House/
├── COMPANIES-HOUSE-API-KEY.txt
├── CH-OAUTH-CLIENT-ID.txt
├── CH-OAUTH-CLIENT-SECRET.txt
├── COMPANIES-HOUSE-AUTH-CODE.txt      ← Harrods 6-char code
├── COMPANIES-HOUSE-UBS-AUTH-CODE.txt  ← UBS AG 6-char code
├── COMPANIES-HOUSE-AMEX-AUTH-CODE.txt ← American Express 6-char code
├── COMPANIES-HOUSE-AIRBUS-AUTH-CODE.txt
├── COMPANIES-HOUSE-BLACKSTONE-AUTH-CODE.txt
├── COMPANIES-HOUSE-SIEMENS-AUTH-CODE.txt
├── COMPANIES-HOUSE-MERCEDES-AUTH-CODE.txt
├── COMPANIES-HOUSE-BUGATTI-AUTH-CODE.txt
├── CH-OAUTH-ACCESS-TOKEN.txt          (after OAuth)
└── CH-OAUTH-REFRESH-TOKEN.txt         (after OAuth)
```

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
```

## File on behalf of Harrods

### 1. Verify company (public API)

```bash
bash scripts/file-companies-house-harrods-api.sh profile
```

### 2. OAuth — authorize filing

```bash
bash scripts/file-companies-house-harrods-api.sh oauth-url
```

Open the URL in a browser. Sign in with Companies House account and enter **HARRODS authentication code** when prompted.

### 3. Exchange callback code

```bash
bash scripts/file-companies-house-harrods-api.sh exchange --code 'YOUR_CALLBACK_CODE'
```

Paste `access_token` and `refresh_token` into Fort Knox.

### 4. Submit filing via API

```bash
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-harrods-api.sh file --mark-filed
```

This creates a **transaction** for `00030209`, attaches confirmation-statement if available, **closes** the transaction, and updates [data/companies-house-harrods-filing.json](../data/companies-house-harrods-filing.json).

## File on behalf of UBS AG (FC021146)

```bash
bash scripts/file-companies-house-ubs-api.sh profile
bash scripts/file-companies-house-ubs-api.sh oauth-url
bash scripts/file-companies-house-ubs-api.sh exchange --code 'YOUR_CALLBACK_CODE'
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-ubs-api.sh file --mark-filed
```

Auth code env: `COMPANIES_HOUSE_UBS_AUTH_CODE` · Register: [data/companies-house-ubs-filing.json](../data/companies-house-ubs-filing.json)

## File on behalf of American Express (01833139)

```bash
bash scripts/file-companies-house-american-express-api.sh profile
bash scripts/file-companies-house-american-express-api.sh oauth-url
bash scripts/file-companies-house-american-express-api.sh exchange --code 'YOUR_CALLBACK_CODE'
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-american-express-api.sh file --mark-filed
```

Auth code env: `COMPANIES_HOUSE_AMEX_AUTH_CODE` · Register: [data/companies-house-american-express-filing.json](../data/companies-house-american-express-filing.json)

## File on behalf of equity partners (generic script)

For **Airbus**, **Blackstone**, **Siemens**, **Mercedes-Benz**, and **Bugatti**, use the shared partner API script:

```bash
bash scripts/file-companies-house-partner-api.sh <target> profile
bash scripts/file-companies-house-partner-api.sh <target> oauth-url
bash scripts/file-companies-house-partner-api.sh <target> exchange --code 'YOUR_CALLBACK_CODE'
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-partner-api.sh <target> file --mark-filed
```

Replace `<target>` with: `airbus` · `blackstone` · `siemens` · `mercedes` · `bugatti`

Checklist (WebFiling fallback): `bash scripts/file-companies-house-partner.sh <target> [--mark-filed|--api-profile]`

| Target | Auth code env | CH number |
|--------|---------------|-----------|
| airbus | `COMPANIES_HOUSE_AIRBUS_AUTH_CODE` | 03468788 |
| blackstone | `COMPANIES_HOUSE_BLACKSTONE_AUTH_CODE` | 03949032 |
| siemens | `COMPANIES_HOUSE_SIEMENS_AUTH_CODE` | 00727817 |
| mercedes | `COMPANIES_HOUSE_MERCEDES_AUTH_CODE` | 02448457 |
| bugatti | `COMPANIES_HOUSE_BUGATTI_AUTH_CODE` | 02180021 |

Bootstrap all industrial partner registers:

```bash
python3 scripts/bootstrap-companies-house-industrial-partners.py
```

## Sandbox testing

```bash
export COMPANIES_HOUSE_API_ENV=sandbox
```

Use **Test** API clients from Developer Hub and [test data generator](https://test-data-sandbox.company-information.service.gov.uk) — never test live filings against Harrods until ready.

## Registers

| Register | Path |
|----------|------|
| API config | [data/companies-house-api-config.json](../data/companies-house-api-config.json) |
| Harrods filing | [data/companies-house-harrods-filing.json](../data/companies-house-harrods-filing.json) |
| UBS filing | [data/companies-house-ubs-filing.json](../data/companies-house-ubs-filing.json) |
| American Express filing | [data/companies-house-american-express-filing.json](../data/companies-house-american-express-filing.json) |
| Airbus filing | [data/companies-house-airbus-filing.json](../data/companies-house-airbus-filing.json) |
| Blackstone filing | [data/companies-house-blackstone-filing.json](../data/companies-house-blackstone-filing.json) |
| Siemens filing | [data/companies-house-siemens-filing.json](../data/companies-house-siemens-filing.json) |
| Mercedes filing | [data/companies-house-mercedes-filing.json](../data/companies-house-mercedes-filing.json) |
| Bugatti filing | [data/companies-house-bugatti-filing.json](../data/companies-house-bugatti-filing.json) |

## API reference

- [API Filing overview](https://developer-specs.company-information.service.gov.uk/manipulate-company-data-api-filing/guides/overview)
- [OAuth web server guide](https://developer-specs.company-information.service.gov.uk/companies-house-identity-service/guides/ServerWeb)

BRMSTE LTD · Companies House 15310393
