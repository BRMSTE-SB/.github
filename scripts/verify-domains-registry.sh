#!/usr/bin/env bash
# Verify the BRMSTE multi-cloud domain registry — deterministic, no network, no tokens.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Validates domains/registry.json (schema, roles, HSTS, unique domains, cloud lanes).
# When domains/manifest.json is present (live-synced Cloudflare zones) it also
# cross-checks: zone count == cloudflare_zone_target, every zone has a valid role
# and zone_id, and every Cloudflare root in the registry appears in the manifest.
#
# Usage:
#   bash scripts/verify-domains-registry.sh
#
# CURSOR NEVER SIGNS · OPERATOR DOESNT BASH · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${REGISTRY:-$ROOT/domains/registry.json}"
MANIFEST="${MANIFEST:-$ROOT/domains/manifest.json}"
OUT="${OUT:-$ROOT/data/edge/domains-registry-verify-latest.json}"

command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"

python3 - "$REGISTRY" "$MANIFEST" "$OUT" << 'PY'
import json
import sys
from datetime import datetime, timezone

registry_path, manifest_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

ALLOWED_ROLES = {"primary", "carbon_justice", "coming_soon"}
REQUIRED_LANES = {"cloudflare", "hetzner", "aws", "azure", "siemens_iem"}

errors = []
warnings = []
checks = []


def check(name, ok, detail=""):
    checks.append({"check": name, "ok": bool(ok), "detail": detail})
    if not ok:
        errors.append(f"{name}: {detail}" if detail else name)
    return ok


def load(path):
    with open(path) as f:
        return json.load(f)


# --- registry.json (required) ---------------------------------------------
try:
    registry = load(registry_path)
    check("registry.parse", True, registry_path)
except FileNotFoundError:
    check("registry.exists", False, f"missing {registry_path}")
    registry = None
except json.JSONDecodeError as e:
    check("registry.parse", False, f"invalid JSON: {e}")
    registry = None

zone_target = None
registry_cf_roots = []
registry_cf_must_live = []

if registry is not None:
    check("registry.schema", registry.get("schema") == "brmste-domain-registry/v1",
          f"schema={registry.get('schema')!r}")

    meta = registry.get("_meta", {})
    zone_target = meta.get("cloudflare_zone_target")
    check("registry.zone_target", isinstance(zone_target, int) and zone_target > 0,
          f"cloudflare_zone_target={zone_target!r}")

    clouds = registry.get("clouds", {})
    missing_lanes = REQUIRED_LANES - set(clouds.keys())
    check("registry.cloud_lanes", not missing_lanes,
          f"missing lanes: {sorted(missing_lanes)}" if missing_lanes else "all 5 lanes present")

    cf_cloud = clouds.get("cloudflare", {}) if isinstance(clouds, dict) else {}
    check("registry.zone_target_consistent",
          cf_cloud.get("zone_target") == zone_target,
          f"clouds.cloudflare.zone_target={cf_cloud.get('zone_target')!r} != _meta.cloudflare_zone_target={zone_target!r}")

    domains = registry.get("domains", [])
    check("registry.domains_nonempty", isinstance(domains, list) and len(domains) > 0,
          f"count={len(domains) if isinstance(domains, list) else 'n/a'}")

    seen = set()
    for i, d in enumerate(domains if isinstance(domains, list) else []):
        name = d.get("domain")
        loc = name or f"index {i}"
        if not name or not isinstance(name, str):
            check(f"registry.domain[{loc}].name", False, "missing/invalid domain")
            continue
        if name in seen:
            check(f"registry.domain[{name}].unique", False, "duplicate domain")
        seen.add(name)

        role = d.get("role")
        check(f"registry.domain[{name}].role", role in ALLOWED_ROLES,
              f"role={role!r} not in {sorted(ALLOWED_ROLES)}")
        check(f"registry.domain[{name}].hsts", d.get("hsts_preload") is True,
              f"hsts_preload={d.get('hsts_preload')!r}")
        lane = d.get("lane")
        check(f"registry.domain[{name}].lane", lane in clouds,
              f"lane={lane!r} not a declared cloud")
        if lane == "cloudflare":
            registry_cf_roots.append(name)
            if d.get("must_be_live") is True:
                registry_cf_must_live.append(name)


