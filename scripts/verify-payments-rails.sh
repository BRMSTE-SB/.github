#!/usr/bin/env bash
# Verify the BRMSTE payment-rails manifests (openUSD/Coinbase, LNbits, edge ads).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${PAYMENTS_DIR:-$ROOT/data/payments}"

fail() { echo "PAYMENTS VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "PAYMENTS VERIFY OK: $*"; }

for f in rails.json coinbase-usdc.json lnbits.json edge-compute-ads.json; do
  [[ -f "$DIR/$f" ]] || fail "manifest missing: $DIR/$f"
done

python3 - "$DIR" <<'PY'
import json, os, sys

d = sys.argv[1]
def load(name):
    return json.loads(open(os.path.join(d, name)).read())

rails = load("rails.json")
if rails.get("schema") != "brmste-payments-rails/v1":
    raise SystemExit(f"rails.json: unexpected schema {rails.get('schema')!r}")
if rails.get("companies_house") != "15310393":
    raise SystemExit("rails.json: companies_house must be 15310393")
rail_ids = [r["id"] for r in rails["rails"]]
for want in ("openusd", "coinbase", "lnbits"):
    if want not in rail_ids:
        raise SystemExit(f"rails.json: missing rail {want}")
if rails["counts"]["rails"] != len(rails["rails"]):
    raise SystemExit("rails.json: counts.rails mismatch")
print(f"rails ok: {', '.join(rail_ids)}")

cb = load("coinbase-usdc.json")
if cb.get("schema") != "brmste-openusd-coinbase/v1":
    raise SystemExit("coinbase-usdc.json: bad schema")
polygon = next((n for n in cb["networks"] if n["id"] == "polygon"), None)
if not polygon or polygon["usdc_token"] != "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359":
    raise SystemExit("coinbase-usdc.json: polygon USDC token mismatch")
if any(k in json.dumps(cb).lower() for k in ("privatekey", "secret_value", "api_key_secret_value")):
    raise SystemExit("coinbase-usdc.json: must not embed secret values")
print(f"openusd/coinbase ok: {len(cb['networks'])} network(s)")

ln = load("lnbits.json")
if ln.get("schema") != "brmste-lnbits-invoices/v1":
    raise SystemExit("lnbits.json: bad schema")
if ln.get("state") != "armed":
    raise SystemExit("lnbits.json: state must be 'armed'")
if ln["api"]["invoice_key_env"] != "LNBITS_INVOICE_KEY":
    raise SystemExit("lnbits.json: invoice_key_env must be LNBITS_INVOICE_KEY")
print("lnbits ok: invoices armed")

ads = load("edge-compute-ads.json")
if ads.get("schema") != "brmste-edge-compute-ads/v1":
    raise SystemExit("edge-compute-ads.json: bad schema")
if ads["burn_earn"]["principle"] != "token_burn_equals_token_earned":
    raise SystemExit("edge-compute-ads.json: burn_earn principle mismatch")
if ads["counts"]["creatives"] != len(ads["creatives"]):
    raise SystemExit("edge-compute-ads.json: counts.creatives mismatch")
print(f"edge-ads ok: {len(ads['creatives'])} creative(s), burn=earn 1:1")
PY

ok "payment rails ${DIR}"
