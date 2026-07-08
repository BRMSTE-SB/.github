#!/usr/bin/env bash
# Deploy brmste-quantum-gi Cloudflare Worker.
# Secrets: wrangler secret put IBM_QUANTUM_API_KEY (operator only — never in repo).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="$ROOT/workers"

fail() { echo "QUANTUM-GI DEPLOY FAIL: $*" >&2; exit 1; }
info() { echo "QUANTUM-GI DEPLOY: $*"; }

[[ -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]] || fail "missing CLOUDFLARE_API_TOKEN / CF_API_TOKEN"
[[ -n "${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}" ]] || fail "missing CLOUDFLARE_ACCOUNT_ID / CF_ACCOUNT_ID"

cd "$WORKER_DIR"

if [[ "${1:-}" == "--dry-run" ]]; then
  info "dry-run: npx wrangler deploy --dry-run"
  npx wrangler deploy --dry-run
  exit 0
fi

info "deploying brmste-quantum-gi"
npx wrangler deploy

info "verify: curl -fsS https://<your-route>/health"
info "set secret if needed: printf '%s' \"\$IBM_QUANTUM_API_KEY\" | npx wrangler secret put IBM_QUANTUM_API_KEY"
