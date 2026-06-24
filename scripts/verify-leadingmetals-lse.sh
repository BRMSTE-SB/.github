#!/usr/bin/env bash
# Verify AD LEADING LSE lane and green ops manifests — no fake live quotes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LSE="$ROOT/data/substrate/ad-leading-lse.json"
GREEN="$ROOT/data/substrate/leadingmetals-green-ops.json"
PAGE="$ROOT/coming-soon/site/leadingmetals.html"

for f in "$LSE" "$GREEN" "$PAGE"; do
  [[ -f "$f" ]] || { echo "FAIL: missing $f"; exit 1; }
done

python3 - "$LSE" "$GREEN" << 'PY'
import json, sys
lse_path, green_path = sys.argv[1:3]
with open(lse_path) as f:
    lse = json.load(f)
with open(green_path) as f:
    green = json.load(f)

if lse.get("entity", {}).get("companies_house") != "13817062":
    raise SystemExit("FAIL: wrong companies house")
eq = lse.get("tickers", {}).get("equity", {})
if eq.get("symbol") != "ADLD":
    raise SystemExit("FAIL: expected equity symbol ADLD")
if eq.get("last_price") is not None:
    raise SystemExit("FAIL: last_price must be null — no fake quotes")
if "quote_live_true" in eq.get("status", ""):
    raise SystemExit("FAIL: quote must not be live without RNS")
if green.get("lse_tickers", {}).get("quote_live") is not False:
    raise SystemExit("FAIL: green ops quote_live must be false")
if green.get("green_mining", {}).get("sites_active") != 6:
    raise SystemExit("FAIL: expected 6 active mining sites")

print(f"OK: LSE lane · equity={eq['symbol']} · bond={lse['tickers']['green_bond']['symbol']}")
print(f"OK: quote_live=false · operator_attested={lse['lse_lane'].get('operator_attested')}")
print(f"OK: green ops · recycling + {green['green_mining']['sites_active']} mining sites")
PY

echo "AD LEADING LSE + green ops manifests verified."
