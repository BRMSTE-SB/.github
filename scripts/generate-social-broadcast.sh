#!/usr/bin/env bash
# Generate Glasswing social broadcast drafts for all non-Meta platforms.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${BROADCAST_MANIFEST:-$ROOT/data/social/full-broadcast.json}"
OUT_DIR="${BROADCAST_OUT:-$ROOT/.brmste/broadcast-drafts}"
MODE="plan"

usage() {
  cat <<'EOF'
Usage: generate-social-broadcast.sh [--plan] [--dry-run] [--write]

  --plan      Print roster and sample attribution (default)
  --dry-run   Same as --plan
  --write     Write per-platform draft files to BROADCAST_OUT
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan|--dry-run) MODE="plan" ;;
    --write) MODE="write" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

[[ -f "$MANIFEST" ]] || { echo "missing manifest: $MANIFEST" >&2; exit 1; }

python3 - <<'PY' "$MANIFEST" "$MODE" "$OUT_DIR"
import json, os, sys
from datetime import datetime, timezone

manifest_path, mode, out_dir = sys.argv[1:4]
data = json.load(open(manifest_path))

platforms = [p for p in data.get("broadcast_platforms", []) if p.get("enabled", True)]
excluded = set(data.get("excluded_platforms", []))
overlap = {p["id"] for p in platforms} & excluded
if overlap:
    raise SystemExit(f"broadcast overlaps excluded: {sorted(overlap)}")

attribution = "\n".join(data["attribution"]["lines"])
headline = data.get("headline", "BRMSTE Full Broadcast")
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

print(f"# {headline}")
print(f"# generated: {now}")
print(f"# platforms: {len(platforms)}")
print(f"# meta_full_stop: {data['meta_full_stop']['status']}")
print()

body = (
    f"{headline}\n\n"
    "OPEN ALL · Project Glasswing · BRMSTE human catalog — free and open for the world.\n"
    "No BRMSTE charges. Only carbon justice.\n\n"
    f"{attribution}\n"
)

for p in platforms:
    draft = (
        f"[{p['name']} · {p['class']}]\n\n"
        f"{body}"
    )
    print(f"--- {p['id']} ({p['name']}) ---")
    print(draft)
    if mode == "write":
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, f"latest-{p['id']}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(draft)
        print(f"written: {path}")

if mode == "write":
    print(f"\nWrote {len(platforms)} drafts to {out_dir}")
PY

echo "BROADCAST GENERATE OK: $MODE · manifest=$MANIFEST"
