#!/usr/bin/env bash
# Record BRMSTE quantum compute usage to local Fort Knox ledger — NEVER commit ledger file.
#
# Usage:
#   bash scripts/record-quantum-usage-mac.sh --unit hybrid_job --quantity 1 --customer id --job job-id
#   bash scripts/record-quantum-usage-mac.sh --summary
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
METER="$ROOT/data/quantum-compute-metering-register.json"
QUANTUM_DIR="${BRMSTE_QUANTUM_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Quantum}"
LEDGER="${BRMSTE_QUANTUM_LEDGER:-$QUANTUM_DIR/QUANTUM-USAGE-LEDGER.json}"

UNIT=""
QUANTITY=""
CUSTOMER=""
JOB=""
SUMMARY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unit) UNIT="$2"; shift 2 ;;
    --quantity) QUANTITY="$2"; shift 2 ;;
    --customer) CUSTOMER="$2"; shift 2 ;;
    --job) JOB="$2"; shift 2 ;;
    --summary) SUMMARY=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

python3 - <<'PY' "$METER" "$LEDGER" "$UNIT" "$QUANTITY" "$CUSTOMER" "$JOB" "$SUMMARY"
import json, pathlib, sys, uuid
from datetime import datetime, timezone

meter_path = pathlib.Path(sys.argv[1])
ledger_path = pathlib.Path(sys.argv[2])
unit, quantity, customer, job, summary = sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7].lower() == "true"

meter = json.loads(meter_path.read_text())
valid_units = {u["id"] for u in meter.get("units", [])}

if summary:
    if not ledger_path.is_file():
        print("ledger_empty path=" + str(ledger_path))
        sys.exit(0)
    data = json.loads(ledger_path.read_text())
    events = data.get("events", [])
    totals = {}
    for e in events:
        uid = e.get("unit_id", "?")
        totals[uid] = totals.get(uid, 0) + float(e.get("quantity", 0))
    print("quantum_usage_summary events=" + str(len(events)))
    for uid, q in sorted(totals.items()):
        print(f"  {uid}={q}")
    sys.exit(0)

if not unit or not quantity:
    print("ERROR: --unit and --quantity required (or --summary)", file=sys.stderr)
    sys.exit(1)
if unit not in valid_units:
    print(f"ERROR: invalid unit {unit} valid={sorted(valid_units)}", file=sys.stderr)
    sys.exit(1)

ledger_path.parent.mkdir(parents=True, exist_ok=True)
if ledger_path.is_file():
    data = json.loads(ledger_path.read_text())
else:
    data = {
        "schema": "brmste-quantum-usage-ledger/v1",
        "operator": "Dr. Shravan Bansal · BRMSTE LTD",
        "events": [],
    }

event = {
    "event_id": str(uuid.uuid4()),
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "unit_id": unit,
    "quantity": float(quantity),
    "customer_id": customer or "anonymous",
    "job_id": job or "",
    "substrate_node": "brmste_quantum_edge",
    "payment_status": "pending",
}
data.setdefault("events", []).append(event)
ledger_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(f"recorded event_id={event['event_id']} unit={unit} quantity={quantity}")
PY
