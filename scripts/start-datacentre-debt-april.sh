#!/usr/bin/env bash
# Run on THE KOHINOOR MAC — start datacentre debt collection since April 2026.
set -euo pipefail

EDGE="${BRMSTE_EDGE:-https://brmste.com}"
REPO_RAW="${BRMSTE_REPO_RAW:-https://raw.githubusercontent.com/BRMSTE-SB/.github/main}"
LOCAL_LEDGER="${HOME}/.brmste/datacentre-debt-april.json"
INVOICE_DIR="${HOME}/.brmste/hetzner-invoices"
MANIFEST="$INVOICE_DIR/manifest.json"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_MANIFEST="$ROOT/data/hetzner/datacentre-debt-april.json"

mkdir -p "$INVOICE_DIR"

echo "BRMSTE datacentre debt · since April 2026"
echo "Edge: $EDGE"
echo "Local ledger: $LOCAL_LEDGER"
echo

if [[ -f "$LOCAL_MANIFEST" ]]; then
  cp "$LOCAL_MANIFEST" "/tmp/datacentre-debt-april.json"
else
  curl -fsSL "$REPO_RAW/data/hetzner/datacentre-debt-april.json" -o "/tmp/datacentre-debt-april.json"
fi
curl -fsSL "$EDGE/api/rails/live-pay/status" -o "/tmp/live-pay-status.json" 2>/dev/null || true
curl -fsSL "$EDGE/api/rails/bizstrat/sales/status" -o "/tmp/sales-status.json" 2>/dev/null || true

python3 - <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path

manifest_path = Path("/tmp/datacentre-debt-april.json")
live_pay = Path("/tmp/live-pay-status.json")
sales = Path("/tmp/sales-status.json")
local = Path.home() / ".brmste" / "datacentre-debt-april.json"
invoice_dir = Path.home() / ".brmste" / "hetzner-invoices"

manifest = json.loads(manifest_path.read_text())
record = {
    "schema": "brmste-datacentre-debt-local/v1",
    "started_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "accrual_from": manifest["accrual"]["effective_from"],
    "months": manifest["accrual"]["months_open"],
    "status": "collection_started",
    "invoices_dropped": sorted(p.name for p in invoice_dir.glob("*") if p.is_file() and p.name != "manifest.json"),
    "live_pay_status": json.loads(live_pay.read_text()).get("status") if live_pay.exists() else "unreachable",
    "sales_completed_gbp": json.loads(sales.read_text()).get("totals", {}).get("total_gbp", 0) if sales.exists() else None,
    "next": [
        "Tag each Apr–Jun Hetzner + Cloudflare invoice with month and amount_gbp",
        "POST /api/rails/bizstrat/paypal/orders with source=datacentre for each period",
        "Capture on buyer approval · verify /api/rails/bizstrat/sales/status?source=datacentre",
        "npm run hydrate:datacentre-debt-april in Fort Knox after edge deploy",
    ],
}
local.parent.mkdir(parents=True, exist_ok=True)
local.write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record, indent=2))
PY

echo
echo "Done. Drop invoices into: $INVOICE_DIR"
echo "Fort Knox: npm run start:datacentre-debt-april && npm run hydrate:datacentre-debt-april"
