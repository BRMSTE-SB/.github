# Cloudflare Worker · Companies House live filings + streaming

**Worker:** `brmste-companies-house-live` · package `workers/companies-house-live`

Connects GOV.UK Companies House **REST read**, **Streaming API**, and **OAuth filing** to Cloudflare Workers + KV (`BRMSTE-SWEEP-LOG`).

## Architecture

```
Companies House APIs          Cloudflare Worker              KV (BRMSTE-SWEEP-LOG)
─────────────────────         ─────────────────────          ────────────────────
stream.companieshouse.gov.uk  Cron */15 min                  ch:stream:* timepoints
api.company-information…      GET /api/ch/status             companies-house-live.json
OAuth filing                  POST /api/ch/sync              ch:company:* snapshots
                              POST /api/ch/file/brmste-roa    ch:pending_txn:*
                              GET  /api/ch/oauth/callback    (OAuth metadata in brmste-kv)
```

## Mac setup

1. Fort Knox keys (REST + streaming + OAuth) — `bash scripts/import-companies-house-keys-mac.sh`
2. Generate internal token: `openssl rand -hex 32` → `CH_WORKER_INTERNAL_TOKEN` in `.env.fort-knox`
3. Build bundle + KV:

```bash
bash scripts/refresh-cloudflare-companies-house-mac.sh
```

4. Deploy Worker + secrets:

```bash
bash scripts/deploy-companies-house-worker-mac.sh
```

5. Cloudflare dashboard: route `brmste.com/api/ch/*` → `brmste-companies-house-live`

6. Developer Hub OAuth redirect URI:

```
https://brmste.com/api/ch/oauth/callback
```

## Public endpoints (after route attached)

| Route | Auth | Purpose |
|-------|------|---------|
| `GET /api/ch/health` | none | Worker health |
| `GET /api/ch/status` | none | Bundle + last sync/stream pull |
| `GET /api/ch/company/{number}` | none | Public company profile (proxied) |
| `GET /api/ch/company/{number}/filing-history` | none | Latest filings |
| `GET /api/ch/oauth/callback` | OAuth | Exchange code → store metadata in KV |
| `POST /api/ch/sync` | `X-CH-Worker-Token` | Force sync + stream pull |
| `POST /api/ch/file/brmste-roa` | `X-CH-Worker-Token` | File BRMSTE AD01 if ROA drift |
| `GET /api/ch/transaction/{id}` | `X-CH-Worker-Token` | Poll filing transaction |

## Trigger live sync from Mac

```bash
source .env.fort-knox
curl -sS -X POST "https://brmste.com/api/ch/sync" \
  -H "X-CH-Worker-Token: $CH_WORKER_INTERNAL_TOKEN"
```

## File BRMSTE registered office (API)

```bash
curl -sS -X POST "https://brmste.com/api/ch/file/brmste-roa" \
  -H "X-CH-Worker-Token: $CH_WORKER_INTERNAL_TOKEN"
```

PSC04 + CH01 (Horseferry) remain **WebFiling** — see [BRMSTE-COMPANIES-HOUSE-ADDRESS.md](BRMSTE-COMPANIES-HOUSE-ADDRESS.md).

## Registers

| File | Role |
|------|------|
| `data/cloudflare-companies-house-live.json` | Public bundle → KV |
| `data/brmste-live-companies-house-endpoints.json` | Stream + filing catalog |
| `data/companies-house-api-config.json` | OAuth scopes + targets |
| `data/cloudflare-mcp-binding.json` | KV namespace IDs |

## Related

- [COMPANIES-HOUSE-API.md](COMPANIES-HOUSE-API.md)
- [COMPANIES-HOUSE-LIVE-STREAMING.md](COMPANIES-HOUSE-LIVE-STREAMING.md)
- [CLOUDFLARE-MCP-EQUITIES.md](CLOUDFLARE-MCP-EQUITIES.md)
