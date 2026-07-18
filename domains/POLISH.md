# Domain polish — audit snapshot & remediation

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

Live, credential-free audit of the BRMSTE apex fleet. Regenerate with
`bash scripts/polish-domains.sh --timeout 12` (writes `domains/polish-report.json`).

> **Where config lives:** the apexes are served by the Hetzner Caddy **`domains-platform`**
> on `brmste-db` (178.104.79.112), with Cloudflare in **DNS-only** mode (no `cf-ray` at the
> edge). The Caddy config is **not in this repository** — it lives on the Hetzner host / a
> private repo. This workspace can produce the audit and the exact remediation snippets, but
> the live change is applied by the **operator / CI / connected MCP**. Cursor never signs.

## Live snapshot — 2026-07-18 (13 known apexes · 38 expected)

| # | Apex | Code | Origin | Serving profile | Gap |
|---|------|------|--------|-----------------|-----|
| 1 | brmste.com | 307 → /entry | brmste-db (Caddy 1.1) | estate/app | + CSP · HSTS→2yr |
| 2 | brmste.ai | 200 | brmste-db (Caddy 1.1, Next.js) | estate/app | + CSP · HSTS→2yr · **strip `X-Powered-By` + `X-Middleware-Rewrite`** |
| 3 | brmste.us | 307 → /entry | brmste-db (Caddy 1.1) | estate/app | + CSP · HSTS→2yr |
| 4 | carbonjustice.uk | 200 | brmste-db (Caddy 1.0) | `brmste-unified-v1` | + XFO · Referrer · Permissions · CSP · HSTS→2yr |
| 5 | re-tyre.com | 200 | brmste-db (Caddy 1.0) | `brmste-unified-v1` | + XFO · Referrer · Permissions · CSP · HSTS→2yr |
| 6 | leadingmetals.com | 200 | brmste-db (Caddy 1.0) | `brmste-unified-v1` | + XFO · Referrer · Permissions · CSP · HSTS→2yr |
| 7 | leadingmetalloys.com | 200 | **89.117.27.251** (Hostinger WordPress) | outlier host | + HSTS · XCTO · XFO · Referrer · Permissions · strip `X-Powered-By` |
| 8 | businessscience.ai | 200 | brmste-db (Caddy 1.0) | `brmste-unified-v1` | + XFO · Referrer · Permissions · CSP · HSTS→2yr |
| 9 | dimpybansalgoldchain.com | — | NXDOMAIN | — | publish DNS |
| 10 | estateam.co.uk | — | NXDOMAIN | — | publish DNS |
| 11 | brmste-commercial.com | — | NXDOMAIN | — | publish DNS |
| 12 | brmste-commercial.ai | — | NXDOMAIN | — | publish DNS |
| 13 | shravanbansal.com | 301 | Squarespace | external | monitor-only |

**Summary:** 0 polished · 8 needs-work · 4 unpublished (DNS) · 1 external.

Two Caddy serving profiles are live:

- **`brmste-unified-v1`** (template rev `rails-2026-07-18`) — portfolio apexes #4–6, #8.
  Emits only `Strict-Transport-Security` (1yr) + `X-Content-Type-Options`. **Missing 4 of 6
  required headers.** This is the highest-leverage fix — one template edit polishes four apexes.
- **estate/app path** (Next.js behind Caddy) — #1–3. Emits the full header set **except CSP**;
  `brmste.ai` additionally leaks `X-Powered-By` and an internal `X-Middleware-Rewrite:
  http://localhost:3030/estate/brmste-ai`.

## Remediation 1 — `brmste-unified-v1` template (polishes carbonjustice.uk, re-tyre.com, leadingmetals.com, businessscience.ai)

Add to the shared Caddy snippet/site block that stamps the unified template (the same place
that already sets `Strict-Transport-Security` and `X-Content-Type-Options`):

