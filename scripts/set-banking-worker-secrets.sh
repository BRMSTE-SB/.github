#!/usr/bin/env bash
# Push eToro secrets to brmste-com-coming-soon for live banking valuation.
# Used by GitHub Actions — secrets come from CI env, never from chat.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="${WORKER_DIR:-$ROOT/coming-soon}"

fail() { echo "BANKING SECRETS FAIL: $*" >&2; exit 1; }
info() { echo "BANKING SECRETS: $*"; }

[[ -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]] || fail "missing CLOUDFLARE_API_TOKEN / CF_API_TOKEN"
[[ -n "${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}" ]] || fail "missing CLOUDFLARE_ACCOUNT_ID / CF_ACCOUNT_ID"
[[ -n "${ETORO_API_KEY:-}" ]] || fail "missing ETORO_API_KEY"
[[ -n "${ETORO_USER_KEY:-}" ]] || fail "missing ETORO_USER_KEY"

cd "$WORKER_DIR"

put_secret() {
  local name="$1" value="$2"
  printf '%s' "$value" | npx wrangler secret put "$name"
  info "set worker secret: $name"
}

put_secret ETORO_API_KEY "$ETORO_API_KEY"
put_secret ETORO_USER_KEY "$ETORO_USER_KEY"
put_secret ETORO_ENV "${ETORO_ENV:-real}"

info "live banking secrets configured on brmste-com-coming-soon"
