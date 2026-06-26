#!/usr/bin/env bash
# Real-time cash net worth valuation for BRMSTE banking (eToro PnL snapshot).
# Usage:
#   ./scripts/etoro-networth-valuation.sh              # live valuation (needs API keys)
#   ./scripts/etoro-networth-valuation.sh --fixture    # offline demo from fixture
#   ./scripts/etoro-networth-valuation.sh --watch 15   # poll every N seconds
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_URL="${ETORO_BASE_URL:-https://public-api.etoro.com/api/v1}"
MANIFEST="${BANKING_MANIFEST:-$ROOT/data/banking/networth-valuation.json}"
FIXTURE="${BANKING_FIXTURE:-$ROOT/data/banking/fixtures/sample-pnl-snapshot.json}"
LIB="$ROOT/scripts/lib/etoro-networth.py"

fail() { echo "NETWORTH FAIL: $*" >&2; exit 1; }
info() { echo "NETWORTH: $*" >&2; }

MODE="live"
WATCH_INTERVAL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture) MODE="fixture"; shift ;;
    --watch)
      MODE="watch"
      WATCH_INTERVAL="${2:-15}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *) fail "unknown argument: $1 (use --fixture, --watch [seconds], or no args)" ;;
  esac
done

[[ -f "$LIB" ]] || fail "valuation library missing: $LIB"

uuid() { python3 -c 'import uuid; print(uuid.uuid4())'; }

ETORO_API_KEY="${ETORO_API_KEY:-${ETORO_X_API_KEY:-${X_API_KEY:-}}}"
ETORO_USER_KEY="${ETORO_USER_KEY:-${ETORO_X_USER_KEY:-${X_USER_KEY:-}}}"

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

emit_fixture() {
  [[ -f "$FIXTURE" ]] || fail "fixture missing: $FIXTURE"
  python3 "$LIB" "$FIXTURE" demo
}

emit_live() {
  [[ -n "$ETORO_API_KEY" ]] || fail "missing API key (set ETORO_API_KEY)"
  [[ -n "$ETORO_USER_KEY" ]] || fail "missing user key (set ETORO_USER_KEY)"

  local env="${ETORO_ENV:-$(probe_env)}"
  local pnl_url="$BASE_URL/trading/info/${env}/pnl"

  curl -fsSL \
    -H "x-api-key: $ETORO_API_KEY" \
    -H "x-user-key: $ETORO_USER_KEY" \
    -H "x-request-id: $(uuid)" \
    "$pnl_url" | python3 "$LIB" - "$env"
}

run_once() {
  case "$MODE" in
    fixture) emit_fixture ;;
    live|watch) emit_live ;;
    *) fail "unknown mode: $MODE" ;;
  esac
}

if [[ "$MODE" == "watch" ]]; then
  [[ -n "$WATCH_INTERVAL" ]] || WATCH_INTERVAL=15
  info "watching every ${WATCH_INTERVAL}s (Ctrl+C to stop)"
  while true; do
    run_once
    sleep "$WATCH_INTERVAL"
  done
fi

run_once
