#!/usr/bin/env bash
# Verify BRMSTE eToro portfolio manifests (weights, schema, holdings).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${PORTFOLIO_DIR:-$ROOT/data/portfolios}"

fail() { echo "PORTFOLIO VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "PORTFOLIO VERIFY OK: $*"; }

[[ -d "$DIR" ]] || fail "portfolio directory missing: $DIR"

shopt -s nullglob
files=("$DIR"/*.json)
[[ ${#files[@]} -gt 0 ]] || fail "no portfolio manifests in $DIR"

python3 - <<'PY' "${files[@]}"
import json, sys

required_etoro = {
    "environment", "leverage", "orderType", "transaction",
    "orderCurrency", "settlementType", "cashTargetPct", "investedTargetPct",
}

def check_holdings(path, holdings):
    if not holdings:
        raise SystemExit(f"{path}: holdings empty")
    weight_sum = sum(float(h["weight"]) for h in holdings)
    if abs(weight_sum - 1.0) > 0.0001:
        raise SystemExit(f"{path}: weights sum to {weight_sum}, expected 1.0")
    symbols = [h.get("symbol", "") for h in holdings]
    if len(symbols) != len(set(symbols)):
        raise SystemExit(f"{path}: duplicate symbols")
    for h in holdings:
        for key in ("symbol", "name", "weight"):
            if key not in h:
                raise SystemExit(f"{path}: holding missing {key}")
        w = float(h["weight"])
        if w <= 0 or w > 1:
            raise SystemExit(f"{path}: invalid weight {w} for {h['symbol']}")

for path in sys.argv[1:]:
    data = json.loads(open(path).read())
    schema = data.get("schema", "")
    etoro = data["etoro"]
    missing = required_etoro - etoro.keys()
    if missing:
        raise SystemExit(f"{path}: etoro missing {sorted(missing)}")
    if float(etoro["investedTargetPct"]) != 1:
        raise SystemExit(f"{path}: investedTargetPct must be 1 for 100% portfolio")

    if schema == "brmste-etoro-portfolio-bundle/v1":
        for key in ("id", "name", "description", "sleeves", "execution", "capitalSplit"):
            if key not in data:
                raise SystemExit(f"{path}: bundle missing {key}")
        if data["capitalSplit"] != "equal":
            raise SystemExit(f"{path}: only equal capitalSplit is supported")
        if not data["sleeves"]:
            raise SystemExit(f"{path}: sleeves empty")
        for sleeve in data["sleeves"]:
            for key in ("id", "label", "holdings"):
                if key not in sleeve:
                    raise SystemExit(f"{path}: sleeve missing {key}")
            check_holdings(f"{path}::{sleeve['id']}", sleeve["holdings"])
    elif schema == "brmste-etoro-portfolio/v1":
        for key in ("id", "name", "description", "holdings", "execution"):
            if key not in data:
                raise SystemExit(f"{path}: missing {key}")
        check_holdings(path, data["holdings"])
    else:
        raise SystemExit(f"{path}: unsupported schema {schema}")

    print(path)

print(len(sys.argv[1:]))
PY

ok "${#files[@]} manifest(s) in $DIR"
