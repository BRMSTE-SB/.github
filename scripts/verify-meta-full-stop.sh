#!/usr/bin/env bash
# Enforce full stop on Meta — no Meta platforms in social/runner config.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/meta-full-stop.json"

fail() { echo "META-FULL-STOP FAIL: $*" >&2; exit 1; }
ok() { echo "META-FULL-STOP OK: $*"; }

[[ -f "$MANIFEST" ]] || fail "missing manifest: $MANIFEST"
[[ -f "$ROOT/META-FULL-STOP.md" ]] || fail "missing policy: META-FULL-STOP.md"

grep -q '"status": "full_stop"' "$MANIFEST" || fail "manifest status must be full_stop"

SCAN_FILES=(
  "$ROOT/CARBON-JUSTICE.md"
  "$ROOT/data/open-all.json"
  "$ROOT/data/hetzner/hourly-posts.json"
  "$ROOT/PROJECT-GLASSWING.md"
  "$ROOT/profile/README.md"
)

PATTERN='Facebook|Instagram Reels|Instagram,|WhatsApp|Threads,|Messenger|meta\.com|facebook\.com|instagram\.com|whatsapp\.com|threads\.net'

for file in "${SCAN_FILES[@]}"; do
  [[ -f "$file" ]] || continue
  if grep -qiE "$PATTERN" "$file"; then
    if ! grep -qi 'full stop\|full_stop\|Stopped\|excluded\|META-FULL-STOP' "$file"; then
      fail "Meta platform reference without exclusion context in $file"
    fi
  fi
done

if grep -qiE 'facebook|instagram|whatsapp|threads\.net' "$ROOT/data/hetzner/hourly-posts.json" 2>/dev/null; then
  if ! grep -q 'excluded_platforms' "$ROOT/data/hetzner/hourly-posts.json"; then
    fail "hourly-posts.json must declare excluded_platforms"
  fi
fi

python3 - <<'PY' "$MANIFEST"
import json, sys
data = json.load(open(sys.argv[1]))
required = {"facebook", "instagram", "threads", "whatsapp"}
found = set(data.get("excluded_platforms", []))
missing = required - found
if missing:
    raise SystemExit(f"manifest missing excluded platforms: {sorted(missing)}")
PY

ok "Meta full stop enforced"
