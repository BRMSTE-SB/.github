#!/usr/bin/env bash
# Verify HSBC Developer Portal API catalog manifest (152 APIs).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="${HSBC_API_CATALOG:-$ROOT/data/banking/rails/hsbc-api-catalog.json}"

fail() { echo "HSBC API CATALOG VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "HSBC API CATALOG VERIFY OK: $*"; }

[[ -f "$CATALOG" ]] || fail "catalog missing: $CATALOG"

python3 - <<'PY' "$CATALOG"
import json, sys

path = sys.argv[1]
data = json.loads(open(path).read())

if data.get("schema") != "brmste-hsbc-api-catalog/v1":
    raise SystemExit(f"{path}: unsupported schema {data.get('schema')}")

apis = data.get("apis", [])
if len(apis) != 152:
    raise SystemExit(f"{path}: expected 152 apis, got {len(apis)}")
if data.get("count") != 152:
    raise SystemExit(f"{path}: count must be 152")

if data.get("source") != "https://develop.hsbc.com/apis":
    raise SystemExit(f"{path}: source must be https://develop.hsbc.com/apis")

indexes = [a.get("index") for a in apis]
if indexes != list(range(1, 153)):
    raise SystemExit(f"{path}: api indexes must be 1..152 sequential")

for a in apis:
    if not a.get("name"):
        raise SystemExit(f"{path}: api index {a.get('index')} missing name")

print(path)
PY

ok "$CATALOG · 152 APIs from develop.hsbc.com/apis"
