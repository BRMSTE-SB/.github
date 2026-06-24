#!/usr/bin/env bash
# Verify full social media BRMSTE broadcast manifest and runner config.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/social/full-broadcast.json"
HOURLY="$ROOT/data/hetzner/hourly-posts.json"
META_STOP="$ROOT/data/meta-full-stop.json"

fail() { echo "FULL-SOCIAL-BROADCAST FAIL: $*" >&2; exit 1; }
ok() { echo "FULL-SOCIAL-BROADCAST OK: $*"; }

[[ -f "$ROOT/FULL-SOCIAL-BROADCAST.md" ]] || fail "missing policy FULL-SOCIAL-BROADCAST.md"
[[ -f "$MANIFEST" ]] || fail "missing manifest: $MANIFEST"
[[ -f "$HOURLY" ]] || fail "missing hourly-posts: $HOURLY"
[[ -f "$META_STOP" ]] || fail "missing meta-full-stop manifest"

python3 - <<'PY' "$MANIFEST" "$HOURLY" "$META_STOP" "$ROOT/data/open-all.json"
import json, sys

manifest_path, hourly_path, meta_path, open_all_path = sys.argv[1:5]
manifest = json.load(open(manifest_path))
hourly = json.load(open(hourly_path))
meta = json.load(open(meta_path))
open_all = json.load(open(open_all_path))

if manifest.get("schema") != "brmste-full-social-broadcast/v1":
    raise SystemExit("manifest schema must be brmste-full-social-broadcast/v1")
if manifest.get("status") != "active":
    raise SystemExit("manifest status must be active")

broadcast_ids = [p["id"] for p in manifest.get("broadcast_platforms", []) if p.get("enabled", True)]
if len(broadcast_ids) < 10:
    raise SystemExit(f"expected at least 10 broadcast platforms, got {len(broadcast_ids)}")
if len(set(broadcast_ids)) != len(broadcast_ids):
    raise SystemExit("duplicate platform ids in broadcast_platforms")

excluded = set(manifest.get("excluded_platforms", []))
meta_excluded = set(meta.get("excluded_platforms", []))
if not {"facebook", "instagram", "threads", "whatsapp"} <= excluded:
    raise SystemExit("manifest excluded_platforms missing required Meta surfaces")
if not meta_excluded <= excluded:
    missing = sorted(meta_excluded - excluded)
    raise SystemExit(f"manifest must include all meta-full-stop platforms: {missing}")

overlap = set(broadcast_ids) & excluded
if overlap:
    raise SystemExit(f"broadcast_platforms overlaps excluded: {sorted(overlap)}")

hourly_broadcast = hourly.get("broadcast_platforms", [])
if not hourly_broadcast:
    raise SystemExit("hourly-posts.json missing broadcast_platforms")
if set(hourly_broadcast) != set(broadcast_ids):
    raise SystemExit("hourly-posts broadcast_platforms must match manifest enabled ids")

hourly_excluded = set(hourly.get("excluded_platforms", []))
if not meta_excluded <= hourly_excluded:
    raise SystemExit("hourly-posts excluded_platforms must cover meta-full-stop list")

fb = open_all.get("full_social_broadcast")
if not fb:
    raise SystemExit("open-all.json missing full_social_broadcast block")
if fb.get("status") != "active":
    raise SystemExit("open-all full_social_broadcast status must be active")

print(len(broadcast_ids))
PY

bash "$ROOT/scripts/verify-meta-full-stop.sh" >/dev/null

ok "full social broadcast enforced ($(python3 -c "import json; print(len([p for p in json.load(open('$MANIFEST'))['broadcast_platforms'] if p.get('enabled',True)]))") platforms)"
