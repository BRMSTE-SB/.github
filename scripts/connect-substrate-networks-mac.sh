#!/usr/bin/env bash
# Connect BRMSTE substrate networks · multichain Fort Knox markers — NEVER commit.
#
# Usage:
#   bash scripts/connect-substrate-networks-mac.sh
#   bash scripts/connect-substrate-networks-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LANE="$ROOT/data/substrate-networks-lane.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
BASE="${BRMSTE_MAC_KEYS_BASE:-/Users/sachindabas/Desktop/API keys - Copy}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$LANE" ]]; then
  echo "ERROR: missing substrate-networks-lane.json" >&2
  exit 1
fi

echo "==> BRMSTE substrate networks connect"
echo "    Keys base: $BASE"
echo "    Fort Knox: $OUT"

python3 - <<'PY' "$LANE" "$BASE" "$OUT" "$VERIFY_ONLY"
import json, pathlib, re, sys

lane_path, base, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    sys.argv[4].lower() == "true",
)

lane = json.loads(lane_path.read_text())

file_map = {
    "POLYMARKET_API_KEY": ("Polymarket", "POLYMARKET-API-KEY.txt"),
    "POLYGON_RPC_URL": ("Polygon", "POLYGON-RPC-URL.txt"),
    "SOLANA_RPC_URL": ("Solana", "SOLANA-RPC-URL.txt"),
    "ETHEREUM_RPC_URL": ("Ethereum", "ETHEREUM-RPC-URL.txt"),
    "COSMOS_ATOM_RPC_URL": ("Cosmos", "COSMOS-ATOM-RPC-URL.txt"),
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

new_vars = {
    "BRMSTE_SUBSTRATE_NETWORKS_CONNECTED": "true",
    "BRMSTE_LIGHTNING_URL": "https://brmste.mempool.space/lightning",
    "BRMSTE_ANTHROPIC_GLASSWING_URL": "https://www.anthropic.com/glasswing",
    "BRMSTE_VOYAGER_II_LIVE": "true",
    "BRMSTE_PIONEER_ATOM": "true",
    "BRMSTE_STEALTH_ONCHAIN_90": "true",
}
for env_var, (subdir, fname) in file_map.items():
    val = read_key(base / subdir / fname)
    if val:
        new_vars[env_var] = val

if verify_only:
    ok = existing.get("BRMSTE_SUBSTRATE_NETWORKS_CONNECTED") == "true"
    if not ok:
        print("verify_fail: BRMSTE_SUBSTRATE_NETWORKS_CONNECTED not true")
        sys.exit(1)
    print("verify_ok substrate_networks connected")
    sys.exit(0)

merged = dict(existing)
merged.update(new_vars)
out_path.parent.mkdir(parents=True, exist_ok=True)
lines = ["# BRMSTE Fort Knox — never commit"]
for k in sorted(merged.keys()):
    lines.append(f"{k}={merged[k]}")
out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"substrate_networks_ok vars_set={len(new_vars)}")
PY
