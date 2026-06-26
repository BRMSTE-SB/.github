#!/usr/bin/env bash
# Verify BRMSTE three-crypto consolidation — only RE-TYRE, BRMSTE, LEADING.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/brmste-three-cryptos.json"

fail() { echo "BRMSTE-THREE-CRYPTOS FAIL: $*" >&2; exit 1; }
ok() { echo "BRMSTE-THREE-CRYPTOS OK: $*"; }

[[ -f "$ROOT/BRMSTE-THREE-CRYPTOS.md" ]] || fail "missing BRMSTE-THREE-CRYPTOS.md"
[[ -f "$MANIFEST" ]] || fail "missing manifest"

python3 - <<'PY' "$MANIFEST"
import json, sys
data = json.load(open(sys.argv[1]))
required = {"schema", "status", "active_cryptos", "stopped_cryptos", "collider_legend"}
missing = required - data.keys()
if missing:
    raise SystemExit(f"missing keys: {sorted(missing)}")
if data["status"] != "consolidated":
    raise SystemExit("status must be consolidated")
labels = [c["label"] for c in data["active_cryptos"]]
expected = ["RE-TYRE", "BRMSTE", "LEADING"]
if labels != expected:
    raise SystemExit(f"active_cryptos labels must be {expected}, got {labels}")
if data["collider_legend"] != "RE-TYRE · BRMSTE · LEADING":
    raise SystemExit("collider_legend mismatch")
stopped = {s["symbol"] for s in data["stopped_cryptos"]}
for sym in ("BTC", "ETH", "SOL", "MATIC"):
    if sym not in stopped:
        raise SystemExit(f"stopped_cryptos must include {sym}")
PY

grep -q 'RE-TYRE' "$ROOT/BRMSTE-THREE-CRYPTOS.md" || fail "policy must cite RE-TYRE"
grep -q 'LEADING' "$ROOT/BRMSTE-THREE-CRYPTOS.md" || fail "policy must cite LEADING"

# Collider SVGs must show three-crypto legend, not legacy tri-chain
for svg in \
  "$ROOT/assets/brmste-gsi-collider-logo.svg" \
  "$ROOT/assets/brmste-carbon-token-collider.svg" \
  "$ROOT/assets/live-edge/brmste-favicon.svg" \
  "$ROOT/assets/live-edge/favicon.svg" \
  "$ROOT/coming-soon/site/public/assets/brmste-gsi-collider-logo.svg"; do
  [[ -f "$svg" ]] || fail "missing collider SVG: $svg"
  grep -q 'RE-TYRE' "$svg" || fail "$svg must show RE-TYRE legend"
  grep -q 'LEADING' "$svg" || fail "$svg must show LEADING legend"
  if grep -qE 'BTC|ETH|SOL' "$svg"; then
    fail "$svg still references stopped BTC/ETH/SOL"
  fi
done

# Governance JSON must not re-introduce legacy tri-chain active rails
for json in \
  "$ROOT/data/hetzner/hydrated-logos.json" \
  "$ROOT/data/hetzner/strategic-russia.json"; do
  [[ -f "$json" ]] || continue
  if grep -qE 'tri_chain|btc_mempool|ethereum-rail|solana-rail|/substrate/bitcoin/|/crypto-stack' "$json"; then
    fail "$json still references stopped crypto rails"
  fi
  if grep -qE '"nodes": \["BTC"|"nodes": \["ETH"|BTC ETH SOL ECONOMY|BTC·ETH·SOL|BTC &#183; ETH' "$json"; then
    fail "$json still lists BTC/ETH/SOL as active nodes"
  fi
done

ok "ONLY RE-TYRE · BRMSTE · LEADING — all other cryptos stopped"
