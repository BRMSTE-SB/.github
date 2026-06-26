#!/usr/bin/env bash
# Sync Cloudflare zone inventory into domains/manifest.json (operator domains 3–38).
# Requires CF_API_TOKEN with Zone:Read on the BRMSTE account.

set -euo pipefail

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${ROOT}/domains/manifest.json"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
CF_BASE="https://api.cloudflare.com/client/v4"

mkdir -p "$(dirname "$MANIFEST")"

zones="[]"
page=1
while true; do
  resp=$(curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" \
    "${CF_BASE}/zones?account.id=${CF_ACCOUNT_ID}&per_page=50&page=${page}&status=active")
  chunk=$(echo "$resp" | jq -c '.result | map({domain: .name, zone_id: .id})')
  zones=$(jq -c --argjson a "$zones" --argjson b "$chunk" '$a + $b' <<< "[]")
  total_pages=$(echo "$resp" | jq -r '.result_info.total_pages // 1')
  [[ "$page" -ge "$total_pages" ]] && break
  page=$((page + 1))
done

count=$(echo "$zones" | jq 'length')

jq -n \
  --argjson zones "$zones" \
  --argjson total "$count" \
  '{
    _meta: {
      owner: "BRMSTE LTD",
      companies_house: "15310393",
      patent: "GB2607860",
      pct: "PCT/GB2026/050406",
      trademark: "BRMSTE™ · GSI — Global Substrate Infrastructure™",
      total_domains: $total,
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
