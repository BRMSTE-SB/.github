#!/usr/bin/env bash
# Verify Metrallium trace manifest structure before AD LEADING listing filing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/substrate/metrallium-trace-opportunities.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: missing $MANIFEST"
  exit 1
fi

python3 - "$MANIFEST" << 'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    d = json.load(f)

required = [
    "schema", "status", "prospect", "listing_lane", "survey_pack_index",
    "opportunity_matrix", "pre_listing_checklist", "honesty"
]
missing = [k for k in required if k not in d]
if missing:
    raise SystemExit(f"FAIL: missing keys: {missing}")

if d.get("listing_lane", {}).get("filing_entity", {}).get("companies_house") != "13817062":
    raise SystemExit("FAIL: filing_entity must be AD LEADING LIMITED (13817062)")

if d.get("status") != "pre_listing_trace · operator_review_required":
    raise SystemExit(f"WARN: unexpected status: {d.get('status')}")

sites = d.get("survey_pack_index", [])
if len(sites) < 7:
    raise SystemExit(f"FAIL: expected >=7 survey traces, got {len(sites)}")

for s in sites:
    if not s.get("trace_id", "").startswith("BRMSTE-TRACE-METRALLIUM-"):
        raise SystemExit(f"FAIL: bad trace_id: {s}")

checklist = d.get("pre_listing_checklist", {})
if checklist.get("substrate_edge_publish") is True:
    raise SystemExit("FAIL: substrate_edge_publish must be false until operator files listing")

print(f"OK: {d['schema']} · {len(sites)} survey traces · status={d['status']}")
print(f"OK: filing_entity=AD LEADING LIMITED · {d['listing_lane']['filing_entity']['companies_house']}")
print(f"OK: opportunity clusters={len(d.get('opportunity_matrix', []))}")
PY

echo "Metrallium pre-listing trace manifest verified."
