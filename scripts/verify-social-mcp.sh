#!/usr/bin/env bash
# Report MCP server status for social broadcast integration (read-only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== BRMSTE Social · MCP integration status ==="
echo ""

check_env() {
  local var_name="$1"
  if [[ -n "${!var_name:-}" ]]; then
    echo "  OK    env $var_name"
  else
    echo "  MISS  env $var_name"
  fi
}

echo "Sinch MCP"
for v in PROJECT_ID KEY_ID KEY_SECRET CONVERSATION_APP_ID CONVERSATION_REGION DEFAULT_SMS_ORIGINATOR; do
  check_env "$v"
done
echo "  tools: send-whatsapp-template-message · send-text-message · send-template-message (WHATSAPP·INSTAGRAM·MESSENGER·TELEGRAM)"
echo ""

echo "Zapier MCP"
echo "  auth: Connect in Cursor IDE → Settings → Tools & MCP → Zapier"
echo "  tools: list_enabled_zapier_actions · discover_zapier_actions · execute_zapier_read/write_action"
echo ""

echo "Slack MCP"
echo "  auth: Connect in Cursor IDE → Settings → Tools & MCP → Slack"
echo ""

if [[ -f "$ROOT/data/social/mcp-integration.json" ]]; then
  echo "Manifest: data/social/mcp-integration.json"
  python3 -c "
import json
with open('$ROOT/data/social/mcp-integration.json') as f:
    m = json.load(f)
for s in m.get('servers', []):
    print(f'  server {s[\"id\"]}: {s.get(\"status\", \"?\")}')
    for ch in s.get('channels', [])[:4]:
        print(f'    - {ch.get(\"platform\", ch.get(\"sinch_channel\", \"?\"))}')
    extra = len(s.get('channels', [])) - 4
    if extra > 0:
        print(f'    … +{extra} more')
"
else
  echo "MISSING data/social/mcp-integration.json"
  exit 1
fi

echo ""
echo "Policy: docs/SOCIAL-MCP-INTEGRATION.md · SOCIAL-MEDIA-BROADCAST.md"
echo "Writes require operator confirmation — no autonomous publish."
