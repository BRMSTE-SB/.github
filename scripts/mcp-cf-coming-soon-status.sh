#!/usr/bin/env bash
# MCP-assisted status check for brmste-com-coming-soon (no tokens in chat).
# Inventory via Cloudflare-bindings MCP; deploy requires Cloudflare-builds MCP or CI.
set -euo pipefail

WORKER="brmste-com-coming-soon"
ACCOUNT="7ea6547b1d6eb1cbd6d0ac5cf960ce2a"
EXPECTED_PAGE="brmste-coming-soon-v5"

log() { echo "[mcp-cf-status] $*"; }

log "worker=${WORKER} account=${ACCOUNT} expected_page=${EXPECTED_PAGE}"
log ""
log "MCP inventory (agent): Cloudflare-bindings → workers_get_worker / workers_get_worker_code"
log "MCP deploy (agent):     Cloudflare-builds → connect in Cursor Settings → Tools & MCP"
log "CI deploy (operator):   GitHub Actions deploy-coming-soon.yml (secrets in repo settings)"
log ""

for host in brmste.com brmste.ai re-tyre.com businessscience.ai; do
  code=$(curl -sS -o /tmp/health-"$host".json -w "%{http_code}" --max-time 12 "https://${host}/health" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    page=$(jq -r '.page // "?"' /tmp/health-"$host".json 2>/dev/null || echo "?")
    if [[ "$page" == "$EXPECTED_PAGE" ]]; then
      log "✓ ${host}/health → ${page}"
    else
      log "⚠ ${host}/health → page=${page} (want ${EXPECTED_PAGE})"
    fi
  else
    log "✗ ${host}/health → HTTP ${code}"
  fi
done

log ""
log "Local preview (no credentials): cd coming-soon && npx wrangler dev"