```caddy
# BRMSTE unified security headers — apply to all domains-platform sites
header {
    Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    X-Content-Type-Options    "nosniff"
    X-Frame-Options           "DENY"
    Referrer-Policy           "strict-origin-when-cross-origin"
    Permissions-Policy        "camera=(), microphone=(), geolocation=(), interest-cohort=()"
    Content-Security-Policy   "default-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https:; base-uri 'none'; frame-ancestors 'none'; upgrade-insecure-requests"
    # strip origin/framework fingerprints
    -X-Powered-By
    -X-Middleware-Rewrite
    -Server
}
```

The canonical (tightest) CSP for the first-party estate apexes is in
[`coming-soon/src/index.js`](../coming-soon/src/index.js) `SECURITY_HEADERS`. The block above
uses a slightly broader `img-src`/`connect-src https:` so it is safe as a fleet-wide default;
tighten per-site where the asset origins are known.

## Remediation 2 — estate/app path (brmste.com, brmste.ai, brmste.us)

This path already sets XFO/Referrer/Permissions. Two changes:

1. **Add CSP** and **raise HSTS to 2 years** (same `Content-Security-Policy` and
   `Strict-Transport-Security` lines as above).
2. **Strip the Next.js leaks on `brmste.ai`** — these expose the framework and an internal
   rewrite target (`http://localhost:3030/estate/brmste-ai`):

```caddy
header {
    Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Content-Security-Policy   "default-src 'self'; img-src 'self' https://brmste.com https://brmste.ai https://raw.githubusercontent.com data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https://brmste.com https://brmste.ai; base-uri 'none'; frame-ancestors 'none'; upgrade-insecure-requests"
    -X-Powered-By
    -X-Middleware-Rewrite
}
```

## Remediation 3 — leadingmetalloys.com (origin 89.117.27.251)

This apex is served from a **Hostinger-hosted WordPress site** (LiteSpeed; response advertises
`platform: hostinger`, `panel: hpanel`, `x-powered-by: PHP/8.0.30`, and `wp-json` links) that is
**outside** the Caddy `domains-platform` (no `via`/`x-brmste-origin`). It already has a minimal CSP
(`upgrade-insecure-requests`) but is missing HSTS, `X-Content-Type-Options`, `X-Frame-Options`,
`Referrer-Policy`, `Permissions-Policy` and leaks `X-Powered-By`. Either:

- **Preferred (consolidate):** repoint DNS to `brmste-db` and bind it to the `brmste-unified-v1`
  template (then it inherits Remediation 1), or
- **In place:** add the full BRMSTE header set on the WordPress host — Hostinger hPanel →
  Advanced → set response headers (or a `.htaccess`/LiteSpeed `Header set` block), and disable
  the PHP `X-Powered-By` (`expose_php = Off`). This is applied in the Hostinger control panel by
  the operator, not from this workspace.

## Remediation 4 — publish DNS (NXDOMAIN)

These apexes have **no A/AAAA record** and do not resolve. Publish DNS in the Cloudflare
account (`7ea6547b1d6eb1cbd6d0ac5cf960ce2a`) to the intended origin, then bind at Caddy:

| Apex | Intended Hetzner origin (`data/hetzner/servers.json`) |
|------|--------------------------------------------------------|
| dimpybansalgoldchain.com | brmste-db (178.104.79.112) |
| estateam.co.uk | brmste-db (178.104.79.112) |
| brmste-commercial.com | commercial-com (135.181.153.241) |
| brmste-commercial.ai | commercial-ai-sb (135.181.154.11) |

## How to apply (operator / CI / MCP — not this workspace)

1. Edit the Caddy `domains-platform` config on `brmste-db` (Remediations 1–3) and reload Caddy.
2. Publish the four DNS records (Remediation 4) — via the Cloudflare dashboard or a
   connected `Cloudflare-*` MCP server (never paste `CF_API_TOKEN` in chat).
3. Re-run `bash scripts/polish-domains.sh` (or the `polish-domains.yml` workflow) to confirm
   every reachable apex reports `status: polished`.

**OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
