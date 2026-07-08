#!/usr/bin/env bash
# Full HTTPS sweep — HSTS + redirect on BRMSTE primary surfaces.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT:-$ROOT/data/edge/https-verify-latest.json}"
HSTS_EXPECT="max-age=63072000"

HOSTS=(
  "brmste.com|/health"
  "brmste.com|/substrate/https-tuned.json"
  "brmste.com|/substrate/starmind/mystery.json"
  "brmste.com|/brand"
  "brmste.ai|/mine/stats"
  "brmste.ai|/substrate/capabilities"
  "api.brmste.com|/chain/health"
)

fail_count=0

python3 - "$OUT" "$HSTS_EXPECT" "${HOSTS[@]}" << 'PY'
import json, sys, urllib.request, ssl
from datetime import datetime, timezone

out_path, hsts_expect = sys.argv[1], sys.argv[2]
hosts = [h.split("|", 1) for h in sys.argv[3:]]

results = []
for host, path in hosts:
    https_url = f"https://{host}{path}"
    http_url = f"http://{host}{path}"
    entry = {"host": host, "path": path, "https_status": 0, "hsts": None, "http_redirect": None, "ok": False}

    try:
        req = urllib.request.Request(https_url, headers={"Accept": "*/*", "User-Agent": "BRMSTE-HTTPS-Verify/1"})
        with urllib.request.urlopen(req, timeout=20) as r:
            entry["https_status"] = r.status
            hsts = r.headers.get("Strict-Transport-Security") or r.headers.get("strict-transport-security")
            entry["hsts"] = hsts
            entry["hsts_ok"] = bool(hsts and hsts_expect.split("=")[0] in hsts and "63072000" in hsts)
    except Exception as e:
        entry["https_error"] = str(e)[:200]

    try:
        req = urllib.request.Request(http_url, headers={"User-Agent": "BRMSTE-HTTPS-Verify/1"}, method="GET")
        with urllib.request.urlopen(req, timeout=15) as r:
            final = r.url
            entry["http_redirect"] = final.startswith("https://")
    except urllib.error.HTTPError as e:
        entry["http_redirect"] = e.code in (301, 302, 307, 308)
    except Exception:
        entry["http_redirect"] = None

    entry["ok"] = entry.get("https_status") == 200 and entry.get("hsts_ok", False)
    if not entry["ok"]:
        pass  # counted below
    results.append(entry)

ok_count = sum(1 for r in results if r["ok"])
report = {
    "schema": "brmste-https-verify/v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "hsts_expected": hsts_expect,
    "results": results,
    "ok_count": ok_count,
    "total": len(results),
}
with open(out_path, "w") as f:
    json.dump(report, f, indent=2)

print(f"HTTPS verify: {ok_count}/{len(results)} fully tuned → {out_path}")
for r in results:
    mark = "OK" if r["ok"] else "FAIL"
    print(f"  [{mark}] https://{r['host']}{r['path']} status={r['https_status']} hsts={bool(r.get('hsts'))}")
sys.exit(0 if ok_count == len(results) else 1)
PY
