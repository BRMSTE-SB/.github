#!/usr/bin/env bash
# Wire Cloudflare Worker secrets from environment variables.
# Operator-run only — values come from keychain, CI, or local env; never from this repo.
set -euo pipefail

fail() { echo "WIRE SECRETS FAIL: $*" >&2; exit 1; }
info() { echo "WIRE SECRETS: $*"; }

[[ -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]] || fail "missing CLOUDFLARE_API_TOKEN / CF_API_TOKEN"
[[ -n "${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}" ]] || fail "missing CLOUDFLARE_ACCOUNT_ID / CF_ACCOUNT_ID"

put_secret() {
  local worker="$1" name="$2" value="$3"
  [[ -n "$value" ]] || return 0
  printf '%s' "$value" | npx wrangler secret put "$name" --name "$worker"
  info "set $name on $worker"
}

echo "=== BRMSTE Secret Wire (env-driven) ==="
echo "Account: ${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}}"
echo ""

# Grok / xAI
if [[ -n "${XAI_API_KEY:-${GROK_API_KEY:-}}" ]]; then
  KEY="${XAI_API_KEY:-${GROK_API_KEY:-}}"
  for WORKER in brmste-mine brmste-serper brmste-etoro brmste-786x-voyager brmste-glass brmste-shop brmste-admin brmste-quantum-gi; do
    put_secret "$WORKER" XAI_API_KEY "$KEY"
    put_secret "$WORKER" GROK_API_KEY "$KEY"
  done
fi

# eToro
if [[ -n "${ETORO_USER_KEY:-}" ]]; then
  put_secret brmste-etoro ETORO_USER_KEY "$ETORO_USER_KEY"
  put_secret brmste-etoro ETORO_ACCESS_TOKEN "$ETORO_USER_KEY"
fi
if [[ -n "${ETORO_API_KEY:-}" ]]; then
  put_secret brmste-etoro ETORO_API_KEY "$ETORO_API_KEY"
fi

# Market data / chain
for WORKER in brmste-mine brmste-glass; do
  put_secret "$WORKER" COINMARKETCAP_API_KEY "${COINMARKETCAP_API_KEY:-}"
  put_secret "$WORKER" ETHERSCAN_API_KEY "${ETHERSCAN_API_KEY:-}"
  put_secret "$WORKER" MEMPOOL_ENTERPRISE_API_KEY "${MEMPOOL_ENTERPRISE_API_KEY:-}"
done

put_secret brmste-serper SERPER_API_KEY "${SERPER_API_KEY:-}"
put_secret brmste-mine SERPER_API_KEY "${SERPER_API_KEY:-}"
put_secret brmste-shop STRIPE_SECRET_KEY "${STRIPE_SECRET_KEY:-}"
put_secret brmste-mine ANTHROPIC_API_KEY "${ANTHROPIC_API_KEY:-}"
put_secret brmste-786x-voyager ANTHROPIC_API_KEY "${ANTHROPIC_API_KEY:-}"

# IBM Quantum
if [[ -n "${IBM_QUANTUM_API_KEY:-}" ]]; then
  for WORKER in brmste-786x-voyager brmste-quantum-gi; do
    put_secret "$WORKER" IBM_QUANTUM_API_KEY "$IBM_QUANTUM_API_KEY"
  done
else
  info "IBM_QUANTUM_API_KEY not set — skipped (generate at https://cloud.ibm.com/iam/apikeys)"
fi

echo ""
echo "=== Post-wire smoke tests ==="
for url in \
  "https://brmste.ai/mine/stats" \
  "https://brmste.ai/substrate/capabilities" \
  "https://brmste.com/health"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  echo "  $code  $url"
done

echo ""
echo "DONE — wire-all-secrets.sh"
