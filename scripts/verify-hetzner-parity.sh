#!/usr/bin/env bash
# Compare repo data/hetzner + assets vs live brmste.com edge (no SSH required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EDGE="https://brmste.com"
FAIL=0

check_json() {
  local edge_path="$1"
  local local_path="$2"
  local tmp
  tmp="$(mktemp)"
  if ! curl -fsSL "$EDGE/$edge_path" -o "$tmp"; then
    echo "FAIL fetch $edge_path"
    FAIL=1
    rm -f "$tmp"
    return
  fi
  if [[ ! -f "$local_path" ]]; then
    echo "MISSING local $local_path (edge ok)"
    FAIL=1
  elif diff -q "$local_path" "$tmp" >/dev/null; then
    echo "MATCH $edge_path"
  else
    echo "DIFF  $edge_path ↔ ${local_path#$ROOT/}"
    FAIL=1
  fi
  rm -f "$tmp"
}

check_bytes() {
  local url="$1"
  local local_path="$2"
  local tmp
  tmp="$(mktemp)"
  if ! curl -fsSL "$url" -o "$tmp"; then
    echo "FAIL fetch $url"
    FAIL=1
    rm -f "$tmp"
    return
  fi
  if [[ ! -f "$local_path" ]]; then
    echo "MISSING local ${local_path#$ROOT/}"
    FAIL=1
  elif diff -q "$local_path" "$tmp" >/dev/null; then
    echo "MATCH $(basename "$local_path")"
  else
    echo "DIFF  $(basename "$local_path")"
    echo "  local: $(sha256sum "$local_path" | awk '{print $1}')"
    echo "  edge:  $(sha256sum "$tmp" | awk '{print $1}')"
    FAIL=1
  fi
  rm -f "$tmp"
}

echo "=== Hetzner substrate (live edge vs repo) ==="
for j in fleet servers all-sales-to-paypal admin-setup hourly-posts rain-from-clouds strategic-russia friendship; do
  check_json "substrate/hetzner/${j}.json" "$ROOT/data/hetzner/${j}.json"
done

echo ""
echo "=== Control plane + GI + branding ==="
check_json "substrate/control-plane/manifest.json" "$ROOT/data/hetzner/control-plane-manifest.json"
check_json "api/control-plane/hetzner/status" "$ROOT/data/hetzner/hetzner-status.json"
check_json "substrate/brmste/hydrated-logos.json" "$ROOT/data/hetzner/hydrated-logos.json"
check_json "substrate/global-fleet/manifest.json" "$ROOT/data/hetzner/global-fleet-manifest.json"
check_json "substrate/gi/hetzner.json" "$ROOT/data/hetzner/gi-hetzner.json"

echo ""
echo "=== Collider logos (canonical SHA 63f7904d…) ==="
check_bytes "$EDGE/brmste-favicon.svg" "$ROOT/assets/brmste-carbon-token-collider.svg"
check_bytes "$EDGE/brmste-favicon.svg" "$ROOT/assets/brmste-gsi-collider-logo.svg"

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "OK — repo mirrors live edge for all checked registers."
  exit 0
fi
echo "PARITY FAIL — run: bash scripts/download-all-hetzner-to-mac.sh"
exit 1
