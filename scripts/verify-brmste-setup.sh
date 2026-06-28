#!/usr/bin/env bash
# Verify BRMSTE master setup manifest and referenced artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${BRMSTE_SETUP:-$ROOT/data/brmste-setup.json}"

fail() { echo "BRMSTE SETUP VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "BRMSTE SETUP VERIFY OK: $*"; }

[[ -f "$MANIFEST" ]] || fail "manifest missing: $MANIFEST"

python3 - <<'PY' "$MANIFEST" "$ROOT"
import json, os, sys

path, root = sys.argv[1], sys.argv[2]
data = json.loads(open(path).read())

if data.get("schema") != "brmste-setup/v1":
    raise SystemExit(f"{path}: unsupported schema {data.get('schema')}")

if data.get("live_only") is not True:
    raise SystemExit(f"{path}: live_only must be true")
if data.get("environment") != "real":
    raise SystemExit(f"{path}: environment must be real")

hsbc = data.get("banking", {}).get("hsbc", {})
if hsbc.get("api_count") != 152:
    raise SystemExit(f"{path}: hsbc.api_count must be 152")

portfolio = data.get("portfolio", {}).get("asset_classes", {})
if portfolio.get("count") != 7:
    raise SystemExit(f"{path}: portfolio.asset_classes.count must be 7")

paths = [
    data["banking"]["networth"]["manifest"],
    data["banking"]["rails"]["fiat"]["manifest"],
    data["banking"]["rails"]["p2p"]["manifest"],
    data["banking"]["rails"]["settlement"]["manifest"],
    data["banking"]["hsbc"]["api_catalog_manifest"],
    data["portfolio"]["asset_classes"]["manifest"],
    data["portfolio"]["thought_equity"]["manifest"],
]
for rel in paths:
    full = os.path.join(root, rel)
    if not os.path.isfile(full):
        raise SystemExit(f"{path}: missing referenced file {rel}")

for rel in data.get("verify", []):
    full = os.path.join(root, rel)
    if not os.path.isfile(full):
        raise SystemExit(f"{path}: missing verify script {rel}")

print(path)
PY

ok "$MANIFEST · banking · portfolio · HSBC 152 APIs"
