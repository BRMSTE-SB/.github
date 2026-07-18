# BRMSTE Domain Fleet

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

Canonical source-of-truth for the BRMSTE domain fleet across **five cloud
lanes**. Everything here runs **credential-free** — no tokens live in the repo
or in chat. Applying changes to live infrastructure is done via **MCP**
(`Cloudflare-builds`), the Hetzner **domains-platform** config, or **CI on
merge** — never a pasted API key (MCP-strict; see `.cursor/rules/mcp-strict-only.mdc`).

## Files

| File | Purpose |
|------|---------|
| `registry.json` | Hand-maintained registry (`brmste-domain-registry/v2`): 13 known apexes, `expected_total` 38, per-domain cloud-lane bindings + the uniform header `policy`. |
| `registry.schema.json` | JSON Schema (draft-07) for `registry.json`. |
| `manifest.json` | *Generated* full active-zone list, synced from Cloudflare (`scripts/sync-cf-zones-to-manifest.sh`). Not committed until a token-holding lane runs the sync. |
| `polish-report.json` | *Generated* live HTTPS audit output (`brmste-polish-report/v2`). |
| `POLISH.md` | Polish playbook — current findings + exact remediation. |

## Five cloud lanes

| Lane | Role | Source of truth |
|------|------|-----------------|
| **Cloudflare** | TLS, HTTPS+HSTS, edge front, legacy coming-soon worker, substrate | account `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`, `manifest.json` (38 zones) |
| **Hetzner** | `domains-platform` (Caddy, `brmste-unified-v1`) + app origins, DB, foundry | `data/hetzner/servers.json` (15 servers) |
| **AWS** | Industrial edge CloudFormation, `Application=BRMSTE` | `BRMSTE-FINAL/aws/…`, region `eu-north-1` |
| **Azure** | Planned secondary industrial edge + carbon-justice region | `CARBON-JUSTICE.md` |
| **Siemens IEM** | Industrial Edge Management control plane | Hetzner `siemens` (46.224.23.51) |

As of **2026-07-18** the live fleet is served by the Hetzner **domains-platform**
(Caddy) fronted by Cloudflare — not the coming-soon worker. Security headers are
set at the platform layer, so `policy` below is the uniform target for whichever
layer answers.

## Uniform header policy (`registry.policy`)

**Required on every response (including redirects):**
`strict-transport-security`, `x-content-type-options`, `x-frame-options`,
`referrer-policy`, `permissions-policy`, `content-security-policy`.

**Forbidden (stack/topology leaks, strip at the edge/platform):**
`x-powered-by`, `x-middleware-rewrite`, `x-aspnet-version`,
`x-aspnetmvc-version`, `x-runtime`.

Target HSTS: `max-age=63072000; includeSubDomains; preload`.

## Verify + audit (credential-free)

```bash
# Structural gate — registry integrity, hetzner bindings resolve, CF account
# matches wrangler.toml. Runs anywhere, no network needed.
bash scripts/verify-domains-registry.sh

# Live HTTPS audit — probes each apex, checks headers against policy, writes
# domains/polish-report.json. HTTPS only, no tokens.
bash scripts/polish-domains.sh --timeout 12
```

CI runs both: `verify-domains.yml` (PR/push gate) and `polish-domains.yml`
(daily cron + dispatch, uploads the report artifact).

## Sync the full 38-zone list (token-holding lane only)

```bash
# Requires CF_API_TOKEN with Zone:Read — run on the operator desktop / CI,
# NOT in a cloud agent or in chat.
bash scripts/sync-cf-zones-to-manifest.sh   # writes domains/manifest.json
```

## Deploy / apply remediations

Never with a pasted token. Use one of:

1. **Cloudflare-builds MCP** (worker/route changes) — connect in Cursor →
   Settings → Tools & MCP.
2. **Hetzner domains-platform config** (header hardening / leak stripping) —
   edit the Caddy `domains-platform` template, roll out via the operator's
   `npm run rollout:hetzner` from THE KOHINOOR MAC.
3. **CI on merge** — GitHub Actions with operator-managed secrets.

Doctrine: **OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
