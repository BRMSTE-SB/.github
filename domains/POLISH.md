# BRMSTE Domain Polish — all 38 zones, all five clouds

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

"Polish" = every BRMSTE domain meets one consistent edge-posture baseline across
**Cloudflare · Hetzner · AWS · Azure · Siemens IEM**. This file is the doctrine;
[`registry.json`](registry.json) `_meta.polish` is the machine baseline; and
[`scripts/polish-domains.sh`](../scripts/polish-domains.sh) is the credential-free
auditor that measures it.

## The polish baseline

Read live from `registry.json` → `_meta.polish` (data-driven, single source of truth):

| Check | Requirement |
|-------|-------------|
| `https` | Reachable over TLS; final URL stays `https://` |
| `hsts` | `Strict-Transport-Security` present, `max-age ≥ 15552000` (180d) |
| `x-content-type-options` | `nosniff` |
| `referrer-policy` | present (worker sends `strict-origin-when-cross-origin`) |
| `meta_full_stop` | **no** Meta/Facebook/Instagram response headers (`x-fb-debug`, `x-instagram-request-id`) — see [`META-FULL-STOP.md`](../META-FULL-STOP.md) |
| `health_token` *(informational)* | `/health` returns `brmste-coming-soon-v5` (zones on the coming-soon worker) |

A domain is **POLISHED** when it is reachable and meets `https + hsts + x-content-type-options + referrer-policy + meta_full_stop`. `health_token` is reported but not required (primary/substrate zones need not serve the coming-soon health page).

## Audit (no secrets — safe for cloud agents, CI, local)

```bash
bash scripts/polish-domains.sh                 # audit every registry domain, write report
bash scripts/polish-domains.sh --only re-tyre.com
bash scripts/polish-domains.sh --strict        # exit 1 if any reachable domain is unpolished
```

Writes [`polish-report.json`](polish-report.json) (`brmste-domains-polish/v1`) and prints a
per-domain table. The auditor is read-only: it never deploys and never asks for
`CF_API_TOKEN` (per [`.cursor/rules/mcp-strict-only.mdc`](../.cursor/rules/mcp-strict-only.mdc)).

### Turnkey remediation plan (`_meta.next_actions`)

Every non-polished domain is classified into one exact, credential-free action and
grouped in `polish-report.json` → `_meta.next_actions` (and per domain under
`domains[].remediation`). This turns "polish all 38" into a checklist the
operator / CI / MCP can execute directly — no diagnosis step, no token in chat:

| `remediation.action` | Meaning | Lane |
|----------------------|---------|------|
| `attach-coming-soon-route` | reachable/HTTPS but missing edge headers the worker sets | `Cloudflare-builds` MCP or CI `deploy-coming-soon.yml` |
| `activate-zone` | `code=000` — DNS/zone not live | add zone + proxied DNS, then attach worker route |
| `force-https` | reachable but not landing on HTTPS | Always Use HTTPS + worker route |
| `strip-meta-headers` | META FULL STOP breach (Meta headers present) | remove syndicating origin, route via worker |

```bash
# just the plan, no diagnosis noise:
jq '._meta.next_actions' domains/polish-report.json
```

### Current live posture (auto-refreshed 2026-07-18)

13 known apexes · reachable 9 · **polished 3** · expected total 38 (live CF active-zone count).

- **POLISHED (3):** `brmste.com` · `brmste.ai` · `brmste.us`
- **`attach-coming-soon-route` (6):** `carbonjustice.uk` · `re-tyre.com` · `leadingmetals.com` · `businessscience.ai` · `shravanbansal.com` (missing `referrer-policy` only) · `leadingmetalloys.com` (also missing HSTS + nosniff)
- **`activate-zone` (4):** `dimpybansalgoldchain.com` · `estateam.co.uk` · `brmste-commercial.com` · `brmste-commercial.ai` (DNS not live)

The gap to 38 is enumeration (only 13 apexes are `source=known`) plus route
attachment — both close via the deploy lane; a connected `Cloudflare-bindings`
MCP or a CI run of `sync-cf-zones-to-manifest.sh` back-fills the remaining zones.

## Remediation by gap class

| Symptom in the report | Root cause | Fix (operator / CI / MCP — never in chat) |
|-----------------------|------------|-------------------------------------------|
| reachable, `referrer-policy` / `health_token` = `-` | zone not (yet) running the `brmste-com-coming-soon` worker (has zone-level HSTS/nosniff only) | attach the worker route: `scripts/deploy-coming-soon-all-zones.sh` (or `Cloudflare-builds` MCP), then re-audit |
| reachable, `hsts` = `-` | zone-level HSTS off or `max-age` too low | enable HSTS (SSL/TLS → Edge Certificates) or deploy the worker, which sends `max-age=63072000; includeSubDomains; preload` |
| reachable, `x-content-type-options` = `-` | no `nosniff` at edge | deploy the worker, or add a Managed Transform |
| `code=000` (unreachable) | DNS not live / zone parked / not yet added to Cloudflare | add the zone + DNS, run `sync-cf-zones-to-manifest.sh`, then deploy the worker |
| `meta_full_stop` = `-` | Meta response header leaking | remove Meta syndication — [`META-FULL-STOP.md`](../META-FULL-STOP.md) |

The coming-soon worker ([`coming-soon/src/index.js`](../coming-soon/src/index.js))
already emits the full security-header set on every response, so **attaching the
worker route to a zone makes that zone polished** — this is why the deploy path
covers all 38 zones uniformly.

## Per-lane polish posture

- **Cloudflare** — control plane. HSTS + nosniff + Referrer-Policy + CSP + Permissions-Policy come from the worker; `deploy-coming-soon-all-zones.sh` fans the route to every active zone. This is where "polish" is enforced at the edge.
- **Hetzner** — origin/relay fleet behind Cloudflare (`Atom → Cloudflare → Hetzner`). Polish = origins only answer via Cloudflare so edge headers always apply; keep origin IPs out of the public repo (see PR #69 IP-redaction).
- **AWS** — Industrial Edge, `eu-north-1`, `Application=BRMSTE`. Polish = TLS on `/substrate/aws/*`; runbook `BRMSTE-FINAL/docs/AWS-INDUSTRIAL-EDGE.md`.
- **Azure** — planned multi-cloud DNS/CDN failover. Polish = when armed, mirror the same HSTS/nosniff/Referrer-Policy baseline.
- **Siemens IEM** — plant-floor edge (SiteWise Edge IEM app, S7/Profinet). Polish = industrial surfaces reached only through the edge lane, never exposed raw.

## Doctrine

**OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

Carbon justice only · no BRMSTE charges — see [`CARBON-JUSTICE.md`](../CARBON-JUSTICE.md).
