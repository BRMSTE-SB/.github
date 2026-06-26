#!/usr/bin/env bash
# Companies House filing checklist — generic partner wrapper
# Usage: bash scripts/file-companies-house-partner.sh <target> [--mark-filed|--api-profile]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
TARGET="${1:?target required}"
shift || true

FILING="$(python3 - <<'PY' "$ROOT/data/companies-house-api-config.json" "$TARGET"
import json, pathlib, sys
cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
target = cfg["targets"][sys.argv[2]]
print(target["filing_register"])
PY
)"

API_SCRIPT="$ROOT/scripts/file-companies-house-partner-api.sh"

if [[ "${1:-}" == "--api-profile" ]]; then
  exec bash "$API_SCRIPT" "$TARGET" profile
fi

if [[ -f "$ENV_FILE" ]] && [[ -n "${COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN:-}" || -n "${COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN:-}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  echo "==> Fort Knox OAuth detected — filing via GOV.UK Companies House API ($TARGET)"
  exec bash "$API_SCRIPT" "$TARGET" file --mark-filed
fi

MARK_FILED=false
if [[ "${1:-}" == "--mark-filed" ]]; then
  MARK_FILED=true
fi

python3 - <<'PY' "$ROOT/$FILING" "$MARK_FILED" "$TARGET" "$API_SCRIPT"
import json, pathlib, sys
from datetime import datetime, timezone

filing_path = pathlib.Path(sys.argv[1])
mark_filed = sys.argv[2].lower() == "true"
target_id = sys.argv[3]
api_script = sys.argv[4]
data = json.loads(filing_path.read_text())
target = data["filing"]["target"]
beneficiary = data["filing"]["beneficiary"]
forms = data.get("filing", {}).get("forms", [])
auth_env = data.get("filing", {}).get("webfiling", {}).get("auth_code_env", "COMPANIES_HOUSE_AUTH_CODE")

print(f"==> BRMSTE Companies House filing · {target_id} · equity beneficiary")
print(f"    Target:      {target['legal_name']} · CH {target['companies_house']}")
print(f"    Beneficiary: {beneficiary['legal_name']} · CH {beneficiary['companies_house']}")
print(f"    Operator:    {beneficiary['operator']}")
print(f"    Equity:      {data['filing'].get('declared_interest', {}).get('ownership_pct', 100)}%")
print("")
print("GOV.UK API:")
print(f"  bash {api_script} {target_id} oauth-url")
print(f"  bash {api_script} {target_id} file --mark-filed")
print("  Docs: docs/COMPANIES-HOUSE-API.md")
print("")
print("Manual WebFiling:")
print("  1. https://www.gov.uk/file-your-company-accounts-online")
print(f"  2. {target['companies_house_url']}")
print(f"  3. Load {auth_env} from Fort Knox")
for i, form in enumerate(forms, 1):
    print(f"  {i + 3}. {form['code']} — {form['title']}")
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
    print(f"After WebFiling completes: bash scripts/file-companies-house-partner.sh {target_id} --mark-filed")
PY
