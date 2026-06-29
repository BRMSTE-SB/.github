#!/usr/bin/env bash
# Deploy brmste-okta-auth worker (Web OIDC + Service client credentials).
#
# Usage:
#   source .env.fort-knox   # or export CF_API_TOKEN + OKTA_CLIENT_SECRET
#   bash scripts/deploy-okta-auth-worker.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/workers/okta-auth"

if [[ -f "$ROOT/.env.fort-knox" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env.fort-knox"
  set +a
fi

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

if [[ -n "${OKTA_CLIENT_SECRET:-}" ]]; then
  printf '%s' "$OKTA_CLIENT_SECRET" | npx wrangler secret put OKTA_CLIENT_SECRET
fi
if [[ -n "${OKTA_SERVICE_INTERNAL_TOKEN:-}" ]]; then
  printf '%s' "$OKTA_SERVICE_INTERNAL_TOKEN" | npx wrangler secret put OKTA_SERVICE_INTERNAL_TOKEN
fi

export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
npx wrangler deploy

echo "OK: brmste-okta-auth deployed. Mount routes on brmste.com — see docs/OKTA-TRIAL-4122800.md"
