#!/usr/bin/env bash
# Build CH live bundle, sync corpus, push to BRMSTE-SWEEP-LOG KV on operator Mac.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env.fort-knox ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env.fort-knox
  set +a
fi

echo "-> build Companies House live Cloudflare bundle"
node scripts/build-cloudflare-companies-house-bundle.mjs

echo "-> sync corpus to website"
node scripts/sync-corpus-to-website.mjs

KV_NS="${BRMSTE_CF_CH_KV_NAMESPACE_ID:-}"
KV_KEY="${BRMSTE_CF_CH_KV_KEY:-companies-house-live.json}"
BUNDLE="$ROOT/data/cloudflare-companies-house-live.json"

if [[ -z "$KV_NS" ]]; then
  KV_NS="$(python3 - <<'PY' "$BUNDLE"
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("publish", {}).get("kv_namespace_id", ""))
PY
)"
fi

if command -v wrangler >/dev/null 2>&1 && [[ -n "$KV_NS" ]] && [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "-> wrangler kv key put $KV_KEY (namespace $KV_NS)"
  wrangler kv key put "$KV_KEY" --namespace-id="$KV_NS" --path="$BUNDLE" --remote
  echo "cloudflare_ch_kv_refresh_ok key=$KV_KEY namespace=$KV_NS"
else
  echo "skip_kv: set CLOUDFLARE_API_TOKEN and BRMSTE_CF_CH_KV_NAMESPACE_ID (or binding id in bundle)"
fi

echo "refresh_cloudflare_companies_house_ok bundle=$BUNDLE"
