#!/usr/bin/env bash
# Verify BRMSTE LTD Diamonds OB_INSCRIBED PCT manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${DIAMONDS_MANIFEST:-$ROOT/data/patent/diamonds-ob-inscribed-pct.json}"

fail() { echo "DIAMONDS PCT VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "DIAMONDS PCT VERIFY OK: $*"; }

[[ -f "$ROOT/BRMSTE-DIAMONDS.md" ]] || fail "missing BRMSTE-DIAMONDS.md"
[[ -f "$MANIFEST" ]] || fail "missing manifest: $MANIFEST"

python3 - <<'PY' "$MANIFEST"
import json, sys

path = sys.argv[1]
data = json.load(open(path))

if data.get("schema") != "brmste-diamonds-ob-inscribed-pct/v1":
    raise SystemExit(f"{path}: unsupported schema")
if data.get("patent_pct") != "PCT/GB2026/050406":
    raise SystemExit(f"{path}: patent_pct must be PCT/GB2026/050406")
if data.get("patent_uk") != "GB2607860":
    raise SystemExit(f"{path}: patent_uk must be GB2607860")
if data.get("inscription", {}).get("type") != "OB_INSCRIBED":
    raise SystemExit(f"{path}: inscription.type must be OB_INSCRIBED")

wipo = data.get("wipo_publication", {})
if wipo.get("eucl_document") != "000046":
    raise SystemExit(f"{path}: expected eucl_document 000046")

print(path)
PY

ok "$MANIFEST"
