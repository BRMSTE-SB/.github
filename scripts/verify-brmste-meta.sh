#!/usr/bin/env bash
# Verify BRMSTE META settlement manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/brmste-meta.json"

fail() { echo "BRMSTE-META FAIL: $*" >&2; exit 1; }
ok() { echo "BRMSTE-META OK: $*"; }

[[ -f "$ROOT/BRMSTE-META.md" ]] || fail "missing BRMSTE-META.md"
[[ -f "$MANIFEST" ]] || fail "missing manifest"

python3 - <<'PY' "$MANIFEST"
import json, sys
data = json.load(open(sys.argv[1]))
required = {
    "schema", "meta", "environment", "settlement", "blockchain",
    "operator_identity", "disambiguation"
}
missing = required - data.keys()
if missing:
    raise SystemExit(f"missing keys: {sorted(missing)}")
if data["environment"] != "real":
    raise SystemExit("environment must be real")
if data["settlement"]["asset"] != "USDC":
    raise SystemExit("settlement asset must be USDC")
if data["settlement"]["rail"] != "coinbase":
    raise SystemExit("settlement rail must be coinbase")
if data["blockchain"]["canonical_domain"] != "brmste.com":
    raise SystemExit("blockchain domain must be brmste.com")
if data["operator_identity"]["email"].lower() != "sb@brmste.ai":
    raise SystemExit("operator email must be sb@brmste.ai")
expected = "REAL BRMSTE USDC COINBASE OF BRMSTE BLOCKCHAIN.COM SB@BRMSTE.AI"
if data["meta"] != expected:
    raise SystemExit(f"meta string mismatch: {data['meta']!r}")
PY

grep -q 'sb@brmste.ai' "$ROOT/BRMSTE-META.md" || fail "BRMSTE-META.md must cite sb@brmste.ai"
grep -q 'Meta Platforms' "$ROOT/META-FULL-STOP.md" || fail "META-FULL-STOP must disambiguate Meta Platforms"

ok "META = REAL BRMSTE USDC COINBASE OF BRMSTE BLOCKCHAIN.COM SB@BRMSTE.AI"
