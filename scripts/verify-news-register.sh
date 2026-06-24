#!/usr/bin/env bash
# Verify BRMSTE news register manifests in governance repo.
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ROOT"

fail() { echo "NEWS-REGISTER FAIL: $*" >&2; exit 1; }
ok() { echo "NEWS-REGISTER OK: $*"; }

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
  data/broadcast/news-media-declare.json
  data/apple/news-declare.json
  data/social/news.json
)

for f in "${MANIFESTS[@]}"; do
  require_json "$f"
  require_field "$f" "schema"
  require_field "$f" "operator"
  require_field "$f" "status"
done

grep -q 'GB2607860' data/broadcast/news-media-declare.json \
  || fail "news-media-declare.json must cite GB2607860"
grep -q 'BRMSTE LTD' data/social/news.json \
  || fail "social/news.json must name BRMSTE LTD"
grep -q 'carbon_justice' data/social/news.json \
  || fail "social/news.json must reference carbon justice open lane"

# Live edge binds (best-effort — do not fail CI if edge is temporarily down)
for path in \
  /substrate/broadcast/news-media-declare.json \
  /substrate/apple/news-declare.json \
  /api/gi/news-media/status; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://brmste.com${path}" || echo "000")"
  if [[ "$code" == "200" ]]; then
    ok "live edge $path HTTP $code"
  else
    echo "NEWS-REGISTER WARN: live edge $path HTTP $code (governance mirror still valid)"
  fi
done

ok "BRMSTE registered on news — ${#MANIFESTS[@]} manifests verified"
