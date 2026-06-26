#!/usr/bin/env bash
# Import Companies House API + OAuth credentials → Fort Knox (.env.fort-knox)
#
# Default folder:
#   /Users/sachindabas/Desktop/API keys - Copy/Companies House
#
# Usage:
#   bash scripts/import-companies-house-keys-mac.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
KEYS_DIR="${1:-${BRMSTE_CH_KEYS_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Companies House}}"

FILE_MAP=(
  "COMPANIES_HOUSE_API_KEY:COMPANIES-HOUSE-API-KEY.txt"
  "COMPANIES_HOUSE_OAUTH_CLIENT_ID:CH-OAUTH-CLIENT-ID.txt"
  "COMPANIES_HOUSE_OAUTH_CLIENT_SECRET:CH-OAUTH-CLIENT-SECRET.txt"
  "COMPANIES_HOUSE_AUTH_CODE:COMPANIES-HOUSE-AUTH-CODE.txt"
  "COMPANIES_HOUSE_UBS_AUTH_CODE:COMPANIES-HOUSE-UBS-AUTH-CODE.txt"
  "COMPANIES_HOUSE_AMEX_AUTH_CODE:COMPANIES-HOUSE-AMEX-AUTH-CODE.txt"
  "COMPANIES_HOUSE_AIRBUS_AUTH_CODE:COMPANIES-HOUSE-AIRBUS-AUTH-CODE.txt"
  "COMPANIES_HOUSE_BLACKSTONE_AUTH_CODE:COMPANIES-HOUSE-BLACKSTONE-AUTH-CODE.txt"
  "COMPANIES_HOUSE_SIEMENS_AUTH_CODE:COMPANIES-HOUSE-SIEMENS-AUTH-CODE.txt"
  "COMPANIES_HOUSE_MERCEDES_AUTH_CODE:COMPANIES-HOUSE-MERCEDES-AUTH-CODE.txt"
  "COMPANIES_HOUSE_BUGATTI_AUTH_CODE:COMPANIES-HOUSE-BUGATTI-AUTH-CODE.txt"
  "COMPANIES_HOUSE_SOTHEBYS_AUTH_CODE:COMPANIES-HOUSE-SOTHEBYS-AUTH-CODE.txt"
  "COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN:CH-OAUTH-ACCESS-TOKEN.txt"
  "COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN:CH-OAUTH-REFRESH-TOKEN.txt"
)

read_key() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  grep -v '^#' "$f" | head -1 | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '"'"'"
}

existing=()
[[ -f "$OUT" ]] && mapfile -t existing < "$OUT" || true

declare -A merged
for line in "${existing[@]}"; do
  [[ "$line" =~ ^# ]] && continue
  [[ "$line" == *"="* ]] || continue
  k="${line%%=*}"
  merged["$k"]="${line#*=}"
done

imported=0
for pair in "${FILE_MAP[@]}"; do
  env_var="${pair%%:*}"
  fname="${pair#*:}"
  val="$(read_key "$KEYS_DIR/$fname" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then
    merged["$env_var"]="$val"
    imported=$((imported + 1))
  fi
done

merged["COMPANIES_HOUSE_API_ENV"]="${merged[COMPANIES_HOUSE_API_ENV]:-live}"
merged["COMPANIES_HOUSE_OAUTH_REDIRECT_URI"]="${merged[COMPANIES_HOUSE_OAUTH_REDIRECT_URI]:-http://127.0.0.1:8765/companies-house/callback}"

{
  echo "# BRMSTE Fort Knox — Companies House API — DO NOT COMMIT"
  echo "# source_dir=$KEYS_DIR"
  for k in $(printf '%s\n' "${!merged[@]}" | sort); do
    echo "$k=${merged[$k]}"
  done
} > "$OUT"

chmod 600 "$OUT" 2>/dev/null || true
echo "imported=$imported vars into $OUT"
echo "Next: bash scripts/file-companies-house-partner-api.sh ubs profile"
echo "       bash scripts/file-companies-house-partner-api.sh blackstone profile"
echo "       bash scripts/file-companies-house-partner-api.sh airbus profile"
