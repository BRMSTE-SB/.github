#!/usr/bin/env bash
# Inventory Cloudflare edge APIs + IBM BRM API — writes data/edge/cloudflare-api-catalog.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/data/edge/cloudflare-api-catalog.json"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
BRM_API="${BRM_API:-https://brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud}"

mkdir -p "$(dirname "$OUT")"

PROBE_PATHS=(
  "brmste.ai|/mine/stats"
  "brmste.ai|/substrate/capabilities"
  "brmste.ai|/substrate/quantum/status.json"
  "brmste.ai|/quantum/health"
  "brmste.ai|/quantum/backends"
  "brmste.ai|/quantum/fleet"
  "brmste.com|/health"
  "brmste.com|/substrate/quantum/status.json"
  "brmste.com|/quantum/backends"
  "api.brmste.com|/chain/health"
  "brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud|/health"
  "brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud|/status"
  "brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud|/api/watsonx/models"
  "brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud|/api/quantum/backends"
  "brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud|/api/grok/models"
)

python3 - "$OUT" "$CF_ACCOUNT_ID" "$BRM_API" "${PROBE_PATHS[@]}" << 'PY'
import json, sys, urllib.request, ssl
from datetime import datetime, timezone

out_path, account_id, brm_api = sys.argv[1], sys.argv[2], sys.argv[3]
probes = [p.split("|", 1) for p in sys.argv[4:]]

results = []
live = 0
for host, path in probes:
    url = f"https://{host}{path}"
    status = 0
    sample = ""
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "BRMSTE-CF-Catalog/1"})
        with urllib.request.urlopen(req, timeout=15) as r:
            status = r.status
            sample = r.read(200).decode("utf-8", errors="replace")
            if status == 200:
                live += 1
    except urllib.error.HTTPError as e:
        status = e.code
        sample = f"HTTP Error {e.code}: {e.reason}"
    except Exception as e:
        status = 0
        sample = str(e)[:120]
    results.append({"host": host, "path": path, "status": status, "sample": sample[:200]})

catalog = {
    "schema": "brmste-cloudflare-api-catalog/v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "account_id": account_id,
    "operator": "Shravan Bansal",
    "entity": "BRMSTE LTD",
    "brm_api": brm_api,
    "quantum_gi_worker": "brmste-quantum-gi",
    "probe_results": results,
    "live_count": live,
    "missing_count": len(results) - live,
}
with open(out_path, "w") as f:
    json.dump(catalog, f, indent=2)
print(f"Wrote {out_path} — {live}/{len(results)} live")
PY

echo "Catalog: $OUT"
