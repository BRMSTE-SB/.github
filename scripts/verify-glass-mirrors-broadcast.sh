#!/usr/bin/env bash
# Verify global broadcast all glass mirrors manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/social/glass-mirrors-broadcast.json"
DIAMONDS="$ROOT/data/patent/diamonds-ob-inscribed-pct.json"
EDGE="$ROOT/data/edge/cloudflare-secrets-doctrine.json"
SOCIAL="$ROOT/data/social/full-broadcast.json"

fail() { echo "GLASS MIRRORS VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "GLASS MIRRORS VERIFY OK: $*"; }

[[ -f "$ROOT/GLASS-MIRRORS-BROADCAST.md" ]] || fail "missing GLASS-MIRRORS-BROADCAST.md"
[[ -f "$MANIFEST" ]] || fail "missing manifest: $MANIFEST"
[[ -f "$DIAMONDS" ]] || fail "missing diamonds manifest"
[[ -f "$EDGE" ]] || fail "missing cloudflare secrets doctrine"
[[ -f "$SOCIAL" ]] || fail "missing social broadcast manifest"

python3 - <<'PY' "$MANIFEST" "$DIAMONDS" "$EDGE" "$SOCIAL" "$ROOT/data/open-all.json"
import json, sys

manifest_path, diamonds_path, edge_path, social_path, open_all_path = sys.argv[1:6]
manifest = json.load(open(manifest_path))
diamonds = json.load(open(diamonds_path))
edge = json.load(open(edge_path))
social = json.load(open(social_path))
open_all = json.load(open(open_all_path))

if manifest.get("schema") != "brmste-glass-mirrors-broadcast/v1":
    raise SystemExit("glass-mirrors schema must be brmste-glass-mirrors-broadcast/v1")
if manifest.get("status") != "active":
    raise SystemExit("glass-mirrors status must be active")
if manifest.get("patent_pct") != diamonds.get("patent_pct"):
    raise SystemExit("patent_pct mismatch between glass-mirrors and diamonds manifests")

mirrors = manifest.get("glass_mirrors", [])
enabled = [m for m in mirrors if m.get("enabled", True)]
if len(enabled) < 5:
    raise SystemExit(f"expected at least 5 glass mirrors, got {len(enabled)}")

if edge.get("identity_binding", {}).get("cloudflare_com") != "brmste.com":
    raise SystemExit("edge identity must bind cloudflare.com to brmste.com")

block = open_all.get("glass_mirrors_broadcast")
if not block:
    raise SystemExit("open-all.json missing glass_mirrors_broadcast block")
if block.get("status") != "active":
    raise SystemExit("open-all glass_mirrors_broadcast status must be active")

if social.get("status") != "active":
    raise SystemExit("social broadcast must be active for glass mirrors")

print(len(enabled))
PY

bash "$ROOT/scripts/verify-diamonds-pct-manifest.sh" >/dev/null

ok "$(python3 -c "import json; print(len([m for m in json.load(open('$MANIFEST'))['glass_mirrors'] if m.get('enabled',True)]))") glass mirror(s)"
