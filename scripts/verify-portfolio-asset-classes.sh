#!/usr/bin/env bash
# Verify BRMSTE portfolio asset-class catalog.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="${PORTFOLIO_ASSET_CLASSES:-$ROOT/data/portfolios/asset-classes.json}"

fail() { echo "ASSET CLASSES VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "ASSET CLASSES VERIFY OK: $*"; }

[[ -f "$CATALOG" ]] || fail "catalog missing: $CATALOG"

python3 - <<'PY' "$CATALOG" "$ROOT"
import json, os, sys

catalog_path, root = sys.argv[1], sys.argv[2]
data = json.loads(open(catalog_path).read())

if data.get("schema") != "brmste-portfolio-asset-classes/v1":
    raise SystemExit(f"{catalog_path}: unsupported schema {data.get('schema')}")

required_ids = {
    "crypto", "securities", "isas", "real-estate",
    "portfolio", "metals", "commodities",
}
classes = data.get("classes", [])
found = {c["id"] for c in classes}
missing = required_ids - found
if missing:
    raise SystemExit(f"{catalog_path}: missing class ids {sorted(missing)}")
if data.get("count") != len(classes):
    raise SystemExit(f"{catalog_path}: count {data.get('count')} != {len(classes)} classes")

labels = {c.get("label") for c in classes}
expected_labels = {"CRYPTO", "SECURITIES", "ISAs", "REAL ESTATE", "PORTFOLIO", "METALS", "COMMODITIES"}
if labels != expected_labels:
    raise SystemExit(f"{catalog_path}: unexpected labels {sorted(labels)}")

for cls in classes:
    for key in ("id", "name", "label", "role", "surface"):
        if key not in cls:
            raise SystemExit(f"{catalog_path}: class {cls.get('id')} missing {key}")
    manifest = cls.get("manifest")
    if manifest and not os.path.isfile(os.path.join(root, manifest)):
        raise SystemExit(f"{catalog_path}: manifest not found for {cls['id']}: {manifest}")

print(catalog_path)
PY

ok "$CATALOG · 7 asset classes"
