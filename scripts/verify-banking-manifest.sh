#!/usr/bin/env bash
# Verify BRMSTE banking net worth valuation manifests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${BANKING_DIR:-$ROOT/data/banking}"
LIB="$ROOT/scripts/lib/etoro-networth.py"
FIXTURE="$DIR/fixtures/sample-pnl-snapshot.json"

fail() { echo "BANKING VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "BANKING VERIFY OK: $*"; }

[[ -d "$DIR" ]] || fail "banking directory missing: $DIR"
[[ -f "$LIB" ]] || fail "valuation library missing: $LIB"
[[ -f "$FIXTURE" ]] || fail "fixture missing: $FIXTURE"

MANIFEST="$DIR/networth-valuation.json"
[[ -f "$MANIFEST" ]] || fail "manifest missing: $MANIFEST"

python3 - <<'PY' "$MANIFEST"
import json, sys

path = sys.argv[1]
data = json.loads(open(path).read())

required = {
    "schema", "id", "name", "description", "currency",
    "valuation", "realtime", "rails", "scripts",
}
missing = required - data.keys()
if missing:
    raise SystemExit(f"{path}: missing keys {sorted(missing)}")

if data["schema"] != "brmste-banking-networth-valuation/v1":
    raise SystemExit(f"{path}: unsupported schema {data['schema']}")

if data["valuation"].get("formula") != "equity = availableCash + totalInvested + unrealizedPnL":
    raise SystemExit(f"{path}: unexpected valuation formula")

if data["rails"]["trading"].get("environment") != "real":
    raise SystemExit(f"{path}: rails.trading.environment must be real")

if data["realtime"].get("liveOnly") is not True:
    raise SystemExit(f"{path}: realtime.liveOnly must be true")

fiat = data["rails"].get("fiat", {})
if fiat.get("provider") != "hsbc":
    raise SystemExit(f"{path}: rails.fiat.provider must be hsbc")
if fiat.get("rail") != "hsbc-uk":
    raise SystemExit(f"{path}: rails.fiat.rail must be hsbc-uk")
if fiat.get("currency") != "GBP":
    raise SystemExit(f"{path}: rails.fiat.currency must be GBP")

hsbc_path = path.replace("networth-valuation.json", "rails/hsbc.json")
hsbc = json.loads(open(hsbc_path).read())
if hsbc.get("schema") != "brmste-banking-rail/v1":
    raise SystemExit(f"{hsbc_path}: unsupported schema {hsbc.get('schema')}")
if hsbc.get("id") != "hsbc-uk":
    raise SystemExit(f"{hsbc_path}: id must be hsbc-uk")
if hsbc.get("environment") != "real":
    raise SystemExit(f"{hsbc_path}: environment must be real")

poll = int(data["realtime"].get("pollIntervalSeconds", 0))
if poll < 10 or poll > 60:
    raise SystemExit(f"{path}: pollIntervalSeconds must be 10-60 (got {poll})")

print(path)
PY

python3 "$LIB" "$FIXTURE" demo >/dev/null || fail "fixture valuation failed"

ok "manifest + fixture valuation in $DIR"
