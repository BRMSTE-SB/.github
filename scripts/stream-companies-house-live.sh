#!/usr/bin/env bash
# GOV.UK Companies House Streaming API — live events for BRMSTE lane filings
#
# Requires Fort Knox:
#   COMPANIES_HOUSE_STREAMING_API_KEY  (Streaming API app — not REST key)
#   COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN (poll-transaction only)
#
# Usage:
#   bash scripts/stream-companies-house-live.sh list-endpoints
#   bash scripts/stream-companies-house-live.sh list-endpoints --target brmste
#   bash scripts/stream-companies-house-live.sh verify-key
#   bash scripts/stream-companies-house-live.sh stream filings --max-events 10
#   bash scripts/stream-companies-house-live.sh stream filings --company-numbers 15310393
#   bash scripts/stream-companies-house-live.sh poll-transaction <transaction_id>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

CMD="${1:-help}"
shift || true

case "$CMD" in
  list-endpoints|verify-key|poll-transaction)
    exec python3 "$ROOT/scripts/companies_house_stream.py" "$CMD" "$@"
    ;;
  stream)
    STREAM_ID="${1:-filings}"
    shift || true
    exec python3 "$ROOT/scripts/companies_house_stream.py" stream --stream "$STREAM_ID" "$@"
    ;;
  help|*)
    echo "Companies House Streaming API · BRMSTE live lane"
    echo ""
    echo "Commands:"
    echo "  list-endpoints [--target brmste]   All live stream + read + filing endpoints"
    echo "  verify-key                         Test streaming API key (companies stream)"
    echo "  stream <id>                        Watch stream (default filings for live filings)"
    echo "    --max-events N  --company-numbers 15310393  --timepoint <tp>  --verbose"
    echo "  poll-transaction <id>              Poll OAuth filing transaction status"
    echo ""
    echo "Register Streaming API app: https://developer.company-information.service.gov.uk"
    echo "Key file: Companies House/COMPANIES-HOUSE-STREAMING-API-KEY.txt"
    echo "Catalog: data/brmste-live-companies-house-endpoints.json"
    ;;
esac
