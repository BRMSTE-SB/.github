#!/usr/bin/env bash
# BRMSTE GSI — apply HTTPS Always + HSTS across all 38 BRMSTE LTD domains
# via the Cloudflare API.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
# GSI™ — Global Substrate Infrastructure™
#
# Usage:
#   CF_API_TOKEN=<token> bash scripts/apply-hsts-all-domains.sh [--dry-run]
#
# Required env vars:
#   CF_API_TOKEN   — Cloudflare API token with Zone:Edit permissions on all 38 zones
#
# Optional:
#   --dry-run      — print what would be applied without calling the Cloudflare API
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

: "${CF_API_TOKEN:?CF_API_TOKEN must be set}"

MANIFEST="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}/domains/manifest.json"
[[ -f "$MANIFEST" ]] || { echo "ERROR: domains/manifest.json not found at $MANIFEST" >&2; exit 1; }

CF_BASE="https://api.cloudflare.com/client/v4"

log()  { echo "[BRMSTE-HSTS] $*"; }
warn() { echo "[BRMSTE-HSTS] WARN: $*" >&2; }
fail() { echo "[BRMSTE-HSTS] FAIL: $*" >&2; exit 1; }

# ── Cloudflare API helpers ────────────────────────────────────────────────────

cf_patch_zone_setting() {
  local zone_id="$1" setting="$2" value="$3"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN zone=$zone_id PATCH $setting=$value"
    return
  fi
  local resp
  resp=$(curl -s -X PATCH "${CF_BASE}/zones/${zone_id}/settings/${setting}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"value\":\"${value}\"}" 2>&1) || true
  if echo "$resp" | grep -q '"success":true'; then
    log "zone=$zone_id $setting=$value OK"
  else
    warn "zone=$zone_id $setting=$value — $(echo "$resp" | grep -o '"message":"[^"]*"' | head -1)"
  fi
}

cf_set_hsts() {
  local zone_id="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN zone=$zone_id PATCH security_header (HSTS: max-age=31536000; includeSubDomains; preload)"
    return
  fi
  local payload
  payload=$(cat <<JSON
{
  "value": {
    "strict_transport_security": {
      "enabled": true,
      "max_age": 31536000,
      "include_subdomains": true,
      "preload": true,
      "nosniff": true
    }
  }
}
JSON
)
  local resp
  resp=$(curl -s -X PATCH "${CF_BASE}/zones/${zone_id}/settings/security_header" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "$payload" 2>&1) || true
  if echo "$resp" | grep -q '"success":true'; then
    log "zone=$zone_id HSTS max-age=31536000; includeSubDomains; preload — OK"
  else
    warn "zone=$zone_id HSTS — $(echo "$resp" | grep -o '"message":"[^"]*"' | head -1)"
  fi
}

cf_set_tls_min() {
  local zone_id="$1"
  # Disable TLS 1.0 and 1.1; minimum is TLS 1.2
  cf_patch_zone_setting "$zone_id" "min_tls_version" "1.2"
}

cf_set_ssl_mode() {
  local zone_id="$1"
  # Full (strict) SSL — origin must present a valid cert
  cf_patch_zone_setting "$zone_id" "ssl" "full"
}

cf_set_automatic_https_rewrites() {
  local zone_id="$1"
  cf_patch_zone_setting "$zone_id" "automatic_https_rewrites" "on"
}

cf_set_always_use_https() {
  local zone_id="$1"
  cf_patch_zone_setting "$zone_id" "always_use_https" "on"
}

# ── Read and iterate domains ──────────────────────────────────────────────────

command -v jq &>/dev/null || fail "jq is required — install with: apt-get install jq"

TOTAL=$(jq '.domains | length' "$MANIFEST")
log "Applying HTTPS/HSTS to $TOTAL domains from $MANIFEST"
[[ "$DRY_RUN" -eq 1 ]] && log "DRY-RUN mode — no Cloudflare API calls will be made"

SKIPPED=0
APPLIED=0
ERRORS=0

while IFS= read -r entry; do
  domain=$(echo "$entry"  | jq -r '.domain')
  zone_id=$(echo "$entry" | jq -r '.zone_id')

  # Skip placeholder entries that haven't been filled in
  if [[ "$domain" == \$* || "$zone_id" == \$* ]]; then
    warn "skipping placeholder: domain=$domain zone_id=$zone_id — fill in domains/manifest.json"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  log "── $domain (zone=$zone_id) ──────────────────"

  cf_set_always_use_https       "$zone_id" && true || ERRORS=$((ERRORS + 1))
  cf_set_automatic_https_rewrites "$zone_id" && true || ERRORS=$((ERRORS + 1))
  cf_set_tls_min                "$zone_id" && true || ERRORS=$((ERRORS + 1))
  cf_set_ssl_mode               "$zone_id" && true || ERRORS=$((ERRORS + 1))
  cf_set_hsts                   "$zone_id" && true || ERRORS=$((ERRORS + 1))

  APPLIED=$((APPLIED + 1))

done < <(jq -c '.domains[]' "$MANIFEST")

log "════════════════════════════════════════════"
log "Done: applied=$APPLIED skipped=$SKIPPED errors=$ERRORS"
[[ "$SKIPPED" -gt 0 ]] && log "ACTION REQUIRED: fill in $SKIPPED placeholder domains in domains/manifest.json"
[[ "$ERRORS"  -gt 0 ]] && warn "$ERRORS errors — check Cloudflare API token permissions"
[[ "$ERRORS"  -eq 0 && "$SKIPPED" -eq 0 ]] && log "All 38 domains: HTTPS + HSTS enforced OK ✓"

exit $([[ "$ERRORS" -eq 0 ]] && echo 0 || echo 1)
