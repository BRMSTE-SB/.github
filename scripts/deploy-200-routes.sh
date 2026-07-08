#!/usr/bin/env bash
# Bind path-specific Worker routes so key surfaces return 200 without replacing
# existing brmste-mine / wealth-rails catch-alls on brmste.com and brmste.ai.
#
# Usage: CF_API_TOKEN=<token> bash scripts/deploy-200-routes.sh [--dry-run]
#
# BRMSTE LTD · OPERATOR DOESNT BASH · agents/CI only
set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
COMING_SOON="${COMING_SOON_WORKER:-brmste-com-coming-soon}"
QUANTUM_GI="${QUANTUM_GI_WORKER:-brmste-quantum-gi}"
CF_BASE="https://api.cloudflare.com/client/v4"

log()  { echo "[DEPLOY-200] $*"; }
warn() { echo "[DEPLOY-200] WARN: $*" >&2; }

cf_get() {
  curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" "$1"
}

zone_id() {
  local name="$1"
  cf_get "${CF_BASE}/zones?name=${name}" | jq -r '.result[0].id // empty'
}

route_exists() {
  local zid="$1" pattern="$2" worker="$3"
  cf_get "${CF_BASE}/zones/${zid}/workers/routes" 2>/dev/null \
    | jq -e --arg p "$pattern" --arg w "$worker" \
      '.result[] | select(.pattern == $p and .script == $w)' >/dev/null 2>&1
}

create_route() {
  local zone_name="$1" pattern="$2" worker="$3"
  local zid
  zid=$(zone_id "$zone_name")
  [[ -n "$zid" ]] || { warn "zone not found: ${zone_name}"; return 1; }

  if route_exists "$zid" "$pattern" "$worker"; then
    log "skip ${pattern} → ${worker} (exists)"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN would create ${pattern} → ${worker} (zone ${zone_name})"
    return 0
  fi

  local payload resp
  payload=$(jq -nc --arg p "$pattern" --arg s "$worker" '{pattern:$p, script:$s}')
  resp=$(curl -sS -X POST "${CF_BASE}/zones/${zid}/workers/routes" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload")

  if echo "$resp" | jq -e '.success == true' >/dev/null; then
    log "OK ${pattern} → ${worker}"
  else
    warn "${pattern}: $(echo "$resp" | jq -r '.errors[0].message // .')"
    return 1
  fi
}

# coming-soon: health, brand, starmind, substrate (both apex domains)
COMING_SOON_ROUTES=(
  "brmste.com|brmste.com/health"
  "brmste.com|brmste.com/brand"
  "brmste.com|brmste.com/starmind"
  "brmste.com|brmste.com/substrate/*"
  "brmste.ai|brmste.ai/health"
  "brmste.ai|brmste.ai/brand"
  "brmste.ai|brmste.ai/starmind"
  "brmste.ai|brmste.ai/substrate/*"
)

# quantum-gi: quantum API + substrate status (brmste.ai + brmste.com)
QUANTUM_ROUTES=(
  "brmste.ai|brmste.ai/quantum/*"
  "brmste.ai|brmste.ai/substrate/quantum/*"
  "brmste.com|brmste.com/quantum/*"
  "brmste.com|brmste.com/substrate/quantum/*"
)

main() {
  command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
  log "account=${CF_ACCOUNT_ID} coming-soon=${COMING_SOON} quantum=${QUANTUM_GI}"

  local entry zone pattern
  for entry in "${COMING_SOON_ROUTES[@]}"; do
    zone="${entry%%|*}"
    pattern="${entry##*|}"
    create_route "$zone" "$pattern" "$COMING_SOON" || true
  done

  for entry in "${QUANTUM_ROUTES[@]}"; do
    zone="${entry%%|*}"
    pattern="${entry##*|}"
    create_route "$zone" "$pattern" "$QUANTUM_GI" || true
  done

  log "done — verify: bash scripts/verify-200-endpoints.sh"
}

main "$@"
