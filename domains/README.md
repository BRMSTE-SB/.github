# BRMSTE Domains — multi-cloud registry

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

Canonical home for every BRMSTE domain and how each one maps across the five
cloud lanes: **Cloudflare · Hetzner · AWS · Azure · Siemens IEM**.

## Files

| File | Purpose | Maintained by |
|------|---------|---------------|
| `registry.json` | Durable source of truth — roles + per-domain cloud lanes. **Edit this by hand.** | agent / operator |
| `registry.schema.json` | JSON Schema (draft-07) for `registry.json`. | — |
| `manifest.json` | Derived artifact — `registry.json` merged with live Cloudflare zone_ids. **Generated, do not hand-edit.** | `scripts/sync-cf-zones-to-manifest.sh` |
| `POLISH.md` | Edge-posture polish doctrine + per-lane posture + remediation by gap class. | agent / operator |
| `polish-report.json` | Credential-free HTTPS posture audit of every domain. **Generated.** | `scripts/polish-domains.sh` |

## The five cloud lanes

Each domain carries a `clouds` object with one status per lane:

| Lane | Role in the estate | Typical status |
|------|--------------------|----------------|
| `cloudflare` | Control plane · DNS · edge (`brmste-com-coming-soon` worker, `/substrate/*`) | `active` |
| `hetzner` | Origin · static fleet · md-render (`Atom → Cloudflare → Hetzner`) | `origin` / `relay` |
| `aws` | Industrial Edge · IDF Layer 2–4 · `eu-north-1` · `Application=BRMSTE` | `substrate` / `planned` |
| `azure` | Multi-cloud DNS/CDN failover lane | `planned` |
| `siemens_iem` | Plant-floor edge · SiteWise Edge IEM app (S7/Profinet) | `plant-edge` / `n/a` |

Status vocabulary: `active · relay · origin · substrate · plant-edge · planned · n/a`.

## Why the count is 38

`_meta.expected_total` is the count of **active zones** in the BRMSTE Cloudflare
account `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`. `registry.json` seeds the known apex
zones (`source: "known"`); the Cloudflare sync fills in `zone_id` for each and
appends any zone that is live in Cloudflare but not yet seeded here (with default
lanes and a heuristic role), so `manifest.json` always reflects all 38.

## Sync (MCP-first — agents never ask for tokens)

Per `.cursor/rules/mcp-strict-only.mdc`, agents inventory Cloudflare via the
`Cloudflare-bindings` / `Cloudflare-observability` MCP servers and deploy via
`Cloudflare-builds`. If a server shows `needsAuth`, connect it in
**Cursor → Settings → Tools & MCP** — do **not** paste `CF_API_TOKEN` into chat.

CI / operator-shell fallback (secrets come from the environment, never chat):

```bash
# Refresh manifest.json from the live Cloudflare zone list (merges registry data)
CF_API_TOKEN=… bash scripts/sync-cf-zones-to-manifest.sh

# Attach the coming-soon worker route to every active zone
CF_API_TOKEN=… bash scripts/deploy-coming-soon-all-zones.sh --dry-run
```

## Verify (no secrets required)

```bash
bash scripts/verify-domains-registry.sh
```

Checks that `registry.json` is valid, every domain is unique, roles are in the
allowed set, and every domain declares all five cloud lanes. Runs in CI via
`.github/workflows/verify-domains.yml`.

## Polish (edge-posture audit, no secrets required)

```bash
bash scripts/polish-domains.sh            # audit HTTPS/HSTS/nosniff/Referrer-Policy/META-stop
bash scripts/polish-domains.sh --strict   # exit 1 if a reachable domain is unpolished
```

Audits every domain against the `_meta.polish` baseline and writes
`polish-report.json`. See [`POLISH.md`](POLISH.md) for the doctrine and how to fix
each gap class. Runs (non-blocking) in CI via
`.github/workflows/polish-domains.yml`.

## Doctrine

**OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

Carbon justice only · no BRMSTE charges — see [`CARBON-JUSTICE.md`](../CARBON-JUSTICE.md).
