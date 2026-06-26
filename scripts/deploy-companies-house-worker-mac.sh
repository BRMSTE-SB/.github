#!/usr/bin/env bash
# Deploy brmste-companies-house-live Worker + push secrets from Fort Knox (Mac only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="$ROOT/workers/companies-house-live"

if [[ -f "$ROOT/.env.fort-knox" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env.fort-knox"
  set +a
fi

WRANGLER=(wrangler)
if ! command -v wrangler >/dev/null 2>&1; then
  WRANGLER=(npx wrangler)
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "set CLOUDFLARE_API_TOKEN in .env.fort-knox"
  exit 1
fi

push_secret() {
  local name="$1"
  local val="${2:-}"
  if [[ -n "$val" ]]; then
    echo "-> secret $name"
    printf '%s' "$val" | "${WRANGLER[@]}" secret put "$name" --cwd "$WORKER_DIR"
  fi
}

echo "-> build CH bundle for Worker KV"
node "$ROOT/scripts/build-cloudflare-companies-house-bundle.mjs"
bash "$ROOT/scripts/refresh-cloudflare-companies-house-mac.sh"

push_secret COMPANIES_HOUSE_API_KEY "${COMPANIES_HOUSE_API_KEY:-}"
push_secret COMPANIES_HOUSE_STREAMING_API_KEY "${COMPANIES_HOUSE_STREAMING_API_KEY:-}"
push_secret COMPANIES_HOUSE_OAUTH_CLIENT_ID "${COMPANIES_HOUSE_OAUTH_CLIENT_ID:-}"
push_secret COMPANIES_HOUSE_OAUTH_CLIENT_SECRET "${COMPANIES_HOUSE_OAUTH_CLIENT_SECRET:-}"
push_secret COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN "${COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN:-}"
push_secret COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN "${COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN:-}"
push_secret CH_WORKER_INTERNAL_TOKEN "${CH_WORKER_INTERNAL_TOKEN:-${BRMSTE_CH_WORKER_TOKEN:-}}"

echo "-> wrangler deploy"
"${WRANGLER[@]}" deploy --cwd "$WORKER_DIR"

echo "deploy_companies_house_worker_ok"
echo "Attach route: brmste.com/api/ch/* → brmste-companies-house-live"
echo "OAuth callback: https://brmste.com/api/ch/oauth/callback (register in Developer Hub)"
