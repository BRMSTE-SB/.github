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

ob = hsbc.get("open_banking", {})
if ob.get("developer_portal") != "https://develop.hsbc.com/":
    raise SystemExit(f"{hsbc_path}: open_banking.developer_portal must be https://develop.hsbc.com/")
if ob.get("devhub") != "https://develop.hsbc.com/hsbc-devhub":
    raise SystemExit(f"{hsbc_path}: open_banking.devhub must be https://develop.hsbc.com/hsbc-devhub")

catalog_path = path.replace("networth-valuation.json", "rails/hsbc-api-catalog.json")
catalog = json.loads(open(catalog_path).read())
if catalog.get("count") != 152 or len(catalog.get("apis", [])) != 152:
    raise SystemExit(f"{catalog_path}: must contain 152 apis")

p2p_ref = hsbc.get("p2p", {})
if p2p_ref.get("id") != "hsbc-brmste-p2p":
    raise SystemExit(f"{hsbc_path}: p2p.id must be hsbc-brmste-p2p")

p2p_path = path.replace("networth-valuation.json", "rails/hsbc-brmste-p2p.json")
p2p = json.loads(open(p2p_path).read())
if p2p.get("schema") != "brmste-banking-p2p-rail/v1":
    raise SystemExit(f"{p2p_path}: unsupported schema {p2p.get('schema')}")
if p2p.get("id") != "hsbc-brmste-p2p":
    raise SystemExit(f"{p2p_path}: id must be hsbc-brmste-p2p")
if p2p.get("parent_rail") != "hsbc-uk":
    raise SystemExit(f"{p2p_path}: parent_rail must be hsbc-uk")
if p2p.get("service") != "PISP":
    raise SystemExit(f"{p2p_path}: service must be PISP")
if p2p.get("payment_type") != "domestic_person_to_person":
    raise SystemExit(f"{p2p_path}: payment_type must be domestic_person_to_person")

fiat_p2p = fiat.get("p2p", {})
if fiat_p2p.get("id") != "hsbc-brmste-p2p":
    raise SystemExit(f"{path}: rails.fiat.p2p.id must be hsbc-brmste-p2p")

poll = int(data["realtime"].get("pollIntervalSeconds", 0))
if poll < 10 or poll > 60:
    raise SystemExit(f"{path}: pollIntervalSeconds must be 10-60 (got {poll})")

print(path)
PY

python3 "$LIB" "$FIXTURE" demo >/dev/null || fail "fixture valuation failed"

ok "manifest + fixture valuation in $DIR"
