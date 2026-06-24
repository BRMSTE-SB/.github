#!/usr/bin/env bash
# Open X compose with current hourly draft (Kohinoor Mac). MCP Zapier path: docs/SOCIAL-MCP-CONNECTED.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tweet="$(bash "$ROOT/scripts/fetch-hourly-draft-for-mcp.sh" | sed -n '/--- POST BODY/,/--- END ---/p' | sed '1d;$d')"

if [[ -z "$tweet" ]]; then
  echo "Could not fetch draft"
  exit 1
fi

chars="${#tweet}"
echo "Tweet (${chars} chars):"
echo "$tweet"
echo ""

url="https://x.com/intent/tweet?text=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.stdin.read()))" <<<"$tweet")"
echo "$url"

if command -v open >/dev/null; then
  open "$url"
  echo "Opened X compose in browser."
else
  echo "Paste URL above or post at https://x.com/home"
fi
