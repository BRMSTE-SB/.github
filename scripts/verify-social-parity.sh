#!/usr/bin/env bash
# Compare data/social vs live brmste.com substrate (excluding governance-only manifests).
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
    echo "MISSING local ${local_path#$ROOT/}"
    FAIL=1
  elif diff -q "$local_path" "$tmp" >/dev/null; then
    echo "MATCH $edge_path"
  else
    echo "DIFF  $edge_path ↔ ${local_path#$ROOT/}"
    FAIL=1
  fi
  rm -f "$tmp"
}

echo "=== Social substrate (live edge vs repo) ==="
for pair in \
  "substrate/social/hourly-posts.json:data/social/hourly-posts.json" \
  "substrate/social/paid-subscriptions.json:data/social/paid-subscriptions.json" \
  "substrate/social/linkedin.json:data/social/linkedin.json" \
  "substrate/social/x.json:data/social/x.json" \
  "substrate/social/youtube.json:data/social/youtube.json" \
  "substrate/social/instagram.json:data/social/instagram.json" \
  "substrate/social/x-ads-api.json:data/social/x-ads-api.json" \
  "substrate/gi/instagram.json:data/social/gi-instagram.json" \
  "substrate/meta/business-settings.json:data/social/meta-business-settings.json" \
  "substrate/daily/updates-manifest.json:data/social/daily-updates-manifest.json" \
  "substrate/glasswing/truth.json:data/social/glasswing-truth.json"; do
  edge_path="${pair%%:*}"
  local_path="$ROOT/${pair##*:}"
  check_json "$edge_path" "$local_path"
done

echo ""
echo "=== Governance manifests (repo only) ==="
for f in channels-direct-integration.json broadcast-manifest.json; do
  if [[ -f "$ROOT/data/social/$f" ]]; then
    echo "OK    data/social/$f"
  else
    echo "MISSING data/social/$f"
    FAIL=1
  fi
done

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "OK — social substrate mirrors live edge."
  exit 0
fi
echo "PARITY FAIL — refresh: bash scripts/download-social-broadcast-to-mac.sh"
exit 1
