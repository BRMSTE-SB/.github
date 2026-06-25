#!/usr/bin/env bash
# Verify coming-soon Wrangler Worker builds and serves routes locally.
# No Cloudflare credentials required.
#
# Usage: bash scripts/verify-wrangler-workers.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="${ROOT}/coming-soon"
PORT="${BRMSTE_WRANGLER_PORT:-0}"
if [[ "$PORT" == "0" ]]; then
  PORT=$(python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
)
fi
BASE="http://127.0.0.1:${PORT}"

log()  { echo "[verify-wrangler] $*"; }
fail() { echo "[verify-wrangler] FAIL: $*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

cd "$SITE_DIR"
npm ci --silent

log "wrangler deploy --dry-run"
npm run deploy:dry >/dev/null

if ! grep -q 'run_worker_first = true' wrangler.toml; then
  fail "wrangler.toml must set run_worker_first = true (Wrangler v4 assets default)"
fi

log "starting wrangler dev on port ${PORT}"
npx wrangler dev --local --port "$PORT" >/tmp/brmste-wrangler-dev.log 2>&1 &
WRANGLER_PID=$!
cleanup() {
  kill "$WRANGLER_PID" 2>/dev/null || true
  wait "$WRANGLER_PID" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 30); do
  if curl -fsS "${BASE}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

health=$(curl -fsS "${BASE}/health")
echo "$health" | jq -e '.ok == true and .page == "brmste-coming-soon-v5"' >/dev/null \
  || fail "/health unexpected: ${health}"

for path in / /brand /open /portfolio /broadcast /public/styles.css; do
  status=$(curl -sS -o /dev/null -w '%{http_code}' "${BASE}${path}")
  [[ "$status" == "200" ]] || fail "${path} returned HTTP ${status}"
  log "✓ ${path} → ${status}"
done

unknown=$(curl -sS -o /dev/null -w '%{http_code}' "${BASE}/no-such-page")
[[ "$unknown" == "404" ]] || fail "unknown path should 404, got ${unknown}"
log "✓ /no-such-page → 404"

log "all wrangler worker checks passed"
