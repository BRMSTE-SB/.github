#!/usr/bin/env bash
# Verify the BRMSTE carbon justice catalog manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="${CARBON_JUSTICE_CATALOG:-$ROOT/data/carbon-justice/catalog.json}"

fail() { echo "CARBON JUSTICE VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "CARBON JUSTICE VERIFY OK: $*"; }

[[ -f "$CATALOG" ]] || fail "catalog manifest missing: $CATALOG"

python3 - "$CATALOG" <<'PY'
import json, sys

path = sys.argv[1]
data = json.loads(open(path).read())

if data.get("schema") != "brmste-carbon-justice-catalog/v1":
    raise SystemExit(f"{path}: unexpected schema {data.get('schema')!r}")

required = (
    "id", "headline", "domain", "entity", "companies_house",
    "software", "clients", "infrastructure", "counts", "surface", "substrate",
)
for key in required:
    if key not in data:
        raise SystemExit(f"{path}: missing {key}")

if data["companies_house"] != "17304635":
    raise SystemExit(f"{path}: companies_house must be 17304635")
if data["domain"] != "carbonjustice.uk":
    raise SystemExit(f"{path}: domain must be carbonjustice.uk")

for section in ("software", "clients", "infrastructure"):
    items = data[section]
    if not items:
        raise SystemExit(f"{path}: {section} empty")
    ids = [i.get("id", "") for i in items]
    if len(ids) != len(set(ids)):
        raise SystemExit(f"{path}: duplicate ids in {section}")
    if data["counts"].get(section) != len(items):
        raise SystemExit(
            f"{path}: counts.{section} {data['counts'].get(section)} != {len(items)}"
        )
    print(f"{section} ok: {len(items)} item(s)")

print(f"catalog ok: {data['headline']} · {data['domain']}")
PY

ok "Carbon justice catalog ${CATALOG}"
