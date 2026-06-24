#!/usr/bin/env bash
# Verify BRMSTE FULL GOOGLE TUNE manifests in governance repo.
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ROOT"

fail() { echo "GOOGLE-FULL-TUNE FAIL: $*" >&2; exit 1; }
ok() { echo "GOOGLE-FULL-TUNE OK: $*"; }

require_json() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing required file: $f"
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" || fail "invalid JSON: $f"
}

require_field() {
  local f="$1" field="$2"
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if sys.argv[2] in d else 1)' "$f" "$field" \
    || fail "$f missing field: $field"
}

MANIFESTS=(
  data/google/full-tune.json
  data/google/mangos.json
  data/google/antigravity.json
  data/google/admin.json
  data/google/search-console.json
  data/google-ads/full-tune.json
  data/gi/general-business-intelligence.json
)

for f in "${MANIFESTS[@]}"; do
  require_json "$f"
  require_field "$f" "schema"
  require_field "$f" "operator"
  require_field "$f" "status"
done

grep -q 'GOOGLE MANGOS = WE ARE BRMSTE' data/google/full-tune.json \
  || fail "full-tune.json must declare GOOGLE MANGOS = WE ARE BRMSTE"
grep -q 'GB2607860' data/google/full-tune.json \
  || fail "full-tune.json must cite GB2607860"
grep -q 'HERMES' data/google/antigravity.json \
  || fail "antigravity.json must reference HERMES lane"
grep -q 'brmste.com' data/google/search-console.json \
  || fail "search-console.json must bind brmste.com property"

# Live edge binds (best-effort)
for path in \
  /substrate/google/mangos.json \
  /substrate/google/antigravity.json \
  /substrate/google/admin.json \
  /substrate/google/search-console.json \
  /substrate/gi/general-business-intelligence.json; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://brmste.com${path}" || echo "000")"
  if [[ "$code" == "200" ]]; then
    ok "live edge $path HTTP $code"
  else
    echo "GOOGLE-FULL-TUNE WARN: live edge $path HTTP $code (governance mirror still valid)"
  fi
done

# full-tune.json on edge may not exist yet — governance leads
code="$(curl -s -o /dev/null -w '%{http_code}' "https://brmste.com/substrate/google/full-tune.json" || echo "000")"
if [[ "$code" == "200" ]]; then
  ok "live edge /substrate/google/full-tune.json HTTP $code"
else
  echo "GOOGLE-FULL-TUNE INFO: edge /substrate/google/full-tune.json HTTP $code — governance mirror registered"
fi

ok "FULL GOOGLE TUNE — ${#MANIFESTS[@]} manifests verified"