# --- manifest.json (optional live sync) -----------------------------------
manifest_present = False
try:
    manifest = load(manifest_path)
    manifest_present = True
    check("manifest.parse", True, manifest_path)
except FileNotFoundError:
    warnings.append(
        f"manifest not present ({manifest_path}) — run scripts/sync-cf-zones-to-manifest.sh "
        "via MCP/CI to cross-check the live 38-zone list"
    )
    manifest = None
except json.JSONDecodeError as e:
    check("manifest.parse", False, f"invalid JSON: {e}")
    manifest = None

if manifest_present and manifest is not None:
    mdomains = manifest.get("domains", [])
    check("manifest.domains_nonempty", isinstance(mdomains, list) and len(mdomains) > 0,
          f"count={len(mdomains) if isinstance(mdomains, list) else 'n/a'}")

    if isinstance(mdomains, list):
        if zone_target is not None:
            check("manifest.zone_count", len(mdomains) == zone_target,
                  f"found {len(mdomains)} zones, expected {zone_target}")

        m_meta = manifest.get("_meta", {}) if isinstance(manifest.get("_meta"), dict) else {}
        if "cloudflare_zone_target" in m_meta:
            check("manifest.meta_zone_target",
                  m_meta.get("cloudflare_zone_target") == zone_target,
                  f"manifest _meta.cloudflare_zone_target={m_meta.get('cloudflare_zone_target')!r} "
                  f"!= registry {zone_target!r}")

        manifest_names = set()
        for i, d in enumerate(mdomains):
            name = d.get("domain")
            loc = name or f"index {i}"
            if not isinstance(name, str) or not name.strip():
                check(f"manifest.domain[{loc}].name", False, "missing/invalid domain")
                continue
            if name in manifest_names:
                check(f"manifest.domain[{name}].unique", False, "duplicate domain")
            manifest_names.add(name)
            zid = d.get("zone_id")
            check(f"manifest.domain[{name}].zone_id",
                  isinstance(zid, str) and bool(zid.strip()), "missing/invalid zone_id")
            role = d.get("role")
            check(f"manifest.domain[{name}].role", role in ALLOWED_ROLES,
                  f"role={role!r} not in {sorted(ALLOWED_ROLES)}")
            check(f"manifest.domain[{name}].hsts", d.get("hsts_preload") is True,
                  f"hsts_preload={d.get('hsts_preload')!r}")

        # must-be-live roots (brmste.com, brmste.ai, carbon justice, …) hard-fail if absent.
        missing_live = [r for r in registry_cf_must_live if r not in manifest_names]
        check("manifest.covers_must_be_live_roots", not missing_live,
              f"registry must-be-live Cloudflare roots absent from live zones: {missing_live}"
              if missing_live else "all must-be-live roots present")

        # other curated roots only warn (they may not all be active zones yet).
        missing_other = [r for r in registry_cf_roots
                         if r not in manifest_names and r not in registry_cf_must_live]
        if missing_other:
            warnings.append(
                f"curated Cloudflare roots not present in live zones (non-critical): {missing_other}"
            )


ok = len(errors) == 0
report = {
    "schema": "brmste-domains-registry-verify/v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "registry": registry_path,
    "manifest": manifest_path if manifest_present else None,
    "manifest_present": manifest_present,
    "zone_target": zone_target,
    "ok": ok,
    "error_count": len(errors),
    "warning_count": len(warnings),
    "errors": errors,
    "warnings": warnings,
    "checks": checks,
}
with open(out_path, "w") as f:
    json.dump(report, f, indent=2)

passed = sum(1 for c in checks if c["ok"])
print(f"Domains registry verify: {passed}/{len(checks)} checks passed → {out_path}")
for w in warnings:
    print(f"  [WARN] {w}")
for e in errors:
    print(f"  [FAIL] {e}")
if ok:
    print("  [OK] registry valid" + (" + manifest cross-checked" if manifest_present else " (manifest not present — registry-only)"))
sys.exit(0 if ok else 1)
PY
