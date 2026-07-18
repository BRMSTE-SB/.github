# BRMSTE multi-cloud domain registry

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406 · INV. G06N3/045**

Canonical registry for BRMSTE domains and their posture across **Cloudflare · Hetzner · AWS · Azure · Siemens IEM**. Everything here is **credential-free** — no API tokens live in this repo or in chat. Live changes run via **MCP** (agent) or **CI secrets** (operator), per `AGENTS.md` / `.cursor/rules/mcp-strict-only.mdc`.

## Files

| File | Purpose |
|------|---------|
| `registry.json` | The 13 known apexes with per-domain multi-cloud posture (`schema: brmste-domain-registry/v2`). |
| `registry.schema.json` | JSON Schema (draft-07) for `registry.json`. |
| `manifest.json` | *Generated* — live Cloudflare zone inventory (domains 1–38). Written by `scripts/sync-cf-zones-to-manifest.sh` (needs Zone:Read via MCP/CI). Not committed offline. |
| `polish-report.json` | *Generated* — output of the credential-free HTTPS posture auditor. |
| `POLISH.md` | Polish workflow, remediation taxonomy, and latest live snapshot. |

## The 38 vs the 13

The BRMSTE Cloudflare account (`7ea6547b1d6eb1cbd6d0ac5cf960ce2a`) carries **38 zones** (`_meta.expected_total`). This registry pins the **13 known apexes** (`_meta.known_apexes`) — the ones with a documented role and multi-cloud binding. Zones 14–38 are **enumerated live**, never guessed:

```bash
# operator MCP or CI (Zone:Read) — not runnable with pasted tokens in a cloud agent VM
bash scripts/sync-cf-zones-to-manifest.sh   # -> domains/manifest.json
```

Keeping the offline registry honest (13 pinned) and the live count authoritative (manifest.json) avoids fabricating zone data the credential-free VM cannot see.

## Multi-cloud lanes

| Cloud | Role | Source |
|-------|------|--------|
| **Cloudflare** | edge control plane — zones, `brmste-com-coming-soon` worker routes, uniform HTTPS + security headers, substrate | `coming-soon/src/index.js`, `scripts/deploy-coming-soon-all-zones.sh` |
| **Hetzner** | origin fleet — 15 servers / 11 projects (commercial, leading, retyre, **siemens cpx52**) | `data/hetzner/servers.json` |
| **AWS** | industrial edge — Greengrass v2 + IoT SiteWise Edge + `brmste-edge`, portal via CloudFront/API GW (eu-north-1) | `BRMSTE-FINAL/aws`, `docs/AWS-INDUSTRIAL-EDGE.md` |
| **Azure** | planned hyperscale coexistence lane | `CARBON-JUSTICE.md` |
| **Siemens IEM** | Industrial Edge Management — AWS IoT SiteWise Edge on Siemens IED (S7 / Profinet) | `BRMSTE-FINAL/docs/SIEMENS-INDUSTRIAL-EDGE.md` |

Each domain in `registry.json` carries a `clouds` block declaring its binding to each lane, and an `expected` block (`https`, `hsts`, `worker_headers`) that the auditor gates against.

## Verify

```bash
bash scripts/verify-domains-registry.sh   # structural gate (ids, counts, cloud blocks, hetzner bindings)
bash scripts/polish-domains.sh --timeout 12   # live credential-free HTTPS posture audit
```

CI: `.github/workflows/verify-domains.yml` (structural, on PR/push) and `.github/workflows/polish-domains.yml` (scheduled credential-free audit, uploads report artifact).
