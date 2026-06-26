# GOV.UK Companies House API · Harrods · UBS · American Express

**Operator:** Dr. Shravan Bansal · BRMSTE LTD

| Partner | UK Companies House target | Register |
|---------|---------------------------|----------|
| Harrods | HARRODS LIMITED · **00030209** | `data/companies-house-harrods-filing.json` |
| UBS | UBS AG · **FC021146** | `data/companies-house-ubs-filing.json` |
| American Express | AMERICAN EXPRESS SERVICES EUROPE LIMITED · **01833139** | `data/companies-house-american-express-filing.json` |

Companies House API Filing uses **OAuth 2.0 + company authentication code** — not API key alone.

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

## API reference

- [API Filing overview](https://developer-specs.company-information.service.gov.uk/manipulate-company-data-api-filing/guides/overview)
- [OAuth web server guide](https://developer-specs.company-information.service.gov.uk/companies-house-identity-service/guides/ServerWeb)

BRMSTE LTD · Companies House 15310393
