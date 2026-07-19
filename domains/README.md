# BRMSTE Domains — Multi-Cloud Registry

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

This directory is the committed source of truth for BRMSTE domains across every
cloud lane: **Cloudflare · Hetzner · AWS · Azure · Siemens IEM**.

## Files

| File | Purpose | Author |
|------|---------|--------|
| `registry.json` | Curated, human-reviewed registry of root domains, their roles, and the cloud lane each belongs to. | Committed by hand / agent |
| `manifest.json` | Authoritative list of **all 38 active Cloudflare zones**, synced live from the Cloudflare API. | Generated — `scripts/sync-cf-zones-to-manifest.sh` |

`manifest.json` is generated, not hand-edited. It is written by the sync script
(run via MCP on the operator desktop or by CI) and lists every active zone with
its `zone_id`, `role`, and HSTS flag. `registry.json` is the reviewed layer on
top — a **curated intent overlay for a subset** of domains, recording roles,
commercial vs brand class, and the multi-cloud lane each surface belongs to. It
does not enumerate all 38 zones; the roles for zones not listed here are assigned
heuristically by the sync script. Domains flagged `must_be_live: true` are known
active zones and are hard-checked against the live manifest.

## Cloud lanes

| Lane | Purpose | Key manifests |
|------|---------|---------------|
| **Cloudflare** | Edge substrate + `brmste-com-coming-soon` worker on all 38 zones | `manifest.json`, `scripts/deploy-coming-soon-all-zones.sh` |
| **Hetzner** | Compute fleet — md-render, mine/foundry, relay, banking | `data/hetzner/*.json`, `BRMSTE-FINAL:config/hetzner-fleet.example.json` |
| **AWS** | Industrial edge (Greengrass / IoT SiteWise), region `eu-north-1` | `BRMSTE-FINAL:aws/cloudformation/brmste-industrial-edge.yaml` |
| **Azure** | Infra build env (AKS/ACR/VNet) via OpenTofu | `infrastructure:Infrastructure-build/tofu/` |
| **Siemens IEM** | AWS IoT SiteWise Edge on Siemens Industrial Edge | `BRMSTE-FINAL:aws/siemens/`, `aws/scripts/deploy-siemens-iem.sh` |

## Verify

Deterministic, no network, no tokens:

```bash
bash scripts/verify-domains-registry.sh
```

The verifier validates `registry.json` (schema, roles, HSTS, unique domains, all
five cloud lanes present, `cloudflare_zone_target` consistent between `_meta` and
`clouds.cloudflare`). When `manifest.json` is present it also cross-checks the
live zone list: the zone count must match `cloudflare_zone_target` (38), each
zone must carry a valid role + string `zone_id` with no duplicates, and every
`must_be_live` registry root must appear in the synced manifest (other curated
roots only warn). Results are written to
`data/edge/domains-registry-verify-latest.json`.

**Where each check runs:**

- `.github/workflows/verify-domains.yml` runs the verifier on every PR/push that
  touches `domains/**` or the scripts — **registry-only** (no `manifest.json` is
  committed, so the live cross-check is skipped there and reported as a warning).
- `.github/workflows/deploy-coming-soon.yml` runs the verifier **immediately
  after** syncing `manifest.json` from Cloudflare, so the full 38-zone
  cross-check gates the live deploy.

## Refresh the live 38-zone manifest

Runs via **MCP (Cloudflare-builds)** on the operator desktop or in CI — never
with a token pasted into chat (see `.cursor/rules/mcp-strict-only.mdc`):

```bash
# CI / operator shell only — CF_API_TOKEN comes from the environment, not chat
bash scripts/sync-cf-zones-to-manifest.sh
```

## Doctrine

**OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
