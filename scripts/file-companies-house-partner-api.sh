#!/usr/bin/env bash
# GOV.UK Companies House API — generic partner filing wrapper
# Usage: bash scripts/file-companies-house-partner-api.sh <target> [profile|oauth-url|exchange|file]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
TARGET="${1:?target required (harrods|ubs|american-express|airbus|blackstone|siemens|mercedes|bugatti)}"
shift || true

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

CMD="${1:-help}"
shift || true

case "$CMD" in
  profile|oauth-url|exchange|file)
    exec python3 "$ROOT/scripts/companies_house_api.py" --target "$TARGET" "$CMD" "$@"
    ;;
  help|*)
    python3 - <<'PY' "$ROOT/data/companies-house-api-config.json" "$TARGET"
import json, pathlib, sys
cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
target = cfg["targets"][sys.argv[2]]
print(f"GOV.UK Companies House API · {target['legal_name']} · CH {target['company_number']}")
print("")
print("Commands: profile · oauth-url · exchange · file")
print(f"Auth code env: {target.get('auth_code_env', 'COMPANIES_HOUSE_AUTH_CODE')}")
print(f"Register: {target.get('filing_register')}")
print("Docs: docs/COMPANIES-HOUSE-API.md")
PY
    ;;
esac
