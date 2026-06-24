#!/usr/bin/env bash
# Hydrate BRMSTE PayPal · Moonshot · Revolut rails from operator UTXOs — Fort Knox only · NEVER commit.
#
# Default UTXO folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/UTXOs/OPERATOR-UTXOS.json
#
# Usage on Mac:
#   bash scripts/hydrate-utxo-rails-mac.sh
#   BRMSTE_UTXO_DIR="/path/to/UTXOs" bash scripts/hydrate-utxo-rails-mac.sh
#   bash scripts/hydrate-utxo-rails-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HYDRATION="$ROOT/data/utxo-ledger-hydration.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

UTXO_DIR="${1:-${BRMSTE_UTXO_DIR:-/Users/sachindabas/Desktop/API keys - Copy/UTXOs}}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
  UTXO_DIR="${BRMSTE_UTXO_DIR:-/Users/sachindabas/Desktop/API keys - Copy/UTXOs}"
elif [[ "${2:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$HYDRATION" ]]; then
  echo "ERROR: missing utxo hydration register — clone BRMSTE-SB/.github first." >&2
  exit 1
fi

echo "==> BRMSTE UTXO rail hydration · PayPal · Moonshot · Revolut"
echo "    UTXO dir:  $UTXO_DIR"
echo "    Fort Knox: $OUT (never committed)"

python3 - <<'PY' "$HYDRATION" "$UTXO_DIR" "$OUT" "$VERIFY_ONLY" "$ROOT"
import json, pathlib, sys
from datetime import datetime, timezone

hydration_path = pathlib.Path(sys.argv[1])
utxo_dir = pathlib.Path(sys.argv[2])
out_path = pathlib.Path(sys.argv[3])
verify_only = sys.argv[4].lower() == "true"
root = pathlib.Path(sys.argv[5])

hydration = json.loads(hydration_path.read_text())
ledger_cfg = hydration["utxo_ledger"]
utxo_file = utxo_dir / ledger_cfg["mac_file"]

if not utxo_file.is_file():
    print(f"ERROR: UTXO ledger not found: {utxo_file}", file=sys.stderr)
    print("Create OPERATOR-UTXOS.json — see docs/FORT-KNOX-UTXO-HYDRATION.md", file=sys.stderr)
    sys.exit(1)

raw = json.loads(utxo_file.read_text(encoding="utf-8"))
utxos = raw.get("utxos") if isinstance(raw, dict) else raw
if not isinstance(utxos, list) or len(utxos) == 0:
    print("ERROR: UTXO ledger must be a non-empty utxos array", file=sys.stderr)
    sys.exit(1)

for i, u in enumerate(utxos):
    if not isinstance(u, dict):
        print(f"ERROR: utxo[{i}] not an object", file=sys.stderr)
        sys.exit(1)
    if not u.get("txid") or u.get("vout") is None:
        print(f"ERROR: utxo[{i}] missing txid or vout", file=sys.stderr)
        sys.exit(1)

count = len(utxos)
rails = ("paypal", "moonshot", "revolut")

if verify_only:
    if not out_path.is_file():
        print("ERROR: .env.fort-knox missing — run hydrate without --verify-only", file=sys.stderr)
        sys.exit(1)
    env = {}
    for line in out_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip()
    if env.get("BRMSTE_UTXO_HYDRATION_STATUS") != "hydrated":
        print("ERROR: BRMSTE_UTXO_HYDRATION_STATUS not hydrated", file=sys.stderr)
        sys.exit(1)
    for rail in rails:
        key = f"BRMSTE_{rail.upper()}_HYDRATED"
        if env.get(key) != "true":
            print(f"ERROR: {key} not true", file=sys.stderr)
            sys.exit(1)
    print(f"verify_ok utxo_count={env.get('BRMSTE_UTXO_COUNT', '?')} rails=paypal,moonshot,revolut")
    sys.exit(0)

existing_lines = []
if out_path.is_file():
    existing_lines = out_path.read_text(encoding="utf-8", errors="replace").splitlines()

keep = []
skip_prefixes = (
    "BRMSTE_UTXO_HYDRATION_STATUS=",
    "BRMSTE_UTXO_LEDGER_PATH=",
    "BRMSTE_UTXO_COUNT=",
    "BRMSTE_UTXO_HYDRATED_AT=",
    "BRMSTE_PAYPAL_HYDRATED=",
    "BRMSTE_MOONSHOT_HYDRATED=",
    "BRMSTE_REVOLUT_HYDRATED=",
)
for line in existing_lines:
    if any(line.startswith(p) for p in skip_prefixes):
        continue
    keep.append(line)

ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
new_lines = [
    "",
    f"# UTXO hydration · {ts}",
    f"BRMSTE_UTXO_HYDRATION_STATUS=hydrated",
    f"BRMSTE_UTXO_LEDGER_PATH={utxo_file.resolve()}",
    f"BRMSTE_UTXO_COUNT={count}",
    f"BRMSTE_UTXO_HYDRATED_AT={ts}",
    "BRMSTE_PAYPAL_HYDRATED=true",
    "BRMSTE_MOONSHOT_HYDRATED=true",
    "BRMSTE_REVOLUT_HYDRATED=true",
]

out_path.write_text("\n".join(keep + new_lines).strip() + "\n", encoding="utf-8")
print(f"hydrated rails=paypal,moonshot,revolut utxo_count={count}")
print("fort_knox_updated=true (UTXO txids never printed)")
PY

chmod 600 "$OUT" 2>/dev/null || true

echo ""
echo "DONE — verify:"
echo "  set -a && source .env.fort-knox && set +a"
echo "  bash scripts/hydrate-utxo-rails-mac.sh --verify-only"
