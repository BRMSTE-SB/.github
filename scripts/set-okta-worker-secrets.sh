#!/usr/bin/env bash
# Push Okta OIDC secrets to brmste-com-coming-soon.
# Used by operator CI — secrets come from env, never from chat or git.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="${WORKER_DIR:-$ROOT/coming-soon}"

fail() { echo "OKTA SECRETS FAIL: $*" >&2; exit 1; }
info() { echo "OKTA SECRETS: $*"; }

[[ -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]] || fail "missing CLOUDFLARE_API_TOKEN / CF_API_TOKEN"
[[ -n "${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}" ]] || fail "missing CLOUDFLARE_ACCOUNT_ID / CF_ACCOUNT_ID"
[[ -n "${OKTA_CLIENT_SECRET:-}" ]] || fail "missing OKTA_CLIENT_SECRET"

cd "$WORKER_DIR"

put_secret() {
  local name="$1" value="$2"
  printf '%s' "$value" | npx wrangler secret put "$name"
  info "set worker secret: $name"
}

put_secret OKTA_CLIENT_SECRET "$OKTA_CLIENT_SECRET"

info "Okta OIDC secret configured on brmste-com-coming-soon"
info "Non-secret vars OKTA_ISSUER + OKTA_CLIENT_ID are in coming-soon/wrangler.toml"
