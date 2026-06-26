#!/usr/bin/env bash
# Verify GOV.UK Companies House live API key (public data API)
#
# Usage:
#   bash scripts/verify-companies-house-api-key.sh
#   bash scripts/verify-companies-house-api-key.sh brmste
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
TARGET="${1:-brmste}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

exec python3 "$ROOT/scripts/companies_house_api.py" --target "$TARGET" verify-api-key
