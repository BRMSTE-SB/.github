#!/usr/bin/env bash
# Build a 100%-invested eToro portfolio from a BRMSTE manifest (market orders by amount).
# Usage:
#   ./scripts/etoro-build-portfolio-100.sh --plan              # no credentials; show allocation plan
#   ./scripts/etoro-build-portfolio-100.sh --dry-run           # resolve symbols only (needs API keys)
#   ./scripts/etoro-build-portfolio-100.sh                     # live build (needs API keys + cash)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${PORTFOLIO_MANIFEST:-$ROOT/data/portfolios/axp-brk-aapl-100.json}"
BASE_URL="${ETORO_BASE_URL:-https://public-api.etoro.com/api/v1}"
V2_BASE_URL="${ETORO_V2_BASE_URL:-https://public-api.etoro.com/api/v2}"
MODE="live"
PLAN_BUDGET="${PORTFOLIO_BUDGET:-10000}"

fail() { echo "PORTFOLIO BUILD FAIL: $*" >&2; exit 1; }
info() { echo "PORTFOLIO BUILD: $*"; }

for arg in "$@"; do
  case "$arg" in
    --plan) MODE="plan" ;;
    --dry-run) MODE="dry-run" ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *) fail "unknown argument: $arg (use --plan, --dry-run, or no args for live build)" ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  fail "manifest not found: $MANIFEST"
fi

ETORO_API_KEY="${ETORO_API_KEY:-${ETORO_X_API_KEY:-${X_API_KEY:-}}}"
ETORO_USER_KEY="${ETORO_USER_KEY:-${ETORO_X_USER_KEY:-${X_USER_KEY:-}}}"

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

require_keys() {
  [[ -n "$ETORO_API_KEY" ]] || fail "missing API key (set ETORO_API_KEY or ETORO_X_API_KEY)"
  [[ -n "$ETORO_USER_KEY" ]] || fail "missing user key (set ETORO_USER_KEY or ETORO_X_USER_KEY)"
}

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

symbol_candidates() {
  python3 - <<'PY' "$1"
import json, sys
symbol = sys.argv[1]
candidates = [symbol]
if symbol == "BRK.B":
    candidates.extend(["BRK-B", "BRKB", "BRK/B"])
print("\n".join(dict.fromkeys(candidates)))
PY
}

resolve_symbol() {
  local symbol="$1" candidate resolved=""
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    resolved="$(curl -fsSL \
      -H "x-api-key: $ETORO_API_KEY" \
      -H "x-user-key: $ETORO_USER_KEY" \
      -H "x-request-id: $(uuid)" \
      "${BASE_URL}/market-data/search?internalSymbolFull=${candidate}" \
      | python3 -c "
import json, sys
symbol = sys.argv[1]
data = json.load(sys.stdin)
items = data.get('items') or data.get('Instruments') or []
for item in items:
    key = item.get('internalSymbolFull') or item.get('symbol') or ''
    if key == symbol:
        iid = item.get('instrumentId') or item.get('instrumentID')
        print(f'{symbol}\t{iid}')
        raise SystemExit(0)
raise SystemExit(1)
" "$candidate" 2>/dev/null || true)"
    if [[ -n "$resolved" ]]; then
      echo "$resolved"
      return 0
    fi
  done < <(symbol_candidates "$symbol")
  fail "could not resolve symbol: $symbol"
}

print_plan() {
  local credit="$1"
  python3 - <<'PY' "$MANIFEST" "$credit"
import json, sys
manifest = json.load(open(sys.argv[1]))
credit = float(sys.argv[2])
print(f"Portfolio: {manifest['name']}")
print(f"Budget:    ${credit:,.2f}")
print()
print(f"{'Symbol':<8} {'Weight':>8}  {'Amount':>12}  Name")
print("-" * 60)
total = 0.0
for h in manifest["holdings"]:
    amount = round(credit * float(h["weight"]), 2)
    total += amount
    print(f"{h['symbol']:<8} {h['weight']*100:7.2f}%  ${amount:11,.2f}  {h['name']}")
print("-" * 60)
print(f"{'TOTAL':<8} {'100.00%':>8}  ${total:11,.2f}")
PY
}

if [[ "$MODE" == "plan" ]]; then
  info "plan mode (no API calls)"
  print_plan "$PLAN_BUDGET"
  exit 0
fi

require_keys

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

info "manifest=$MANIFEST env=$ENV mode=$MODE"

if [[ "$MODE" == "dry-run" ]]; then
  info "resolving symbols"
  while IFS= read -r symbol; do
    [[ -n "$symbol" ]] || continue
    resolve_symbol "$symbol"
  done < <(python3 - <<'PY' "$MANIFEST"
import json, sys
for h in json.load(open(sys.argv[1]))["holdings"]:
    print(h["symbol"])
PY
)
  CREDIT="$(curl -fsSL \
    -H "x-api-key: $ETORO_API_KEY" \
    -H "x-user-key: $ETORO_USER_KEY" \
    -H "x-request-id: $(uuid)" \
    "$PNL_URL" | python3 -c 'import json,sys; print(json.load(sys.stdin)["clientPortfolio"]["credit"])')"
  print_plan "$CREDIT"
  info "dry-run complete — no orders placed"
  exit 0
fi

CREDIT="$(curl -fsSL \
  -H "x-api-key: $ETORO_API_KEY" \
  -H "x-user-key: $ETORO_USER_KEY" \
  -H "x-request-id: $(uuid)" \
  "$PNL_URL" | python3 -c 'import json,sys; print(json.load(sys.stdin)["clientPortfolio"]["credit"])')"

python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$CREDIT" \
  || fail "no available cash (credit=$CREDIT)"

info "available cash: \$${CREDIT}"
print_plan "$CREDIT"

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
    resolve_symbol "$SYMBOL" >/dev/null
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
  | python3 -c '
import json, sys
portfolio = json.load(sys.stdin)["clientPortfolio"]
positions = portfolio.get("positions") or []
print("Open positions after build:", len(positions))
print("Remaining cash: $", portfolio.get("credit"))
'

info "done — verify holdings in eToro app or re-fetch $PNL_URL"
