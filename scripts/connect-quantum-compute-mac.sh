#!/usr/bin/env bash
# Connect BRMSTE quantum compute commercial rails · Fort Knox only — NEVER commit.
#
# Default Quantum key folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/Quantum
#
# Usage:
#   bash scripts/connect-quantum-compute-mac.sh
#   bash scripts/connect-quantum-compute-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAILS="$ROOT/data/brmste-quantum-compute-rails.json"
SALES="$ROOT/data/quantum-compute-sales-lane.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

QUANTUM_DIR="${BRMSTE_QUANTUM_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Quantum}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$RAILS" || ! -f "$SALES" ]]; then
  echo "ERROR: missing quantum compute registers." >&2
  exit 1
fi

echo "==> BRMSTE quantum compute rails connect"
echo "    Quantum keys: $QUANTUM_DIR"
echo "    Fort Knox:    $OUT"

python3 - <<'PY' "$RAILS" "$QUANTUM_DIR" "$OUT" "$VERIFY_ONLY"
import json, pathlib, re, sys

rails_path, quantum_dir, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    sys.argv[4].lower() == "true",
)

rails = json.loads(rails_path.read_text())

file_map = {
    "BRMSTE_QUANTUM_API_KEY": "BRMSTE-QUANTUM-API-KEY.txt",
    "BRMSTE_QUANTUM_API_ENDPOINT": "BRMSTE-QUANTUM-ENDPOINT.txt",
    "BRMSTE_QUANTUM_MERCHANT_ID": "BRMSTE-QUANTUM-MERCHANT-ID.txt",
    "BRMSTE_QUANTUM_WEBHOOK_SECRET": "BRMSTE-QUANTUM-WEBHOOK-SECRET.txt",
}

def read_key(path: pathlib.Path) -> str:
    if not path.is_file():
        return ""
    raw = path.read_text(encoding="utf-8", errors="replace").strip()
    for line in raw.splitlines():
        line = line.strip().strip('"').strip("'")
        if line and not line.startswith("#"):
            return re.sub(r"[\r\n]", "", line)
    return ""

existing = {}
if out_path.is_file():
    for line in out_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        existing[k.strip()] = v.strip()

new_vars = {}
for env_var, fname in file_map.items():
    val = read_key(quantum_dir / fname)
    if val:
        new_vars[env_var] = val

new_vars["BRMSTE_QUANTUM_COMPUTE_CONNECTED"] = "true"
new_vars["BRMSTE_CURSOR_QUANTUM_ROUTING"] = "true"
new_vars["BRMSTE_QUANTUM_CAPTURE_BEFORE_EXECUTE"] = "true"

if verify_only:
    ok = existing.get("BRMSTE_QUANTUM_COMPUTE_CONNECTED") == "true"
    endpoint = existing.get("BRMSTE_QUANTUM_API_ENDPOINT") or new_vars.get("BRMSTE_QUANTUM_API_ENDPOINT")
    if not ok:
        print("verify_fail: BRMSTE_QUANTUM_COMPUTE_CONNECTED not true")
        sys.exit(1)
    if not endpoint:
        print("verify_warn: BRMSTE_QUANTUM_API_ENDPOINT missing — set endpoint for Cursor routing")
    print(f"verify_ok quantum_compute connected endpoint={'set' if endpoint else 'missing'}")
    sys.exit(0)

merged = dict(existing)
merged.update(new_vars)
lines = ["# BRMSTE quantum compute rails — Fort Knox — never commit"]
for k in sorted(merged.keys()):
    if k.startswith("BRMSTE_QUANTUM") or k == "BRMSTE_CURSOR_QUANTUM_ROUTING":
        lines.append(f"{k}={merged[k]}")
for k, v in merged.items():
    if k not in {x.split("=")[0] for x in lines[1:]} and "=" not in k:
        pass
# preserve other env keys
other_lines = []
for k, v in sorted(existing.items()):
    if k not in new_vars and not k.startswith("BRMSTE_QUANTUM") and k != "BRMSTE_CURSOR_QUANTUM_ROUTING":
        other_lines.append(f"{k}={v}")
out_path.parent.mkdir(parents=True, exist_ok=True)
body = "\n".join(lines + other_lines + [f"{k}={v}" for k, v in sorted(new_vars.items())])
# dedupe: read all, merge, write
all_kv = dict(existing)
all_kv.update(new_vars)
final = ["# BRMSTE Fort Knox — never commit"]
for k in sorted(all_kv.keys()):
    final.append(f"{k}={all_kv[k]}")
out_path.write_text("\n".join(final) + "\n", encoding="utf-8")
print(f"quantum_connect_ok vars={len(new_vars)} out={out_path}")
PY
