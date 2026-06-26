#!/usr/bin/env bash
# Refresh Cloudflare MCP equities & holdings bundle on operator Mac.
# Builds public JSON, syncs corpus, pushes to Cloudflare KV (no Fort Knox values in git).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env.fort-knox ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env.fort-knox
  set +a
fi

echo "-> build Cloudflare MCP equities bundle"
node scripts/build-cloudflare-mcp-equities-bundle.mjs

echo "-> sync corpus to website"
node scripts/sync-corpus-to-website.mjs

KV_NS="${BRMSTE_CF_KV_NAMESPACE_ID:-}"
KV_KEY="${BRMSTE_CF_KV_KEY:-equities-holdings.json}"
BUNDLE="$ROOT/data/cloudflare-mcp-equities-holdings.json"

if [[ -z "$KV_NS" ]]; then
  if [[ -f "$BUNDLE" ]]; then
    KV_NS="$(python3 - <<'PY' "$BUNDLE"
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("cloudflare_binding", {}).get("kv_namespace", {}).get("id", ""))
PY
)"
  fi
fi

if command -v wrangler >/dev/null 2>&1 && [[ -n "$KV_NS" ]] && [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "-> wrangler kv key put (namespace $KV_NS)"
  wrangler kv key put "$KV_KEY" --namespace-id="$KV_NS" --path="$BUNDLE" --remote
  echo "cloudflare_kv_refresh_ok key=$KV_KEY namespace=$KV_NS"
else
  echo "skip_kv: set CLOUDFLARE_API_TOKEN and BRMSTE_CF_KV_NAMESPACE_ID (or wrangler + binding id in register)"
fi

echo "refresh_cloudflare_mcp_ok bundle=$BUNDLE corpus=website/public/corpus/"
