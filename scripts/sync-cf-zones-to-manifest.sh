#!/usr/bin/env bash
# Sync Cloudflare zone inventory into domains/manifest.json (operator domains 3–38).
# Requires CF_API_TOKEN with Zone:Read on the BRMSTE account.

set -euo pipefail

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${ROOT}/domains/manifest.json"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
EXPECTED_ZONES="${EXPECTED_ZONES:-38}"
CF_BASE="https://api.cloudflare.com/client/v4"

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

mkdir -p "$(dirname "$MANIFEST")"

zones="[]"
page=1
while true; do
  resp=$(curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" \
    "${CF_BASE}/zones?account.id=${CF_ACCOUNT_ID}&per_page=50&page=${page}&status=active")
  if ! echo "$resp" | jq -e '.success == true' >/dev/null 2>&1; then
    echo "FAIL: Cloudflare API did not return success on page ${page}: $(echo "$resp" | jq -rc '.errors // .' 2>/dev/null)" >&2
    exit 1
  fi
  chunk=$(echo "$resp" | jq -c '.result | map({domain: .name, zone_id: .id})')
  zones=$(jq -nc --argjson a "$zones" --argjson b "$chunk" '$a + $b')
  total_pages=$(echo "$resp" | jq -r '.result_info.total_pages // 1')
  [[ "$page" -ge "$total_pages" ]] && break
  page=$((page + 1))
done

count=$(echo "$zones" | jq 'length')

if [[ "$count" -ne "$EXPECTED_ZONES" ]]; then
  if [[ "${ALLOW_ZONE_DRIFT:-0}" == "1" ]]; then
    echo "WARN: expected ${EXPECTED_ZONES} zones but found ${count} (ALLOW_ZONE_DRIFT=1)" >&2
  else
    echo "FAIL: expected ${EXPECTED_ZONES} zones but found ${count} — refusing to write a drifted manifest. A permanent count change must update BOTH EXPECTED_ZONES here AND registry._meta.cloudflare_zone_target (plus clouds.cloudflare.zone_target) in domains/registry.json, or the post-sync verifier will reject the new manifest. Use ALLOW_ZONE_DRIFT=1 only for a one-off local sync." >&2
    exit 1
  fi
fi

jq -n \
  --argjson zones "$zones" \
  --argjson total "$count" \
  --argjson expected "$EXPECTED_ZONES" \
  '{
    _meta: {
      owner: "BRMSTE LTD",
      companies_house: "15310393",
      patent: "GB2607860",
      pct: "PCT/GB2026/050406",
      trademark: "BRMSTE™ · GSI — Global Substrate Infrastructure™",
      total_domains: $total,
      cloudflare_zone_target: $expected,
      registry: "domains/registry.json",
      description: "Auto-synced from Cloudflare API. Run scripts/sync-cf-zones-to-manifest.sh to refresh.",
      synced_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    },
    domains: ($zones | to_entries | map({
      id: (.key + 1),
      domain: .value.domain,
      zone_id: .value.zone_id,
      role: (if (.value.domain == "carbonjustice.uk" or .value.domain == "www.carbonjustice.uk") then "carbon_justice"
        elif (.value.domain == "brmste.com" or .value.domain == "brmste.ai") then "primary"
        else "coming_soon" end),
      hsts_preload: true,
      redirect_to: null,
      notes: "Synced from Cloudflare account"
    }))
  }' > "$MANIFEST"

echo "Wrote ${count} domains to ${MANIFEST}"
