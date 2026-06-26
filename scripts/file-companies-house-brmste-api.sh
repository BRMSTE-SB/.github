#!/usr/bin/env bash
# GOV.UK Companies House API — BRMSTE LTD (15310393) address sync
#
# Requires Fort Knox credentials — never commit .env.fort-knox
#
# Usage:
#   bash scripts/file-companies-house-brmste-api.sh profile
#   bash scripts/file-companies-house-brmste-api.sh compare-address
#   bash scripts/file-companies-house-brmste-api.sh oauth-url
#   bash scripts/file-companies-house-brmste-api.sh exchange --code 'AUTH_CODE'
#   bash scripts/file-companies-house-brmste-api.sh update-address --mark-filed
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
  profile|oauth-url|exchange|file|compare-address|update-address)
    exec python3 "$ROOT/scripts/companies_house_api.py" --target brmste "$CMD" "$@"
    ;;
  help|*)
    echo "GOV.UK Companies House API · BRMSTE LTD · CH 15310393"
    echo ""
    echo "Commands:"
    echo "  profile          Fetch company profile (public API + API key)"
    echo "  compare-address  Compare live ROA vs canonical register"
    echo "  oauth-url        OAuth URL — sign in + BRMSTE auth code"
    echo "  exchange         Exchange OAuth callback code"
    echo "  update-address   File AD01 ROA if needed + register PSC04 pending"
    echo ""
    echo "Fort Knox env vars:"
    echo "  COMPANIES_HOUSE_API_KEY"
    echo "  COMPANIES_HOUSE_OAUTH_CLIENT_ID / _SECRET"
    echo "  COMPANIES_HOUSE_BRMSTE_AUTH_CODE (at OAuth sign-in)"
    echo "  COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN (after exchange)"
    echo ""
    echo "Register: data/brmste-ltd-companies-house-register.json"
    echo "Docs: docs/BRMSTE-COMPANIES-HOUSE-ADDRESS.md"
    ;;
esac
