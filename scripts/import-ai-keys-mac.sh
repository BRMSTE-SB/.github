#!/usr/bin/env bash
# Import AI API keys from Mac Desktop folder → Fort Knox (.env.fort-knox) — NEVER commit.
#
# Default folder (Sachin's Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/AI keys
#
# Usage on Mac:
#   bash scripts/import-ai-keys-mac.sh
#   BRMSTE_AI_KEYS_DIR="/path/to/AI keys" bash scripts/import-ai-keys-mac.sh
#   bash scripts/import-ai-keys-mac.sh ~/Desktop/API keys - Copy/AI keys
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/ai-lane-manifest.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

KEYS_DIR="${1:-${BRMSTE_AI_KEYS_DIR:-/Users/sachindabas/Desktop/API keys - Copy/AI keys}}"

if [[ ! -d "$KEYS_DIR" ]]; then
  echo "ERROR: keys folder not found: $KEYS_DIR" >&2
  echo "Set BRMSTE_AI_KEYS_DIR or pass path as first argument." >&2
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: missing $MANIFEST — clone BRMSTE-SB/.github first." >&2
  exit 1
fi

echo "==> BRMSTE Fort Knox AI key import"
echo "    From: $KEYS_DIR"
echo "    To:   $OUT (never committed to git)"

python3 - <<'PY' "$MANIFEST" "$KEYS_DIR" "$OUT"
import json, pathlib, re, sys
from datetime import datetime, timezone

manifest_path, keys_dir, out_path = sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
manifest = json.loads(pathlib.Path(manifest_path).read_text())
lines = [
    "# BRMSTE Fort Knox — AI API keys — DO NOT COMMIT",
    f"# imported_at={datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
    f"# source_dir={keys_dir}",
    "",
]
missing = []
imported = []

for p in manifest.get("providers", []):
    env = p["env_var"]
    fname = p["mac_key_file"]
    fpath = keys_dir / fname
    if not fpath.is_file():
        missing.append(fname)
        continue
    raw = fpath.read_text(encoding="utf-8", errors="replace").strip()
    key = ""
    for line in raw.splitlines():
        line = line.strip().strip('"').strip("'")
        if line and not line.startswith("#"):
            key = line
            break
    if not key:
        missing.append(fname + " (empty)")
        continue
    # sanitize for shell env (no newlines)
    key = re.sub(r"[\r\n]", "", key)
    lines.append(f"{env}={key}")
    imported.append(p["id"])

out_path.write_text("\n".join(lines) + "\n")
print(f"imported={len(imported)} providers: {', '.join(imported)}")
if missing:
    print(f"missing={len(missing)}: {', '.join(missing)}")
PY

chmod 600 "$OUT" 2>/dev/null || true

echo ""
echo "DONE — load on Mac:"
echo "  set -a && source \"$OUT\" && set +a"
echo ""
echo "Never commit .env.fort-knox or paste keys into OPEN ALL repos."
