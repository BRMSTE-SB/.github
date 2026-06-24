#!/usr/bin/env bash
# Cut leadingmetals.com over from Vercel (76.76.21.21) to Cloudflare Worker brmste-com-coming-soon.
#
# BRMSTE LTD · AD LEADING LIMITED · leadingmetals.com
#
# Prerequisites:
#   CF_API_TOKEN — Zone:Read, DNS:Edit, Workers Routes:Edit
#   CF_ACCOUNT_ID — 7ea6547b1d6eb1cbd6d0ac5cf960ce2a
#
# Usage:
#   CF_API_TOKEN=... bash scripts/cutover-leadingmetals-vercel-to-cf.sh [--dry-run]
#
# Also remove leadingmetals.com from Vercel:
#   vercel domains rm leadingmetals.com   # or Vercel dashboard → Domains → Remove

set -euo pipefail

DOMAIN="leadingmetals.com"
WORKER_NAME="${WORKER_NAME:-brmste-com-coming-soon}"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
CF_BASE="https://api.cloudflare.com/client/v4"
VERCEL_A="76.76.21.21"
DRY_RUN=0

for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

log()  { echo "[LEADINGMETALS-CUTOVER] $*"; }
warn() { echo "[LEADINGMETALS-CUTOVER] WARN: $*" >&2; }
fail() { echo "[LEADINGMETALS-CUTOVER] FAIL: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq required"

cf() {
  local method="$1"; shift
  local url="$1"; shift
  if [[ "$DRY_RUN" -eq 1 && "$method" != "GET" ]]; then
    log "DRY-RUN $method $url"
    return 0
  fi
  curl -fsS -X "$method" -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" "$@" "$url"
}

zone_resp=$(cf GET "${CF_BASE}/zones?name=${DOMAIN}")
zone_id=$(echo "$zone_resp" | jq -r '.result[0].id // empty')
[[ -n "$zone_id" && "$zone_id" != "null" ]] || fail "zone not found in CF account: ${DOMAIN}"

log "zone=${DOMAIN} id=${zone_id}"

# List DNS records pointing at Vercel
dns_resp=$(cf GET "${CF_BASE}/zones/${zone_id}/dns_records?per_page=100")
vercel_records=$(echo "$dns_resp" | jq -c --arg ip "$VERCEL_A" \
  '[.result[] | select(.content == $ip or (.content | test("vercel"; "i")))]')

count=$(echo "$vercel_records" | jq 'length')
log "found ${count} Vercel-related DNS record(s)"

echo "$vercel_records" | jq -c '.[]' | while read -r rec; do
  rid=$(echo "$rec" | jq -r '.id')
  rname=$(echo "$rec" | jq -r '.name')
  rtype=$(echo "$rec" | jq -r '.type')
  rcontent=$(echo "$rec" | jq -r '.content')
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN would DELETE ${rtype} ${rname} → ${rcontent}"
  else
    cf DELETE "${CF_BASE}/zones/${zone_id}/dns_records/${rid}" >/dev/null
    log "deleted ${rtype} ${rname} → ${rcontent}"
  fi
done

ensure_proxied_a() {
  local name="$1"
  local existing
  existing=$(echo "$dns_resp" | jq -c --arg n "${name}" \
    '[.result[] | select(.type == "A" and .name == $n)][0] // empty')
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    local rid proxied content
    rid=$(echo "$existing" | jq -r '.id')
    proxied=$(echo "$existing" | jq -r '.proxied')
    content=$(echo "$existing" | jq -r '.content')
    if [[ "$content" == "$VERCEL_A" ]]; then
      : # deleted above
    elif [[ "$proxied" == "true" && "$content" != "$VERCEL_A" ]]; then
      log "keep proxied A ${name} → ${content}"
      return 0
    fi
  fi
  local payload
  payload=$(jq -nc --arg name "$name" --arg ip "192.0.2.1" \
    '{type:"A", name:$name, content:$ip, proxied:true, ttl:1, comment:"BRMSTE Worker apex — proxied"}')
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN would CREATE proxied A ${name} → 192.0.2.1"
  else
    cf POST "${CF_BASE}/zones/${zone_id}/dns_records" --data "$payload" >/dev/null
    log "created proxied A ${name} → 192.0.2.1"
  fi
}

ensure_proxied_a "${DOMAIN}"
ensure_proxied_a "www.${DOMAIN}"

# Worker route
pattern="*${DOMAIN}/*"
routes_resp=$(cf GET "${CF_BASE}/zones/${zone_id}/workers/routes" 2>/dev/null || echo '{"result":[]}')
has_route=$(echo "$routes_resp" | jq -e --arg p "$pattern" --arg w "$WORKER_NAME" \
  '.result[] | select(.pattern == $p and .script == $w)' >/dev/null 2>&1 && echo yes || echo no)

if [[ "$has_route" == "yes" ]]; then
  log "worker route exists: ${pattern} → ${WORKER_NAME}"
else
  payload=$(jq -nc --arg p "$pattern" --arg s "$WORKER_NAME" '{pattern:$p, script:$s}')
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN would CREATE route ${pattern} → ${WORKER_NAME}"
  else
    cf POST "${CF_BASE}/zones/${zone_id}/workers/routes" --data "$payload" >/dev/null
    log "created route ${pattern} → ${WORKER_NAME}"
  fi
fi

log "done — after worker deploy verify:"
log "  curl -s https://${DOMAIN}/health | jq"
log "  curl -sI https://${DOMAIN}/ | grep -i x-brmste-surface"
log ""
log "Remove from Vercel if still attached:"
log "  https://vercel.com/dashboard → Project → Domains → remove ${DOMAIN}"
