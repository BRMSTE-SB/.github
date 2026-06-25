#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/data/hetzner/datacentre-debt-april.json"

[[ -f "$MANIFEST" ]] || { echo "missing $MANIFEST"; exit 1; }

python3 - <<PY
import json
from pathlib import Path

m = json.loads(Path("$MANIFEST").read_text())
required = [
    "schema", "accrual", "lane_split", "datacentres", "tariff",
    "collection", "ledger", "operator_now",
]
missing = [k for k in required if k not in m]
if missing:
    raise SystemExit(f"missing keys: {missing}")
if m["accrual"]["effective_from"] != "2026-04-01T00:00:00Z":
    raise SystemExit("accrual must start 2026-04-01")
if m["collection"]["checkout_body"]["source"] != "datacentre":
    raise SystemExit("checkout source must be datacentre")
print("verify-datacentre-debt-april: ok")
PY
