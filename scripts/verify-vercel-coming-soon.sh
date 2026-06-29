#!/usr/bin/env bash
# Verify BRMSTE coming-soon on Vercel-hosted domains.
set -euo pipefail

HOSTS="${1:-leadingmetals.com}"

for host in $HOSTS; do
  echo "=== ${host} ==="
  health=$(curl -fsS --max-time 20 "https://${host}/api/health" 2>/dev/null || curl -fsS --max-time 20 "https://${host}/health" 2>/dev/null || echo '{}')
  echo "health: ${health}"
  if echo "$health" | jq -e '.ok == true' >/dev/null 2>&1; then
    echo "✓ health ok"
  else
    echo "⚠ health check failed or not yet deployed"
  fi

  favicon_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "https://${host}/brmste-favicon.svg" || echo "000")
  if [[ "$favicon_status" == "200" ]]; then
    echo "✓ brmste-favicon.svg"
  else
    echo "⚠ brmste-favicon.svg — HTTP ${favicon_status}"
  fi

  brand_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "https://${host}/brand" || echo "000")
  if [[ "$brand_status" == "200" ]]; then
    echo "✓ /brand"
  else
    echo "⚠ /brand — HTTP ${brand_status}"
  fi
done
