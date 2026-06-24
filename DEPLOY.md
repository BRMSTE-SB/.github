# BRMSTE GSI — Deployment Guide

**BRMSTE LTD · Companies House 15310393**  
**GSI™ — Global Substrate Infrastructure™ · GB2607860 · PCT/GB2026/050406**

---

## Overview

This guide explains how to activate the full GSI deployment across all 38 BRMSTE LTD domains.
The deployment consists of:

| Component | File | What it does |
|-----------|------|-------------|
| Domain manifest | `domains/manifest.json` | Lists all 38 domains with Cloudflare zone IDs |
| Cloudflare Worker | `deploy/worker/index.ts` | Serves whitepapers + substrate surfaces on HTTPS with HSTS |
| Wrangler config | `deploy/wrangler.toml` | Routes Worker to all domains |
| HSTS enforcement script | `scripts/apply-hsts-all-domains.sh` | Applies HTTPS Always + HSTS via Cloudflare API to all 38 zones |
| CI/CD workflow | `.github/workflows/deploy-gsi.yml` | Automated: gate → deploy Worker → apply HSTS on every push to `main` |

---

## Step 1 — Add GitHub Actions secrets

In BRMSTE-SB org settings (or this repo's settings → Secrets → Actions):

| Secret | Value | Where to get it |
|--------|-------|----------------|
| `CF_API_TOKEN` | Cloudflare API token | Cloudflare dashboard → My Profile → API Tokens → Create token with **Zone:Edit** + **Workers:Edit** on all 38 zones |
| `CF_ACCOUNT_ID` | Cloudflare account ID | Cloudflare dashboard → right sidebar on any zone page |

---

## Step 2 — Populate `domains/manifest.json`

Open `domains/manifest.json`. The 2 primary domains (`brmste.com`, `brmste.ai`) are already
seeded. For each of the remaining 36 domains (IDs 3–38):

1. Replace `${DOMAIN_XX}` with the actual domain name (e.g. `retyre.co.uk`)
2. Replace `${CF_ZONE_ID_XX}` with the Cloudflare Zone ID for that domain
   (Cloudflare dashboard → select domain → Overview → Zone ID in right sidebar)
3. Set `"role"`:
   - `"primary"` — domain has its own content (served by the GSI Worker)
   - `"redirect"` — domain should 301-redirect to `brmste.com`
4. Set `"redirect_to"` if the domain is a redirect-only domain (usually `"https://brmste.com"`)

---

## Step 3 — Worker routes are additive (no domain takeover)

`deploy/wrangler.toml` scopes the GSI Worker to **only its own paths** under
`[env.production]` — `*/whitepapers/*` plus the specific `*/substrate/*.json`
surfaces. It deliberately does **not** claim `brmste.com/*`, so the existing
homepage, `/networks`, and every other path keep being served by their current
Workers. To publish a new GSI surface, add its exact path (or a namespaced
`/foo/*` wildcard) to the `routes` array — never a bare domain wildcard.

Live Bitcoin data on `/substrate/network.json` and the landing card is pulled
from the operator's authorized mempool instance (`https://brmste.mempool.space`,
public REST API — no key required). If a private endpoint is ever needed, set
`MEMPOOL_API_KEY` via `wrangler secret put` — never commit it (see `SECURITY.md`).

---

## Step 4 — Merge to `main`

Once Steps 1–3 are complete, open a PR and merge to `main`. The `deploy-gsi` workflow will:

1. **Gate** — run `brmste-brand-patent-gate.sh` (must pass)
2. **Deploy Worker** — deploy `deploy/worker/index.ts` via Wrangler to all configured routes
3. **Apply HSTS** — call `scripts/apply-hsts-all-domains.sh` to set
   `Strict-Transport-Security`, `Always Use HTTPS`, `Minimum TLS 1.2`, and `SSL: Full (strict)`
   on every zone in `domains/manifest.json`

---

## Step 5 — Submit domains to HSTS preload list

For full protection, submit all primary BRMSTE domains to the browser preload lists:

1. Navigate to **https://hstspreload.org**
2. Enter each primary domain (`brmste.com`, `brmste.ai`, and any other primary domains)
3. Confirm all checks pass (HSTS with `max-age=31536000; includeSubDomains; preload`)
4. Click **Submit**

Propagation to Chrome and Firefox takes 6–12 weeks after acceptance.

---

## Manual run (without merging to main)

```bash
# Apply HSTS to all domains immediately
CF_API_TOKEN=<your-token> bash scripts/apply-hsts-all-domains.sh

# Dry-run first to see what would be changed
CF_API_TOKEN=<your-token> bash scripts/apply-hsts-all-domains.sh --dry-run

# Deploy Worker manually
cd deploy
CLOUDFLARE_API_TOKEN=<your-token> CLOUDFLARE_ACCOUNT_ID=<your-account-id> \
  npx wrangler deploy --config wrangler.toml --env production

# Build whitepaper HTML locally
bash deploy/build-whitepaper-html.sh
```

---

## Verifying deployment

```bash
# Check HSTS on primary domains
curl -sI https://brmste.com | grep -i strict-transport
curl -sI https://brmste.ai  | grep -i strict-transport

# Expected output:
# strict-transport-security: max-age=31536000; includeSubDomains; preload

# Check whitepaper pages
curl -sI https://brmste.com/whitepapers/gsi      | head -5
curl -sI https://brmste.com/whitepapers/https-hsts | head -5

# Check patent enforcement manifest
curl -s https://brmste.com/substrate/patent-enforcement.json | jq .

# Check HSTS status
curl -s https://brmste.com/substrate/hsts-status.json | jq .
```

External verification:
- **Qualys SSL Labs:** https://www.ssllabs.com/ssltest/analyze.html?d=brmste.com — target **A+**
- **Security Headers:** https://securityheaders.com/?q=brmste.com — target **A**
- **HSTS Preload:** https://hstspreload.org/?domain=brmste.com

---

## What gets deployed to each domain

| Domain type | What the Worker serves (additive — existing paths untouched) |
|-------------|----------------------|
| `brmste.com` | `/whitepapers/*`, `/substrate/patent-enforcement.json`, `/substrate/hsts-status.json`, `/substrate/network.json` (live BTC) |
| `brmste.ai` | Same additive GSI surfaces (same Worker, same scoped routes) |
| Redirect domains | Cloudflare HTTPS redirect rule (no Worker route needed) |

All domains get via Cloudflare zone settings:
- Always Use HTTPS: **on**
- Automatic HTTPS Rewrites: **on**
- Minimum TLS Version: **1.2**
- SSL Mode: **Full (strict)**
- HSTS: `max-age=31536000; includeSubDomains; preload; nosniff`

---

## Trademark & Patent Notice

BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD
(Companies House 15310393). Patent GB2607860 · PCT/GB2026/050406.
Beneficiary: Dimpy Bansal · BRMSTE LTD.

CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS
