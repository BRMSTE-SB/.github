# Domain Polish Playbook

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

"Polish" = every BRMSTE apex reaches over HTTPS, carries the uniform security
header set, and leaks no stack/topology headers — across all 38 Cloudflare
zones fronting the Hetzner **domains-platform** (with AWS / Azure / Siemens IEM
lanes tracked in `registry.json`).

The audit is **credential-free** and runs in the cloud agent VM. **Applying**
fixes is not — it happens via the Cloudflare-builds MCP, the Hetzner
domains-platform config, or CI (never a pasted token).

## Remediation taxonomy

| Remediation | Trigger | Apply where |
|-------------|---------|-------------|
| `activate-zone` | HTTPS 000 (unreachable) & CF zone not active | Cloudflare: add zone + DNS, front on domains-platform |
| `investigate-origin` | 000 with an active CF zone, or a reached 4xx/5xx | Hetzner origin / DNS |
| `harden-headers` | reached but a required header is missing | domains-platform (Caddy) header block |
| `strip-meta-headers` | reached, headers complete, but a leak header present | domains-platform / edge `header -X …` |
| `none` | polished, or an external host we only monitor | — |

> HTTPS-only probe: **any numeric code means HTTPS was reached**, so we never
> emit "force-https". Code `000` is TLS/DNS unreachable.

## Current findings

Regenerate any time with `bash scripts/polish-domains.sh --timeout 12`
(writes `domains/polish-report.json`). Snapshot from the last audit:

- **harden-headers (8):** every reachable BRMSTE apex is missing
  `content-security-policy`. `carbonjustice.uk` additionally lacks
  `x-frame-options`, `referrer-policy`, `permissions-policy`. `brmste.ai`
  also **leaks** `x-powered-by: Next.js` and, worse,
  `x-middleware-rewrite: http://localhost:3030/estate/brmste-ai` — an internal
  origin/port disclosure that must be stripped.
- **investigate-origin (2):** `dimpybansalgoldchain.com`, `estateam.co.uk`
  (CF zone active but origin unreachable — 000).
- **activate-zone (2):** `brmste-commercial.com`, `brmste-commercial.ai`
  (Cloudflare zone not yet active; origins live on Hetzner
  `commercial-com` / `commercial-ai-sb`).
- **polished / monitor (1):** `shravanbansal.com` is external (Squarespace) —
  off the BRMSTE edge, monitored only.

## Fix: uniform headers on the domains-platform (Caddy)

Add to the shared `brmste-unified-v1` site block so **all** fronted apexes
inherit it. This closes every `harden-headers` finding and strips the leaks:

```caddyfile
header {
    # required security headers (uniform target)
    Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    Referrer-Policy "strict-origin-when-cross-origin"
    Permissions-Policy "camera=(), microphone=(), geolocation=()"
    Content-Security-Policy "default-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'; upgrade-insecure-requests"

    # strip stack / internal-topology leaks
    -X-Powered-By
    -X-Middleware-Rewrite
    -X-AspNet-Version
    -X-AspNetMvc-Version
    -X-Runtime
    -Server
}
```

For the Next.js app behind `brmste.ai`, also set
`poweredByHeader: false` in `next.config.js` and drop
`x-middleware-rewrite` in middleware so the internal `localhost:3030` route
never reaches the wire (defence in depth even with the Caddy strip).

Roll out from THE KOHINOOR MAC (operator): `npm run rollout:hetzner`.
Then re-audit: `bash scripts/polish-domains.sh` and confirm the domain flips to
`polished`. CSP is intentionally strict; widen only per real asset origins.

## Fix: activate-zone / investigate-origin

- **activate-zone** (`brmste-commercial.*`): create the Cloudflare zone,
  point DNS at the Hetzner origin, front on the domains-platform. Via the
  `Cloudflare-builds` MCP or CI — never a pasted token.
- **investigate-origin** (`dimpybansalgoldchain.com`, `estateam.co.uk`): zone
  is active but the origin is down. Check the Hetzner origin / DNS record, then
  re-audit.

## Enumerate all 38 zones

The registry tracks the 13 known apexes; the full active-zone list is synced
from Cloudflare into `domains/manifest.json` by a token-holding lane:

```bash
# operator desktop / CI only — needs CF_API_TOKEN (Zone:Read)
bash scripts/sync-cf-zones-to-manifest.sh
```

Then extend `registry.json` with any apexes the manifest surfaces beyond the 13
known ones so `known_apexes` climbs toward `expected_total` (38).

Doctrine: **OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
