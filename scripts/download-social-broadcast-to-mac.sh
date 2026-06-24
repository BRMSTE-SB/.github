#!/usr/bin/env bash
# Run on THE KOHINOOR MAC — full social broadcast + all channel binds.
set -euo pipefail

DEST="${1:-$HOME/Downloads/BRMSTE-SOCIAL-ALL}"
EDGE="https://brmste.com"
REPO_RAW="https://raw.githubusercontent.com/BRMSTE-SB/.github/main"

mkdir -p "$DEST/substrate/social" "$DEST/substrate/gi" "$DEST/substrate/meta" \
  "$DEST/substrate/daily" "$DEST/substrate/glasswing" "$DEST/api" "$DEST/github"

echo "→ Social broadcast collect to $DEST"

SOCIAL_JSON=(
  hourly-posts.json
  paid-subscriptions.json
  linkedin.json
  x.json
  youtube.json
  instagram.json
  x-ads-api.json
)
for j in "${SOCIAL_JSON[@]}"; do
  curl -fsSL "$EDGE/substrate/social/$j" -o "$DEST/substrate/social/$j"
  echo "  substrate/social/$j"
done

curl -fsSL "$EDGE/substrate/gi/instagram.json" -o "$DEST/substrate/gi/instagram.json"
curl -fsSL "$EDGE/substrate/meta/business-settings.json" -o "$DEST/substrate/meta/business-settings.json"
curl -fsSL "$EDGE/substrate/daily/updates-manifest.json" -o "$DEST/substrate/daily/updates-manifest.json"
curl -fsSL "$EDGE/substrate/glasswing/truth.json" -o "$DEST/substrate/glasswing/truth.json"
curl -fsSL "$EDGE/substrate/hetzner/hourly-posts.json" -o "$DEST/substrate/hetzner-hourly-posts.json"

curl -fsSL "$EDGE/api/rails/hourly-posts/status" -o "$DEST/api/hourly-posts-status.json"
curl -fsSL "$EDGE/api/rails/hourly-posts/verify" -o "$DEST/api/hourly-posts-verify.json"
curl -fsSL "$EDGE/api/rails/daily-updates/status" -o "$DEST/api/daily-updates-status.json"
curl -fsSL "$EDGE/api/rails/whatsapp-notify/status" -o "$DEST/api/whatsapp-notify-status.json"

curl -fsSL "$REPO_RAW/data/social/channels-direct-integration.json" -o "$DEST/github/channels-direct-integration.json"
curl -fsSL "$REPO_RAW/data/social/broadcast-manifest.json" -o "$DEST/github/broadcast-manifest.json"
curl -fsSL "$REPO_RAW/data/social/mcp-integration.json" -o "$DEST/github/mcp-integration.json"
curl -fsSL "$REPO_RAW/docs/SOCIAL-MCP-INTEGRATION.md" -o "$DEST/github/SOCIAL-MCP-INTEGRATION.md"

MANIFEST="$DEST/COLLECT-MANIFEST.txt"
{
  echo "BRMSTE Social broadcast collect · $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "dest: $DEST"
  find "$DEST" -type f ! -name 'COLLECT-MANIFEST.txt' | sort | while read -r f; do
    sha256sum "$f"
  done
} > "$MANIFEST"

echo ""
echo "DONE — open $DEST"
open "$DEST" 2>/dev/null || true
