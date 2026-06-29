#!/usr/bin/env bash
# Run on THE KOHINOOR MAC — collect all Hetzner fleet data + live BRMSTE logos.
set -euo pipefail

DEST="${1:-$HOME/Downloads/BRMSTE-HETZNER-ALL}"
EDGE="https://brmste.com"
REPO_RAW="https://raw.githubusercontent.com/BRMSTE-SB/.github/main"

mkdir -p "$DEST/logos" "$DEST/substrate/hetzner" "$DEST/substrate/brmste" "$DEST/github" "$DEST/hetzner-ssh"

echo "→ Collecting to $DEST"

# --- Live edge logos (SHA-pinned collider = favicon) ---
curl -fsSL "$EDGE/brmste-favicon.svg" -o "$DEST/logos/brmste-carbon-token-collider.svg"
cp "$DEST/logos/brmste-carbon-token-collider.svg" "$DEST/logos/brmste-gsi-collider-logo.svg"
curl -fsSL "$EDGE/favicon.svg" -o "$DEST/logos/favicon.svg"
curl -fsSL "$EDGE/brmste-wordmark.svg" -o "$DEST/logos/brmste-wordmark.svg"
curl -fsSL "$EDGE/brmste-cursor-agent-logo.svg" -o "$DEST/logos/brmste-cursor-agent-logo.svg"

sha256sum "$DEST/logos/brmste-carbon-token-collider.svg" | tee "$DEST/logos/COLLIDER-SHA256.txt"
echo "expected: 03eeeb0b52899510dc75d578210ac802440cf3b3d2c564d459000a7cfda54a79" >> "$DEST/logos/COLLIDER-SHA256.txt"

# --- All Hetzner substrate JSON (15 nodes) ---
HETZNER_JSON=(
  fleet.json
  servers.json
  all-sales-to-paypal.json
  admin-setup.json
  hourly-posts.json
  rain-from-clouds.json
  strategic-russia.json
  friendship.json
)
for j in "${HETZNER_JSON[@]}"; do
  curl -fsSL "$EDGE/substrate/hetzner/$j" -o "$DEST/substrate/hetzner/$j"
  echo "  substrate/hetzner/$j"
done

curl -fsSL "$EDGE/substrate/brmste/hydrated-logos.json" -o "$DEST/substrate/brmste/hydrated-logos.json"
curl -fsSL "$EDGE/substrate/control-plane/manifest.json" -o "$DEST/substrate/control-plane-manifest.json"
curl -fsSL "$EDGE/api/control-plane/hetzner/status" -o "$DEST/hetzner-status.json"
curl -fsSL "$EDGE/api/rails/live-pay/status" -o "$DEST/live-pay-status.json" 2>/dev/null || true

# --- GitHub governance copies ---
curl -fsSL "$REPO_RAW/data/hetzner/servers.json" -o "$DEST/github/servers.json"
curl -fsSL "$REPO_RAW/data/gsi-collider-logo.json" -o "$DEST/github/gsi-collider-logo.json"
curl -fsSL "$REPO_RAW/assets/brmste-carbon-token-collider.svg" -o "$DEST/github/github-collider.svg"

# --- Optional: pull from each Hetzner box (requires ~/.ssh/config brmste-* aliases) ---
if command -v ssh >/dev/null && ssh -G brmste-lucifer-ro 2>/dev/null | grep -q hostname; then
  echo "→ SSH fleet detected — collecting hostname + branding paths from each server"
  while IFS= read -r host; do
  [[ -z "$host" ]] && continue
    safe="${host//[^a-zA-Z0-9_-]/_}"
    ssh -o ConnectTimeout=8 -o BatchMode=yes "$host" 'hostname; ls -la /var/www 2>/dev/null | head -5; ls -la ~/brmste 2>/dev/null | head -5' \
      > "$DEST/hetzner-ssh/${safe}.txt" 2>&1 || echo "ssh_fail $host" >> "$DEST/hetzner-ssh/errors.txt"
  done < <(python3 -c "
import json
with open('$DEST/substrate/hetzner/servers.json') as f:
    for s in json.load(f)['servers']:
        print(s.get('ssh_ro',''))
")
else
  echo "→ SSH skipped (no brmste-* hosts in ~/.ssh/config). Run: npm run setup:server-ssh"
fi

echo ""
echo "DONE — open $DEST"
open "$DEST" 2>/dev/null || true
