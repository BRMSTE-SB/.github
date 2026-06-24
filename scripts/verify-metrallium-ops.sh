#!/usr/bin/env bash
# Verify Metrallium trace, listing, and ops manifests under AD LEADING LIMITED.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACE="$ROOT/data/substrate/metrallium-trace-opportunities.json"
LISTING="$ROOT/data/substrate/metrallium-listing.json"
OPS="$ROOT/data/substrate/metrallium-ops.json"

for f in "$TRACE" "$LISTING" "$OPS"; do
  [[ -f "$f" ]] || { echo "FAIL: missing $f"; exit 1; }
done

python3 - "$TRACE" "$LISTING" "$OPS" << 'PY'
import json, sys

trace_path, listing_path, ops_path = sys.argv[1:4]

with open(trace_path) as f:
    trace = json.load(f)
with open(listing_path) as f:
    listing = json.load(f)
with open(ops_path) as f:
    ops = json.load(f)

CH = "13817062"

def ch(entity):
    return entity.get("companies_house") == CH or entity.get("companies_house") == CH

# Trace
if "ops_live" not in trace.get("status", ""):
    raise SystemExit(f"FAIL: trace status must include ops_live, got {trace.get('status')}")
if not trace.get("acquisition", {}).get("acquired"):
    raise SystemExit("FAIL: trace acquisition.acquired must be true")
if len(trace.get("survey_pack_index", [])) < 7:
    raise SystemExit("FAIL: expected >=7 survey traces")

# Listing
if listing.get("status") != "acquired · listed · ops_live":
    raise SystemExit(f"FAIL: listing status {listing.get('status')}")
acq = listing.get("acquisition", {})
if acq.get("acquiring_entity", {}).get("companies_house") != CH:
    raise SystemExit("FAIL: listing acquirer must be AD LEADING LIMITED")
if not acq.get("acquired"):
    raise SystemExit("FAIL: listing acquisition.acquired must be true")
sites = listing.get("portfolio", {}).get("sites", [])
if len(sites) < 6:
    raise SystemExit(f"FAIL: expected >=6 portfolio sites, got {len(sites)}")

# Ops
if ops.get("status") != "ops_live":
    raise SystemExit(f"FAIL: ops status must be ops_live, got {ops.get('status')}")
if ops.get("owner_entity", {}).get("companies_house") != CH:
    raise SystemExit("FAIL: ops owner must be AD LEADING LIMITED")
site_ops = ops.get("site_ops", [])
active = [s for s in site_ops if s.get("status") == "active"]
if len(active) < 6:
    raise SystemExit(f"FAIL: expected >=6 active site_ops, got {len(active)}")

print(f"OK: trace · {trace['schema']} · {len(trace['survey_pack_index'])} surveys · {trace['status']}")
print(f"OK: listing · {listing['schema']} · {len(sites)} sites · {listing['status']}")
print(f"OK: ops · {ops['schema']} · {len(active)} active sites · {ops['status']}")
print(f"OK: acquirer AD LEADING LIMITED · {CH}")
print(f"OK: listing_id={acq.get('listing_id')}")
PY

echo "Metrallium AD LEADING ops manifests verified."
