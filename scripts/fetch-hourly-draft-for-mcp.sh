#!/usr/bin/env bash
# Fetch current hourly social draft from brmste edge — ready for MCP publish on connected Cursor.
set -euo pipefail

EDGE="https://brmste.com"
json="$(curl -fsSL "$EDGE/api/rails/hourly-posts/status")"

export HOURLY_JSON="$json"
python3 <<'PY'
import json, os, textwrap

data = json.loads(os.environ["HOURLY_JSON"])
hour = data.get("this_hour", {})
platform = hour.get("platform", "?")
draft = hour.get("draft_preview", "")
console = hour.get("console", "")
label = hour.get("label", platform)

attribution = textwrap.dedent("""
Full Broadcast · Project Glasswing = Shravan Bansal
BRMSTE LTD · Companies House 15310393 · GB2607860
https://brmste.com/truth
""").strip()

full_post = f"{draft}\n\n{attribution}"

print("=== BRMSTE hourly draft for MCP ===")
print(f"platform: {platform} ({label})")
print(f"console:  {console}")
print(f"updated:  {data.get('updated_at', '')}")
print()
print("--- POST BODY (copy or Zapier write) ---")
print(full_post)
print("--- END ---")
print()
print("MCP on connected Cursor:")
print("  Zapier: list_enabled_zapier_actions → execute_zapier_write_action")
print("  Sinch:  send-text-message (WHATSAPP|INSTAGRAM) after operator approves")
PY
