#!/usr/bin/env bash
# Run on THE KOHINOOR MAC — collect all Hetzner fleet data + live BRMSTE logos.
set -euo pipefail

DEST="${1:-$HOME/Downloads/BRMSTE-HETZNER-ALL}"
EDGE="https://brmste.com"
REPO_RAW="https://raw.githubusercontent.com/BRMSTE-SB/.github/main"
CANONICAL_COLLIDER_SHA="63f7904d6da67632292149652ac4d8e42df7683f93d682a897a9de884278d5dd"

mkdir -p "$DEST/logos" "$DEST/substrate/hetzner" "$DEST/substrate/brmste" \
  "$DEST/substrate/gi" "$DEST/substrate/global-fleet" "$DEST/substrate/control-plane" \
  "$DEST/api" "$DEST/github" "$DEST/hetzner-ssh"

echo "→ Collecting to $DEST"

# --- Live edge logos (SHA-pinned collider = favicon) ---
curl -fsSL "$EDGE/brmste-favicon.svg" -o "$DEST/logos/brmste-carbon-token-collider.svg"
cp "$DEST/logos/brmste-carbon-token-collider.svg" "$DEST/logos/brmste-gsi-collider-logo.svg"
curl -fsSL "$EDGE/favicon.svg" -o "$DEST/logos/favicon.svg"
curl -fsSL "$EDGE/brmste-wordmark.svg" -o "$DEST/logos/brmste-wordmark.svg"
curl -fsSL "$EDGE/brmste-cursor-agent-logo.svg" -o "$DEST/logos/brmste-cursor-agent-logo.svg"

sha256sum "$DEST/logos/brmste-carbon-token-collider.svg" | tee "$DEST/logos/COLLIDER-SHA256.txt"
echo "expected: $CANONICAL_COLLIDER_SHA" >> "$DEST/logos/COLLIDER-SHA256.txt"
actual="$(sha256sum "$DEST/logos/brmste-carbon-token-collider.svg" | awk '{print $1}')"
if [[ "$actual" != "$CANONICAL_COLLIDER_SHA" ]]; then
  echo "WARN collider SHA mismatch — edge may have changed"
fi

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
curl -fsSL "$EDGE/substrate/gi/hetzner.json" -o "$DEST/substrate/gi/hetzner.json"
curl -fsSL "$EDGE/substrate/global-fleet/manifest.json" -o "$DEST/substrate/global-fleet/manifest.json"
curl -fsSL "$EDGE/substrate/control-plane/manifest.json" -o "$DEST/substrate/control-plane/manifest.json"
curl -fsSL "$EDGE/api/control-plane/hetzner/status" -o "$DEST/api/control-plane-hetzner-status.json"
curl -fsSL "$EDGE/api/control-plane/status" -o "$DEST/api/control-plane-status.json"
curl -fsSL "$EDGE/api/rails/live-pay/status" -o "$DEST/api/live-pay-status.json" 2>/dev/null || true

# --- GitHub governance copies (for diff) ---
curl -fsSL "$REPO_RAW/data/hetzner/servers.json" -o "$DEST/github/servers.json"
curl -fsSL "$REPO_RAW/data/gsi-collider-logo.json" -o "$DEST/github/gsi-collider-logo.json"
curl -fsSL "$REPO_RAW/assets/brmste-carbon-token-collider.svg" -o "$DEST/github/github-collider.svg"

# --- Manifest: every file + SHA256 ---
MANIFEST="$DEST/COLLECT-MANIFEST.txt"
{
  echo "BRMSTE Hetzner Mac collect · $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "dest: $DEST"
  echo "collider_expected_sha: $CANONICAL_COLLIDER_SHA"
  find "$DEST" -type f ! -name 'COLLECT-MANIFEST.txt' | sort | while read -r f; do
    sha256sum "$f"
  done
} > "$MANIFEST"

# --- SSH: alias config OR direct IP (Kohinoor Mac + ~/.ssh/brmste keys) ---
ssh_resolved_host() {
  local alias="$1"
  local hn
  hn="$(ssh -G "$alias" 2>/dev/null | awk '/^hostname /{print $2; exit}')"
  [[ -n "$hn" && "$hn" != "$alias" ]]
}

ssh_key_candidates=(
  "$HOME/.ssh/brmste/id_ed25519"
  "$HOME/.ssh/brmste/kohinoor_ed25519"
  "$HOME/.ssh/id_ed25519"
)

pick_ssh_key() {
  local k
  for k in "${ssh_key_candidates[@]}"; do
    [[ -f "$k" ]] && return 0
  done
  return 1
}

probe_server() {
  local label="$1"
  local target="$2"
  local safe="${label//[^a-zA-Z0-9_-]/_}"
  local key_args=()
  for k in "${ssh_key_candidates[@]}"; do
    [[ -f "$k" ]] && key_args+=(-i "$k")
  done
  ssh -o ConnectTimeout=12 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "${key_args[@]}" "$target" \
    'hostname; uname -a; ls -la /var/www 2>/dev/null | head -8; ls -la ~/brmste 2>/dev/null | head -8' \
    > "$DEST/hetzner-ssh/${safe}.txt" 2>&1 \
    || echo "ssh_fail $label $target" >> "$DEST/hetzner-ssh/errors.txt"
}

if ssh_resolved_host "brmste-lucifer-ro"; then
  echo "→ SSH via ~/.ssh/config aliases"
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    probe_server "$host" "$host"
  done < <(python3 -c "
import json
with open('$DEST/substrate/hetzner/servers.json') as f:
    for s in json.load(f)['servers']:
        print(s.get('ssh_ro',''))
")
elif pick_ssh_key; then
  echo "→ SSH via fleet IPs (no brmste-* aliases — using servers.json IPs)"
  python3 -c "
import json
with open('$DEST/substrate/hetzner/servers.json') as f:
    for s in json.load(f)['servers']:
        ip = s.get('ip','')
        rid = s.get('id','')
        ro = s.get('ssh_ro','')
        if ip:
            print(f'{rid}|root@{ip}|{ro}')
" | while IFS='|' read -r rid target ro; do
    probe_server "$rid" "$target"
  done
else
  echo "→ SSH skipped — run on Kohinoor Mac with: npm run setup:server-ssh"
  echo "   (needs ~/.ssh/brmste keys; firewall allows ops IP 152.37.108.90 only)"
fi

echo ""
echo "DONE — open $DEST"
echo "Manifest: $MANIFEST"
open "$DEST" 2>/dev/null || true
