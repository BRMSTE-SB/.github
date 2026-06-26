#!/usr/bin/env bash
# Companies House filing — UBS AG · GOV.UK API or checklist
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILING="$ROOT/data/companies-house-ubs-filing.json"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
API_SCRIPT="$ROOT/scripts/file-companies-house-ubs-api.sh"

if [[ "${1:-}" == "--api-profile" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
  fi
  exec bash "$API_SCRIPT" profile
fi

if [[ -f "$ENV_FILE" ]] && [[ -n "${COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN:-}" || -n "${COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN:-}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  echo "==> Fort Knox OAuth detected — filing UBS AG via GOV.UK Companies House API"
  exec bash "$API_SCRIPT" file --mark-filed
fi

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

print("==> BRMSTE Companies House filing · UBS AG equity beneficiary")
print(f"    Target:      {target['legal_name']} · CH {target['companies_house']}")
print(f"    Beneficiary: {beneficiary['legal_name']} · CH {beneficiary['companies_house']}")
print(f"    Operator:    {beneficiary['operator']}")
print(f"    Equity:      100% · UBS Group AG")
print("")
print("GOV.UK API:")
print("  bash scripts/file-companies-house-ubs-api.sh oauth-url")
print("  bash scripts/file-companies-house-ubs-api.sh file --mark-filed")
print("  Docs: docs/COMPANIES-HOUSE-API.md")
print("")
print("Manual WebFiling steps (operator):")
print("  1. Sign in: https://www.gov.uk/file-your-company-accounts-online")
print(f"  2. Open company: {target['companies_house_url']}")
print("  3. Load COMPANIES_HOUSE_UBS_AUTH_CODE from Fort Knox")
for i, f in enumerate(forms, 1):
    print(f"  {i + 3}. File {f['code']} — {f['title']}")
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
    print("  bash scripts/file-companies-house-ubs.sh --mark-filed")
PY
