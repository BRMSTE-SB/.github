#!/usr/bin/env bash
# Route brmste.com Okta auth paths to brmste-okta-auth worker.
set -euo pipefail

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
WORKER_NAME="${WORKER_NAME:-brmste-okta-auth}"
CF_BASE="https://api.cloudflare.com/client/v4"
DOMAINS=(brmste.com brmste.ai)

cf_get() {
  curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" "$1"
}

for zone_name in "${DOMAINS[@]}"; do
  zone_id=$(cf_get "${CF_BASE}/zones?name=${zone_name}" | jq -r '.result[0].id')
  [[ -n "$zone_id" && "$zone_id" != "null" ]] || { echo "zone not found: ${zone_name}" >&2; continue; }
  pattern="${zone_name}/api/auth/okta*"
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
