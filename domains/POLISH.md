# Domain polish — workflow & live snapshot

**Credential-free.** The auditor probes **public HTTPS only** — it never needs `CF_API_TOKEN` or any cloud key. Live remediation (attaching worker routes, activating zones) runs via **Cloudflare-builds MCP** (agent) or **CI secrets** (operator). Doctrine: `OPERATOR DOESNT BASH · MCP-first · carbon justice only`.

## What "polished" means

A domain is **polished** when, over HTTPS at its root, it is:

1. **reachable** (TLS/DNS resolve — HTTP code ≠ `000`), and
2. **serving** (2xx/3xx), and
3. carries **HSTS**, and
4. for worker-fronted domains (`expected.worker_headers: true`), also carries the full uniform set the `brmste-com-coming-soon` worker emits: `X-Content-Type-Options: nosniff`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`.

## Remediation taxonomy

Because the probe is HTTPS-only, `code 000` means TLS/DNS unreachable and any numeric code means HTTPS was reached (so there is no "force-https" case).

| Action | Trigger | Who executes |
|--------|---------|--------------|
| `none` | Polished. | — |
| `activate-zone` | Unreachable (`000`) and no Cloudflare zone. | Cloudflare MCP / CI: add zone + DNS, then attach route. |
| `investigate-origin` | Unreachable with a zone, **or** HTTPS 4xx/5xx on a non-worker origin. | Cloudflare / Hetzner MCP. |
| `attach-coming-soon-route` | HTTPS reachable but off-edge/unmapped (4xx) or missing uniform headers. | Attach `*<domain>/*` → `brmste-com-coming-soon` (`scripts/deploy-coming-soon-all-zones.sh`). |
| `strip-meta-headers` | A Meta/Facebook-origin header is present. | Remove at edge (`META-FULL-STOP.md`). |
| `review` | Reachable + serving but posture incomplete. | Manual header review. |

The report groups every non-`none` action under `_meta.next_actions` as a turnkey plan:

```bash
jq '._meta.next_actions' domains/polish-report.json
```

## Latest live snapshot (`2026-07-18T18:12:17Z`, 13 known apexes, timeout 12s)

- **Polished (3):** `brmste.com`, `brmste.ai`, `brmste.us`.
- **attach-coming-soon-route (6):** `carbonjustice.uk`, `re-tyre.com`, `leadingmetals.com`, `leadingmetalloys.com`, `businessscience.ai`, `shravanbansal.com` — reachable over HTTPS but not fronted by the coming-soon worker's uniform header set (`shravanbansal.com` is currently Squarespace-hosted, 301→404).
- **activate-zone (4):** `dimpybansalgoldchain.com`, `estateam.co.uk`, `brmste-commercial.com`, `brmste-commercial.ai` — HTTP `000` (zone/DNS not live). The two `brmste-commercial.*` apexes have Hetzner origins (`commercial-com`, `commercial-ai-sb`) but no live Cloudflare zone yet.

**Root cause of the header gaps:** those zones are not on the coming-soon worker route (the worker sets all security headers uniformly). Fix = attach the route via Cloudflare MCP/CI, then re-audit. Not doable from the credential-free cloud-agent VM.

Regenerate any time:

```bash
bash scripts/polish-domains.sh --timeout 12
```
