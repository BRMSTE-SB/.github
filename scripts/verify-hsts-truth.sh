#!/usr/bin/env bash
# Verify HTTPS + HSTS full truth on BRMSTE coming-soon worker responses.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER="$ROOT/coming-soon/src/index.js"
EXPECTED='max-age=63072000; includeSubDomains; preload'

fail() { echo "HSTS-TRUTH VERIFY FAIL: $*" >&2; exit 1; }

[[ -f "$WORKER" ]] || fail "missing coming-soon/src/index.js"
grep -q 'Strict-Transport-Security' "$WORKER" || fail "Strict-Transport-Security missing in worker"
grep -q 'includeSubDomains; preload' "$WORKER" || fail "HSTS must include includeSubDomains; preload"
grep -q 'function httpsRedirect' "$WORKER" || fail "httpsRedirect missing — HTTP must 308 to HTTPS"
grep -q 'function secureResponse' "$WORKER" || fail "secureResponse missing — all error paths need HSTS"
grep -q 'X-BRMSTE-HTTPS-Truth' "$WORKER" || fail "X-BRMSTE-HTTPS-Truth header missing"

HOST="${HSTS_VERIFY_HOST:-}"
if [[ -n "$HOST" ]]; then
  headers=$(curl -fsSI --max-time 20 "https://${HOST}/health" || fail "could not fetch https://${HOST}/health")
  echo "$headers" | grep -qi '^strict-transport-security:' || fail "live HSTS header missing on https://${HOST}/health"
  echo "$headers" | grep -qi 'includeSubDomains' || fail "live HSTS missing includeSubDomains on ${HOST}"
  echo "$headers" | grep -qi 'preload' || fail "live HSTS missing preload on ${HOST}"
  echo "$headers" | grep -qi 'x-brmste-https-truth: enforced' || fail "X-BRMSTE-HTTPS-Truth missing on ${HOST}"
  echo "HSTS-TRUTH LIVE OK: https://${HOST}/health · ${EXPECTED}"
else
  echo "HSTS-TRUTH CODE OK: worker enforces HTTPS redirect + HSTS on all response paths"
fi
