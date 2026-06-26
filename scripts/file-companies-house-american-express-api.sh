#!/usr/bin/env bash
# GOV.UK Companies House API — file on behalf of AMERICAN EXPRESS SERVICES EUROPE LIMITED (01833139)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
TARGET="american-express"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

CMD="${1:-help}"
shift || true

case "$CMD" in
  profile|oauth-url|exchange|file)
    exec python3 "$ROOT/scripts/companies_house_api.py" --target "$TARGET" "$CMD" "$@"
    ;;
  help|*)
    echo "GOV.UK Companies House API · AMERICAN EXPRESS SERVICES EUROPE LIMITED · CH 01833139"
    echo ""
    echo "Commands:"
    echo "  profile     Fetch company profile (public API + API key)"
    echo "  oauth-url   Print OAuth URL — sign in + Amex auth code"
    echo "  exchange    Exchange OAuth callback code for bearer token"
    echo "  file        Create filing transaction and submit via API"
    echo ""
    echo "Fort Knox env vars:"
    echo "  COMPANIES_HOUSE_API_KEY"
    echo "  COMPANIES_HOUSE_OAUTH_CLIENT_ID / _SECRET"
    echo "  COMPANIES_HOUSE_AMEX_AUTH_CODE (at OAuth sign-in)"
    echo "  COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN (after exchange)"
    echo ""
    echo "Docs: docs/COMPANIES-HOUSE-API.md"
    ;;
esac
