# GOV.UK Companies House · Live Streaming API · BRMSTE lane

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**

The **Streaming API** pushes real-time changes (filings accepted, officer updates, PSC changes) as they happen. It complements the REST public API (read snapshots) and the **Filing API** (OAuth submit).

**Catalog:** `data/brmste-live-companies-house-endpoints.json`

## Three APIs — do not mix keys

| API | Host | Auth | Purpose |
|-----|------|------|---------|
| **Streaming** | `https://stream.companieshouse.gov.uk` | `COMPANIES_HOUSE_STREAMING_API_KEY` (Basic) | Live events |
| **Public REST** | `https://api.company-information.service.gov.uk` | `COMPANIES_HOUSE_API_KEY` (Basic) | Read company profile, ROA |
| **Filing** | Same as public REST | OAuth bearer + company auth code | Submit AD01, CS01 |

Streaming and REST keys are **not interchangeable**. Register a **Streaming API** application in [Developer Hub](https://developer.company-information.service.gov.uk).

## Mac Fort Knox

```
Companies House/
├── COMPANIES-HOUSE-API-KEY.txt              ← REST read key (app 6a3e63f98941ddfd0fd9ec24)
├── COMPANIES-HOUSE-STREAMING-API-KEY.txt    ← Streaming API key (separate app)
├── CH-OAUTH-CLIENT-ID.txt
├── CH-OAUTH-CLIENT-SECRET.txt
├── COMPANIES-HOUSE-BRMSTE-AUTH-CODE.txt
└── …
```

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
bash scripts/stream-companies-house-live.sh verify-key
bash scripts/stream-companies-house-live.sh list-endpoints --target brmste
```

## Live streaming endpoints (all on `stream.companieshouse.gov.uk`)

| Stream id | Path | Use for live filings |
|-----------|------|----------------------|
| `filings` | `/filings` | **Filing history** — AD01, PSC04, CS01 acceptance |
| `companies` | `/companies` | Company profile / ROA changes |
| `officers` | `/officers` | Director CH01 correspondence |
| `persons-with-significant-control` | `/persons-with-significant-control` | PSC04 register |
| `persons-with-significant-control-statements` | `/persons-with-significant-control-statements` | PSC statements |
| `charges` | `/charges` | Charges register |
| `insolvency-cases` | `/insolvency-cases` | Insolvency |
| `disqualified-officers` | `/disqualified-officers` | Disqualifications |
| `company-exemptions` | `/company-exemptions` | Exemptions |

Optional query: `?timepoint=<integer>` to resume after disconnect.

## Watch BRMSTE lane company numbers

The register filters events to these Companies House numbers:

| Target | Company number |
|--------|----------------|
| BRMSTE LTD | **15310393** |
| Harrods | 00030209 |
| UBS AG | FC021146 |
| American Express | 01833139 |
| Blackstone | 03949032 |
| Siemens | 00727817 |
| Mercedes-Benz UK | 02448457 |
| Bugatti | 02180021 |
| Airbus | 03468788 |
| Sotheby's | 00874867 |

## Commands

```bash
# Full endpoint catalog (streams + public read + filing)
bash scripts/stream-companies-house-live.sh list-endpoints
bash scripts/stream-companies-house-live.sh list-endpoints --target brmste

# Verify streaming key
bash scripts/stream-companies-house-live.sh verify-key

# Watch live filings for BRMSTE LTD (max 10 events then exit)
bash scripts/stream-companies-house-live.sh stream filings --max-events 10 --company-numbers 15310393

Mac Fort Knox file: `Companies House/COMPANIES-HOUSE-STREAMING-API-KEY.txt` → `bash scripts/import-companies-house-keys-mac.sh`

Save streaming key to Mac: `Companies House/COMPANIES-HOUSE-STREAMING-API-KEY.txt` then `bash scripts/import-companies-house-keys-mac.sh`

# Watch all lane companies on filings stream
bash scripts/stream-companies-house-live.sh stream filings --max-events 20

# After OAuth filing — poll transaction accept/reject
bash scripts/stream-companies-house-live.sh poll-transaction <transaction_id>
```

Python directly:

```bash
python3 scripts/companies_house_stream.py list-endpoints --target brmste
python3 scripts/companies_house_stream.py stream --stream filings --max-events 5
```

## Filing API endpoints (live submit)

Used by `scripts/companies_house_api.py` and partner `file-*-api.sh` scripts:

1. `POST /transactions` — body `{ "company_number": "15310393" }`
2. `POST /transactions/{id}/registered-office-address` — AD01 (BRMSTE Basingstoke)
3. `POST /transactions/{id}/confirmation-statement` — CS01 (partners)
4. `PUT /transactions/{id}` — `{ "status": "closed" }`
5. `GET /transactions/{id}` — poll until accepted/rejected

**WebFiling only (not streaming):** PSC04 + CH01 for **Apartment 97, 70 Horseferry Road, SW1P 2FE** — see [BRMSTE-COMPANIES-HOUSE-ADDRESS.md](BRMSTE-COMPANIES-HOUSE-ADDRESS.md).

## Connection rules

- Max **2 concurrent** streaming connections per account.
- On HTTP **429**, wait **60 seconds** before reconnect.
- Heartbeats are blank lines — ignore them.
- Do not reconnect rapidly (rate limited).

## Docs

- [Streaming API overview](https://developer-specs.company-information.service.gov.uk/streaming-api/guides/overview)
- [Streaming authentication](https://developer-specs.company-information.service.gov.uk/streaming-api/guides/authentication)
- [Filing API guide](https://developer-specs.company-information.service.gov.uk/manipulate-company-data-api-filing/guides/overview)
- [REST API + OAuth setup](COMPANIES-HOUSE-API.md)
