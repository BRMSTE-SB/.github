#!/usr/bin/env bash
# Deploy brmste-com-coming-soon Worker routes to every zone in the BRMSTE Cloudflare account.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Usage:
#   CF_API_TOKEN=<token> bash scripts/deploy-coming-soon-all-zones.sh [--dry-run]
#
# Optional env:
#   CF_ACCOUNT_ID  — defaults to BRMSTE account 7ea6547b1d6eb1cbd6d0ac5cf960ce2a
#   WORKER_NAME    — defaults to brmste-com-coming-soon
#   EXPECTED_ZONES — defaults to 38 (warn if count differs)
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
WORKER_NAME="${WORKER_NAME:-brmste-com-coming-soon}"
EXPECTED_ZONES="${EXPECTED_ZONES:-38}"
CF_BASE="https://api.cloudflare.com/client/v4"

log()  { echo "[BRMSTE-COMING-SOON] $*"; }
warn() { echo "[BRMSTE-COMING-SOON] WARN: $*" >&2; }
fail() { echo "[BRMSTE-COMING-SOON] FAIL: $*" >&2; exit 1; }

cf_get() {
  curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" "$1"
}

list_all_zones() {
  local page=1
  local zones_json="[]"
  while true; do
    local resp chunk total_pages
    resp=$(cf_get "${CF_BASE}/zones?account.id=${CF_ACCOUNT_ID}&per_page=50&page=${page}&status=active")
    chunk=$(echo "$resp" | jq -c '.result | map({id, name})')
    zones_json=$(jq -nc --argjson a "$zones_json" --argjson b "$chunk" '$a + $b')
    total_pages=$(echo "$resp" | jq -r '.result_info.total_pages // 1')
    if [[ "$page" -ge "$total_pages" ]]; then
      break
    fi
    page=$((page + 1))
  done
  echo "$zones_json"
}

route_exists() {
  local zone_id="$1"
  local pattern="$2"
  local routes
  routes=$(cf_get "${CF_BASE}/zones/${zone_id}/workers/routes" 2>/dev/null || echo '{"result":[]}')
  echo "$routes" | jq -e --arg p "$pattern" --arg w "$WORKER_NAME" \
    '.result[] | select(.pattern == $p and .script == $w)' >/dev/null 2>&1
}

create_route() {
  local zone_id="$1"
  local zone_name="$2"
  local pattern="*${zone_name}/*"

  if route_exists "$zone_id" "$pattern"; then
    log "skip ${zone_name} — route already exists (${pattern} → ${WORKER_NAME})"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN would create route zone=${zone_name} pattern=${pattern} script=${WORKER_NAME}"
    return 0
  fi

  local payload
  payload=$(jq -nc --arg p "$pattern" --arg s "$WORKER_NAME" '{pattern:$p, script:$s}')
  local resp
  resp=$(curl -sS -X POST "${CF_BASE}/zones/${zone_id}/workers/routes" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "$payload")

  if echo "$resp" | jq -e '.success == true' >/dev/null; then
    log "route ${zone_name} OK (${pattern} → ${WORKER_NAME})"
  else
    warn "${zone_name}: $(echo "$resp" | jq -r '.errors[0].message // .')"
  fi
}

main() {
  command -v jq >/dev/null 2>&1 || fail "jq is required"

  log "account=${CF_ACCOUNT_ID} worker=${WORKER_NAME}"
  zones=$(list_all_zones)
  count=$(echo "$zones" | jq 'length')
  log "discovered ${count} active zone(s)"

  if [[ "$count" -ne "$EXPECTED_ZONES" ]]; then
    warn "expected ${EXPECTED_ZONES} zones but found ${count}"
  fi

  echo "$zones" | jq -r '.[] | [.id, .name] | @tsv' | while IFS=$'\t' read -r zone_id zone_name; do
    [[ -n "$zone_id" && -n "$zone_name" ]] || continue
    create_route "$zone_id" "$zone_name"
  done

  log "done — verify with: curl -s https://<domain>/health"
}

main "$@"
