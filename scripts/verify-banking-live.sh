#!/usr/bin/env bash
# Verify live banking net worth API on production edge.
set -euo pipefail

HOST="${BANKING_HOST:-brmste.com}"
URL="https://${HOST}/api/banking/networth"

fail() { echo "BANKING LIVE VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "BANKING LIVE VERIFY OK: $*"; }

body="$(curl -fsS --max-time 30 "$URL" 2>/dev/null)" || fail "could not reach $URL"

python3 - <<'PY' "$body"
import json, sys

data = json.loads(sys.argv[1])

if data.get("schema") != "brmste-banking-networth-valuation/v1":
    raise SystemExit(f"unexpected schema: {data.get('schema')}")

if data.get("environment") != "real":
    raise SystemExit(f"expected real environment, got {data.get('environment')}")

equity = (data.get("netWorth") or {}).get("equity")
if equity is None:
    raise SystemExit("missing netWorth.equity")

print(f"environment=real equity=${equity:,.2f} asOf={data.get('asOf')}")
PY

banking_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "https://${HOST}/banking" || echo 000)"
[[ "$banking_status" == "200" ]] || fail "/banking returned HTTP $banking_status"

ok "$URL · https://${HOST}/banking"
