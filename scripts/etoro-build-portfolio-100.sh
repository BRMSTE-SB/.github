#!/usr/bin/env bash
# Build a 100%-invested eToro portfolio from a BRMSTE manifest (market orders by amount).
# Requires: ETORO_API_KEY, ETORO_USER_KEY. Optional: ETORO_ENV (real|demo), PORTFOLIO_MANIFEST.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${PORTFOLIO_MANIFEST:-$ROOT/data/portfolios/axp-brk-aapl-100.json}"
BASE_URL="${ETORO_BASE_URL:-https://public-api.etoro.com/api/v1}"
V2_BASE_URL="${ETORO_V2_BASE_URL:-https://public-api.etoro.com/api/v2}"

fail() { echo "PORTFOLIO BUILD FAIL: $*" >&2; exit 1; }
info() { echo "PORTFOLIO BUILD: $*"; }

: "${ETORO_API_KEY:?Set ETORO_API_KEY (x-api-key)}"
: "${ETORO_USER_KEY:?Set ETORO_USER_KEY (x-user-key)}"

if [[ ! -f "$MANIFEST" ]]; then
  fail "manifest not found: $MANIFEST"
fi

read -r ENV_OVERRIDE LEVERAGE ORDER_TYPE TRANSACTION ORDER_CURRENCY SETTLEMENT_TYPE <<<"$(python3 - <<'PY' "$MANIFEST"
import json, sys
m = json.load(open(sys.argv[1]))
e = m["etoro"]
print(
    e.get("environment", "real"),
    e.get("leverage", 1),
    e.get("orderType", "mkt"),
    e.get("transaction", "buy"),
    e.get("orderCurrency", "usd"),
    e.get("settlementType", "real"),
)
PY
)"

ENV="${ETORO_ENV:-$ENV_OVERRIDE}"
SPACING="$(python3 - <<'PY' "$MANIFEST"
import json, sys
print(json.load(open(sys.argv[1]))["execution"].get("minOrderSpacingSeconds", 3))
PY
)"
PNL_WAIT="$(python3 - <<'PY' "$MANIFEST"
import json, sys
print(json.load(open(sys.argv[1]))["execution"].get("pnlVerificationWaitSeconds", 10))
PY
)"

uuid() { python3 -c 'import uuid; print(uuid.uuid4())'; }

probe_env() {
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "x-api-key: $ETORO_API_KEY" \
    -H "x-user-key: $ETORO_USER_KEY" \
    -H "x-request-id: $(uuid)" \
    "$BASE_URL/trading/info/real/pnl" 2>/dev/null || echo 000)"
  if [[ "$code" == "200" ]]; then
    echo "real"
  elif [[ "$code" == "403" ]]; then
    echo "demo"
  else
    fail "could not probe key environment (HTTP $code)"
  fi
}

if [[ -z "${ETORO_ENV:-}" ]]; then
  DETECTED="$(probe_env)"
  if [[ "$DETECTED" != "$ENV" ]]; then
    info "key environment is $DETECTED; manifest requested $ENV — using $DETECTED"
    ENV="$DETECTED"
  fi
fi

PNL_URL="$BASE_URL/trading/info/${ENV}/pnl"
if [[ "$ENV" == "demo" ]]; then
  ORDER_URL="$V2_BASE_URL/trading/execution/demo/orders"
else
  ORDER_URL="$V2_BASE_URL/trading/execution/orders"
fi
SEARCH_URL="$BASE_URL/market-data/search"

info "manifest=$MANIFEST env=$ENV"

CREDIT="$(curl -fsSL \
  -H "x-api-key: $ETORO_API_KEY" \
  -H "x-user-key: $ETORO_USER_KEY" \
  -H "x-request-id: $(uuid)" \
  "$PNL_URL" | python3 -c 'import json,sys; print(json.load(sys.stdin)["clientPortfolio"]["credit"])')"

if python3 - <<'PY' "$CREDIT"
import sys
if float(sys.argv[1]) <= 0:
    raise SystemExit(1)
PY
then
  :
else
  fail "no available cash (credit=$CREDIT)"
fi

info "available cash: \$${CREDIT}"

HOLDINGS_JSON="$(python3 - <<'PY' "$MANIFEST" "$CREDIT"
import json, sys
manifest = json.load(open(sys.argv[1]))
credit = float(sys.argv[2])
out = []
for h in manifest["holdings"]:
    amount = round(credit * float(h["weight"]), 2)
    out.append({"symbol": h["symbol"], "name": h["name"], "weight": h["weight"], "amount": amount})
print(json.dumps(out))
PY
)"

place_order() {
  local symbol="$1" amount="$2"
  local body
  body="$(python3 - <<PY
import json
print(json.dumps({
    "action": "open",
    "transaction": "$TRANSACTION",
    "symbol": "$symbol",
    "orderType": "$ORDER_TYPE",
    "leverage": int($LEVERAGE),
    "amount": float($amount),
    "orderCurrency": "$ORDER_CURRENCY",
    "settlementType": "$SETTLEMENT_TYPE",
}))
PY
)"
  curl -fsSL -X POST \
    -H "x-api-key: $ETORO_API_KEY" \
    -H "x-user-key: $ETORO_USER_KEY" \
    -H "x-request-id: $(uuid)" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$ORDER_URL"
}

python3 - <<'PY' "$HOLDINGS_JSON"
import json, sys
holdings = json.loads(sys.argv[1])
total = sum(h["amount"] for h in holdings)
print("Planned allocation:")
for h in holdings:
    print(f"  {h['symbol']:6} {h['weight']*100:6.2f}%  \${h['amount']:,.2f}  {h['name']}")
print(f"  TOTAL  100.00%  \${total:,.2f}")
PY

FIRST=1
while IFS= read -r row; do
  SYMBOL="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["symbol"])' "$row")"
  AMOUNT="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["amount"])' "$row")"
  if [[ "$FIRST" != "1" ]]; then
    info "spacing ${SPACING}s (trade-execution rate limit)"
    sleep "$SPACING"
  fi
  FIRST=0
  if python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) >= 1 else 1)' "$AMOUNT"; then
    info "placing $SYMBOL buy \$$AMOUNT (leverage=$LEVERAGE)"
    RESP="$(place_order "$SYMBOL" "$AMOUNT" || true)"
    echo "$RESP" | python3 -m json.tool 2>/dev/null || echo "$RESP"
  else
    info "skipping $SYMBOL (amount \$${AMOUNT} below \$1 minimum)"
  fi
done < <(python3 - <<'PY' "$HOLDINGS_JSON"
import json, sys
for h in json.loads(sys.argv[1]):
    print(json.dumps(h))
PY
)

info "waiting ${PNL_WAIT}s for PnL cache before verification"
sleep "$PNL_WAIT"

curl -fsSL \
  -H "x-api-key: $ETORO_API_KEY" \
  -H "x-user-key: $ETORO_USER_KEY" \
  -H "x-request-id: $(uuid)" \
  "$PNL_URL" \
  | python3 - <<'PY' "$HOLDINGS_JSON"
import json, sys
holdings = {h["symbol"] for h in json.loads(sys.argv[1])}
portfolio = json.load(sys.stdin)["clientPortfolio"]
positions = portfolio.get("positions") or []
found = {}
for p in positions:
    iid = p.get("instrumentID")
    found[iid] = p
print("Open positions after build:", len(positions))
print("Remaining cash: $", portfolio.get("credit"))
PY

info "done — verify holdings in eToro app or re-fetch $PNL_URL"
