#!/usr/bin/env bash
# Companies House filing checklist — HARRODS LIMITED revenue beneficiary · BRMSTE LTD
# Auth codes stay in Fort Knox (.env.fort-knox) — never commit.
#
# Usage:
#   bash scripts/file-companies-house-harrods.sh
#   bash scripts/file-companies-house-harrods.sh --mark-filed
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILING="$ROOT/data/companies-house-harrods-filing.json"

if [[ ! -f "$FILING" ]]; then
  echo "ERROR: missing $FILING" >&2
  exit 1
fi

MARK_FILED=false
if [[ "${1:-}" == "--mark-filed" ]]; then
  MARK_FILED=true
fi

python3 - <<'PY' "$FILING" "$MARK_FILED"
import json, pathlib, sys
from datetime import datetime, timezone

filing_path = pathlib.Path(sys.argv[1])
mark_filed = sys.argv[2].lower() == "true"
data = json.loads(filing_path.read_text())

target = data["filing"]["target"]
beneficiary = data["filing"]["beneficiary"]
forms = data["filing"].get("forms", [])

print("==> BRMSTE Companies House filing · Harrods revenue beneficiary")
print(f"    Target:     {target['legal_name']} · CH {target['companies_house']}")
print(f"    Beneficiary: {beneficiary['legal_name']} · CH {beneficiary['companies_house']}")
print(f"    Operator:   {beneficiary['operator']}")
print(f"    Revenue:    100% → BRMSTE PayPal")
print("")
print("WebFiling steps (operator):")
print("  1. Sign in: https://www.gov.uk/file-your-company-accounts-online")
print(f"  2. Open company: {target['companies_house_url']}")
print("  3. Load COMPANIES_HOUSE_AUTH_CODE from Fort Knox:")
print("       set -a && source .env.fort-knox && set +a")
for i, f in enumerate(forms, 1):
    print(f"  {i + 3}. File {f['code']} — {f['title']}")
    print(f"       Purpose: {f['purpose']}")
print("")
print(f"Register status: {data['filing'].get('status', 'unknown')}")

if mark_filed:
    data["filing"]["status"] = "filed"
    data["status"] = "filed"
    data["filing"]["filed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    filing_path.write_text(json.dumps(data, indent=2) + "\n")
    print("MARKED filed in register.")
else:
    print("")
    print("After WebFiling completes, run:")
    print("  bash scripts/file-companies-house-harrods.sh --mark-filed")
PY

echo ""
echo "Next: bash scripts/connect-harrods-paypal-mac.sh"
