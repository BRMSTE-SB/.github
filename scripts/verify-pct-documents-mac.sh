#!/usr/bin/env bash
# Verify PCT/GB2026/050406 ePCT documents on Mac — record sha256 in manifest.
#
# Usage:
#   bash scripts/verify-pct-documents-mac.sh
#   bash scripts/verify-pct-documents-mac.sh "/Users/shravanbansal/Downloads/dbrmstre^PCTGB2026050406-documents"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/patents/pct-gb2026-050406/manifest.json"
DIR="${1:-$HOME/Downloads/dbrmstre^PCTGB2026050406-documents}"

need() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "missing: $f" >&2
    exit 1
  fi
}

need "$MANIFEST"
need "$DIR/BRMSTE-DIAMOND-CONSOLIDATED.docx"
need "$DIR/PCTGB2026050406-eucl-000046-en-20260629.pdf"
need "$DIR/PCTGB2026050406-amcl-000047-en-20260629.pdf"

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

H_DOCX="$(hash_file "$DIR/BRMSTE-DIAMOND-CONSOLIDATED.docx")"
H_EUCL="$(hash_file "$DIR/PCTGB2026050406-eucl-000046-en-20260629.pdf")"
H_AMCL="$(hash_file "$DIR/PCTGB2026050406-amcl-000047-en-20260629.pdf")"

python3 - <<'PY' "$MANIFEST" "$H_DOCX" "$H_EUCL" "$H_AMCL" "$DIR"
import json, pathlib, sys
from datetime import datetime, timezone

path, h_docx, h_eucl, h_amcl, dir_path = sys.argv[1:6]
data = json.loads(pathlib.Path(path).read_text())
by_id = {d["id"]: d for d in data.get("documents", [])}
updates = {
    "diamond-consolidated": h_docx,
    "eucl-000046": h_eucl,
    "amcl-000047": h_amcl,
}
for doc_id, digest in updates.items():
    doc = by_id.get(doc_id)
    if not doc:
        raise SystemExit(f"missing manifest doc id: {doc_id}")
    doc["sha256"] = digest
    doc["verified_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    doc["verified_path"] = str(pathlib.Path(dir_path).expanduser())
data["verified_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
pathlib.Path(path).write_text(json.dumps(data, indent=2) + "\n")
print("pct_documents_verified_ok")
for doc_id, digest in updates.items():
    print(f"  {doc_id}: {digest[:16]}…")
PY

echo "manifest updated: $MANIFEST"
echo "Fort Knox: keep PDFs/DOCX local; do not commit binaries to OPEN ALL."
