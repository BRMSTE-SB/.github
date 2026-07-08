#!/usr/bin/env bash
# Verify all key BRMSTE endpoints return HTTP 200.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT:-$ROOT/data/edge/verify-200-latest.json}"

TARGETS=(
  "brmste.com|/health"
  "brmste.com|/brand"
  "brmste.com|/starmind"
  "brmste.com|/substrate/starmind/mystery.json"
  "brmste.com|/substrate/https-tuned.json"
  "brmste.ai|/health"
  "brmste.ai|/quantum/health"
  "brmste.ai|/quantum/backends"
  "brmste.ai|/substrate/quantum/status.json"
  "brmste.ai|/mine/stats"
  "api.brmste.com|/chain/health"
)

python3 - "$OUT" "${TARGETS[@]}" << 'PY'
import json, sys, urllib.request
from datetime import datetime, timezone

out_path = sys.argv[1]
targets = [t.split("|", 1) for t in sys.argv[2:]]

results = []
ok = 0
for host, path in targets:
    url = f"https://{host}{path}"
    status = 0
    err = None
    try:
        req = urllib.request.Request(url, headers={"Accept": "*/*", "User-Agent": "BRMSTE-Verify-200/1"})
        with urllib.request.urlopen(req, timeout=25) as r:
            status = r.status
    except urllib.error.HTTPError as e:
        status = e.code
        err = str(e.reason)[:120]
    except Exception as e:
        err = str(e)[:120]
    entry = {"host": host, "path": path, "url": url, "status": status, "ok": status == 200}
    if err:
        entry["error"] = err
    if status == 200:
        ok += 1
    results.append(entry)

report = {
    "schema": "brmste-verify-200/v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "ok_count": ok,
    "total": len(results),
    "all_200": ok == len(results),
    "results": results,
}
with open(out_path, "w") as f:
    json.dump(report, f, indent=2)

print(f"Verify 200: {ok}/{len(results)} → {out_path}")
for r in results:
    mark = "OK" if r["ok"] else "FAIL"
    print(f"  [{mark}] {r['status']} https://{r['host']}{r['path']}")
sys.exit(0 if ok == len(results) else 1)
PY
