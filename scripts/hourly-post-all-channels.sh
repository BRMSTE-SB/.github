#!/usr/bin/env bash
# Hourly drafts + compose open for ALL operator channels (Kohinoor Mac).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date -u +%Y%m%d-%H%M)"
OPEN=false
MCP_ONLY=false
DEST=""

for arg in "$@"; do
  case "$arg" in
    --open) OPEN=true ;;
    --mcp-prompt) MCP_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [DEST] [--open] [--mcp-prompt]"
      echo "  Generates latest-{x,linkedin,youtube,instagram,whatsapp,meta_business}.txt"
      exit 0
      ;;
    *)
      if [[ -z "$DEST" ]]; then
        DEST="$arg"
      fi
      ;;
  esac
done

DEST="${DEST:-$HOME/Downloads/BRMSTE-HOURLY-ALL/$STAMP}"

echo "→ Hourly all-channels bundle: $DEST"
python3 "$ROOT/scripts/generate-hourly-all-channels.py" "$DEST"

if [[ "$MCP_ONLY" == true ]]; then
  cat "$DEST/MCP_BATCH_PROMPT.txt"
  exit 0
fi

echo ""
echo "=== Drafts written ==="
ls -1 "$DEST"/latest-*.txt

MANIFEST="$DEST/manifest.json"
if [[ -f "$MANIFEST" ]]; then
  python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
for p in m['platforms']:
    print(f\"  {p['id']}: {p['char_count']} chars → {p['draft_file']}\")
"
fi

if [[ "$OPEN" == true ]]; then
  echo ""
  echo "→ Opening compose consoles (Mac)"
  if command -v open >/dev/null; then
    python3 -c "
import json, subprocess
with open('$MANIFEST') as f:
    m = json.load(f)
urls = []
for p in m['platforms']:
    if p.get('intent_url'):
        urls.append(p['intent_url'])
    elif p.get('share_url'):
        urls.append(p['share_url'])
    elif p.get('console') and str(p['console']).startswith('http'):
        urls.append(p['console'])
for u in urls:
    print('open', u)
    subprocess.run(['open', u], check=False)
"
    echo "Opened X intent · LinkedIn share · consoles. Paste from latest-*.txt"
  else
    echo "No 'open' command — use manifest.json URLs on Kohinoor Mac"
  fi
fi

echo ""
echo "MCP (connected Cursor): cat $DEST/MCP_BATCH_PROMPT.txt"
echo "Cron (Mac hourly): 0 * * * * $ROOT/scripts/hourly-post-all-channels.sh --open"
