#!/usr/bin/env bash
# Sync Cloudflare zone inventory into domains/manifest.json (all BRMSTE zones).
#
# manifest.json is the DERIVED artifact: live Cloudflare zones (domain + zone_id)
# merged with the durable multi-cloud data in domains/registry.json (role, cloud
# lanes, redirect, notes). Edit domains/registry.json by hand — never manifest.json.
#
# Requires CF_API_TOKEN with Zone:Read on the BRMSTE account.
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406

set -euo pipefail

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${ROOT}/domains/manifest.json"
REGISTRY="${ROOT}/domains/registry.json"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
CF_BASE="https://api.cloudflare.com/client/v4"

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
mkdir -p "$(dirname "$MANIFEST")"

# Durable multi-cloud registry (roles + per-domain cloud lanes). Optional but expected.
if [[ -f "$REGISTRY" ]]; then
  registry=$(cat "$REGISTRY")
else
  registry='{"_meta":{},"domains":[]}'
  echo "WARN: ${REGISTRY} not found — writing manifest with heuristic roles only" >&2
fi

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
  --argjson registry "$registry" \
  '
  ($registry.domains // []) as $reg
  | ($reg | map({key: .domain, value: .}) | from_entries) as $byDomain
  | {
    cloudflare: "active",
    hetzner: "relay",
    aws: "planned",
    azure: "planned",
    siemens_iem: "n/a"
  } as $defaultClouds
  | {
    _meta: {
      owner: "BRMSTE LTD",
      companies_house: "15310393",
      patent: "GB2607860",
      pct: "PCT/GB2026/050406",
      cloudflare_account_id: $registry._meta.cloudflare_account_id // "7ea6547b1d6eb1cbd6d0ac5cf960ce2a",
      total_domains: $total,
      expected_total: ($registry._meta.expected_total // $total),
      trademark: "BRMSTE™ · GSI — Global Substrate Infrastructure™",
      clouds: ($registry._meta.clouds // {}),
      description: "DERIVED — Cloudflare zones merged with domains/registry.json. Edit registry.json, then re-run scripts/sync-cf-zones-to-manifest.sh.",
      synced_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    },
    domains: ($zones | to_entries | map(
      .value.domain as $d
      | ($byDomain[$d] // null) as $r
      | {
        id: (.key + 1),
        domain: $d,
        zone_id: .value.zone_id,
        role: ($r.role //
          (if ($d == "carbonjustice.uk" or $d == "www.carbonjustice.uk") then "carbon_justice"
           elif ($d == "brmste.com" or $d == "brmste.ai") then "primary"
           else "coming_soon" end)),
        source: (if $r then "known" else "cloudflare-sync" end),
        hsts_preload: ($r.hsts_preload // true),
        redirect_to: ($r.redirect_to // null),
        clouds: ($r.clouds // $defaultClouds),
        notes: ($r.notes // "Synced from Cloudflare account")
      }))
  }' > "$MANIFEST"

expected=$(echo "$registry" | jq -r '._meta.expected_total // empty')
echo "Wrote ${count} domains to ${MANIFEST}"
if [[ -n "$expected" && "$count" != "$expected" ]]; then
  echo "NOTE: live zone count ${count} differs from registry expected_total ${expected}" >&2
fi
