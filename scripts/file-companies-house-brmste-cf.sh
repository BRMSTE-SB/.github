#!/usr/bin/env bash
# BRMSTE LTD · Companies House filing via Cloudflare Worker (brmste-companies-house-live)
#
# Requires:
#   CH_CF_BASE — default https://brmste.com/api/ch
#   CH_WORKER_INTERNAL_TOKEN — in .env.fort-knox
#   Worker deployed + route brmste.com/api/ch/* attached
#
# Usage:
#   bash scripts/file-companies-house-brmste-cf.sh oauth-url
#   bash scripts/file-companies-house-brmste-cf.sh status
#   bash scripts/file-companies-house-brmste-cf.sh file-correspondence
#   bash scripts/file-companies-house-brmste-cf.sh file-it
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

BASE="${CH_CF_BASE:-https://brmste.com/api/ch}"
TOKEN="${CH_WORKER_INTERNAL_TOKEN:-${BRMSTE_CH_WORKER_TOKEN:-}}"
CMD="${1:-help}"
shift || true

auth_header() {
  if [[ -z "$TOKEN" ]]; then
    echo "Set CH_WORKER_INTERNAL_TOKEN in .env.fort-knox" >&2
    exit 1
  fi
}

case "$CMD" in
  oauth-url)
    curl -sS "${BASE}/oauth/url" | python3 -m json.tool
    echo ""
    echo "Open authorize_url in browser → sign in → BRMSTE auth code → callback stores tokens in CF KV"
    ;;
  status)
    curl -sS "${BASE}/status" | python3 -m json.tool
    ;;
  compare)
    curl -sS "${BASE}/company/15310393/registered-office-address" | python3 -m json.tool
    echo "--- officers ---"
    curl -sS "${BASE}/company/15310393/officers" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for i in d.get('items',[]):
  print(i.get('name'), i.get('address',{}).get('postal_code'))
"
    ;;
  sync)
    auth_header
    curl -sS -X POST "${BASE}/sync" -H "X-CH-Worker-Token: $TOKEN" | python3 -m json.tool
    ;;
  file-roa)
    auth_header
    curl -sS -X POST "${BASE}/file/brmste-roa" -H "X-CH-Worker-Token: $TOKEN" | python3 -m json.tool
    ;;
  file-correspondence)
    auth_header
    curl -sS -X POST "${BASE}/file/brmste-correspondence" \
      -H "X-CH-Worker-Token: $TOKEN" | python3 -m json.tool
    ;;
  file-it)
    auth_header
    curl -sS -X POST "${BASE}/file/brmste-it" \
      -H "X-CH-Worker-Token: $TOKEN" | python3 -m json.tool
    ;;
  poll)
    TXN="${1:-}"
    if [[ -z "$TXN" ]]; then
      echo "usage: $0 poll <transaction_id>" >&2
      exit 1
    fi
    auth_header
    curl -sS "${BASE}/transaction/${TXN}" -H "X-CH-Worker-Token: $TOKEN" | python3 -m json.tool
    ;;
  help|*)
    echo "BRMSTE LTD · Companies House via Cloudflare Worker"
    echo "Base: $BASE"
    echo ""
    echo "  oauth-url            GET authorize URL (open in browser)"
    echo "  status               Worker + bundle status"
    echo "  compare              Live ROA + officer postcodes"
    echo "  sync                 Force REST + stream pull"
    echo "  file-roa             POST AD01 if ROA drift"
    echo "  file-correspondence  POST PSC04 + CH01 Horseferry"
    echo "  file-it              ROA + correspondence"
    echo "  poll <txn_id>        Poll transaction"
    echo ""
    echo "Deploy: bash scripts/deploy-companies-house-worker-mac.sh"
    ;;
esac
