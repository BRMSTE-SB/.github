#!/usr/bin/env bash
# Attach brmste-quantum-gi Worker to quantum routes on brmste.ai + brmste.com.
# Requires CF_API_TOKEN (operator-managed — never in chat).
set -euo pipefail

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
WORKER_NAME="${WORKER_NAME:-brmste-quantum-gi}"
CF_BASE="https://api.cloudflare.com/client/v4"

ROUTES=(
  "brmste.ai|brmste.ai/quantum/*"
  "brmste.ai|brmste.ai/substrate/quantum/*"
  "brmste.com|brmste.com/quantum/*"
  "brmste.com|brmste.com/substrate/quantum/*"
)

cf_get() {
  curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" "$1"
}

for entry in "${ROUTES[@]}"; do
  zone_name="${entry%%|*}"
  pattern="${entry##*|}"
  zone_id=$(cf_get "${CF_BASE}/zones?name=${zone_name}" | jq -r '.result[0].id')
  [[ -n "$zone_id" && "$zone_id" != "null" ]] || { echo "zone not found: ${zone_name}" >&2; continue; }
  exists=$(cf_get "${CF_BASE}/zones/${zone_id}/workers/routes" | jq -e --arg p "$pattern" --arg w "$WORKER_NAME" \
    '.result[] | select(.pattern == $p and .script == $w)' >/dev/null 2>&1 && echo yes || echo no)
  if [[ "$exists" == "yes" ]]; then
    echo "skip ${pattern} → ${WORKER_NAME} (exists)"
    continue
  fi
  payload=$(jq -nc --arg p "$pattern" --arg s "$WORKER_NAME" '{pattern:$p, script:$s}')
  curl -fsS -X POST "${CF_BASE}/zones/${zone_id}/workers/routes" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null
  echo "created route ${pattern} → ${WORKER_NAME}"
done

echo "Quantum GI routes bound."
