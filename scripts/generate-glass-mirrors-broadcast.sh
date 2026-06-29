#!/usr/bin/env bash
# Generate Glass Mirrors broadcast drafts (Diamonds OB_INSCRIBED PCT attribution).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${GLASS_MIRRORS_MANIFEST:-$ROOT/data/social/glass-mirrors-broadcast.json}"
OUT_DIR="${GLASS_MIRRORS_OUT:-$ROOT/.brmste/glass-mirrors-drafts}"
MODE="plan"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan|--dry-run) MODE="plan" ;;
    --write) MODE="write" ;;
    -h|--help)
      sed -n '2,5p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ -f "$MANIFEST" ]] || { echo "missing manifest: $MANIFEST" >&2; exit 1; }

python3 - <<'PY' "$MANIFEST" "$MODE" "$OUT_DIR"
import json, os, sys
from datetime import datetime, timezone

manifest_path, mode, out_dir = sys.argv[1:4]
data = json.load(open(manifest_path))

mirrors = [m for m in data.get("glass_mirrors", []) if m.get("enabled", True)]
attribution = "\n".join(data["attribution"]["lines"])
headline = data.get("headline", "GLOBAL BROADCAST ALL GLASS MIRRORS")
diamonds = data.get("diamonds", "BRMSTE LTD DIAMONDS OB_INSCRIBED PCT")
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

print(f"# {headline}")
print(f"# {diamonds}")
print(f"# generated: {now}")
print(f"# mirrors: {len(mirrors)}")
print()

body = (
    f"{headline}\n"
    f"{diamonds}\n\n"
    "cloudflare.com = brmste.com = HTTPS = HSTS = Quantum General Intelligence\n"
    "All secrets on Cloudflare. No BRMSTE charges. Only carbon justice.\n\n"
    f"{attribution}\n"
)

for m in mirrors:
    draft = f"[{m['name']} · {m['class']}]\n\n{body}"
    print(f"--- {m['id']} ({m['name']}) ---")
    print(draft)
    if mode == "write":
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, f"latest-{m['id']}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(draft)
        print(f"written: {path}")

if mode == "write":
    print(f"\nWrote {len(mirrors)} drafts to {out_dir}")
PY

echo "GLASS MIRRORS GENERATE OK: $MODE · manifest=$MANIFEST"
