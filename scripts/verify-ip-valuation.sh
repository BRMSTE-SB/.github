#!/usr/bin/env bash
# Verify IP valuation manifest · BRMSTE LTD · GB2607860
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/data/ip-valuation.json"
EDGE="$ROOT/coming-soon/site/public/ip-valuation.json"
POLICY="$ROOT/IP-VALUATION.md"

fail() { echo "IP-VALUATION VERIFY FAIL: $*" >&2; exit 1; }

[[ -f "$MANIFEST" ]] || fail "missing data/ip-valuation.json"
[[ -f "$EDGE" ]] || fail "missing coming-soon/site/public/ip-valuation.json"
[[ -f "$POLICY" ]] || fail "missing IP-VALUATION.md"

jq -e '.schema == "brmste-ip-valuation/v1"' "$MANIFEST" >/dev/null || fail "schema mismatch"
jq -e '.patent_uk == "GB2607860"' "$MANIFEST" >/dev/null || fail "patent_uk must be GB2607860"
jq -e '.doctrine.unit == "1SAT = 1£"' "$MANIFEST" >/dev/null || fail "doctrine must be 1SAT = 1£"
jq -e '.anchor.address == "32i1m6gNcSHwiPX9nfTNXVjme9j5DU8y5g"' "$MANIFEST" >/dev/null || fail "anchor address mismatch"
jq -e '.transfer_90_days.days == 90' "$MANIFEST" >/dev/null || fail "transfer must be 90 days"
jq -e '.transfer_90_days.from.name == "Shravan Bansal"' "$MANIFEST" >/dev/null || fail "from operator mismatch"
jq -e '.transfer_90_days.to.name == "Kohinoor Bansal"' "$MANIFEST" >/dev/null || fail "to recipient mismatch"
jq -e '(.fellow_licensors | map(.name) | index("Siemens")) != null' "$MANIFEST" >/dev/null || fail "Siemens licensor missing"
jq -e '(.fellow_licensors | map(.name) | index("Porsche")) != null' "$MANIFEST" >/dev/null || fail "Porsche licensor missing"
jq -e '(.work_against_ip | length) >= 8' "$MANIFEST" >/dev/null || fail "work_against_ip too short"

grep -q 'GB2607860' "$POLICY" || fail "IP-VALUATION.md must cite GB2607860"
grep -q '1 SAT = 1 £' "$POLICY" || fail "IP-VALUATION.md must cite 1SAT=1£ doctrine"
grep -q '32i1m6gNcSHwiPX9nfTNXVjme9j5DU8y5g' "$POLICY" || fail "IP-VALUATION.md must cite anchor address"
grep -q 'Kohinoor Bansal' "$POLICY" || fail "IP-VALUATION.md must cite Kohinoor Bansal"

diff -q "$MANIFEST" "$EDGE" >/dev/null || fail "edge mirror out of sync with data/ip-valuation.json"

echo "IP-VALUATION VERIFY OK: manifest · edge mirror · policy · GB2607860 · 1SAT=1£"
