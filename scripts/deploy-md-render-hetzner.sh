#!/usr/bin/env bash
# BRMSTE branded MD render — deploy to the Hetzner fleet (origin) behind Cloudflare (HSTS).
# Run on THE KOHINOOR MAC (SSH to brmste-* nodes is Mac-only). Cloud agents cannot SSH the fleet.
#
#   bash scripts/deploy-md-render-hetzner.sh                 # deploy to default nodes
#   MD_RENDER_NODES="brmste-lucifer brmste-leading" bash scripts/deploy-md-render-hetzner.sh
#   bash scripts/deploy-md-render-hetzner.sh --dry-run       # build only, no SSH
#
# After deploy: in Cloudflare, proxy the docs hostname (e.g. brmste.com/docs or
# docs.brmste.com) to the node(s) on :8787 and enable HSTS at the edge
# (SSL/TLS -> Edge Certificates -> HSTS: max-age 63072000, includeSubDomains, preload).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/md-render"
REMOTE_DIR="/opt/brmste-md-render"
PORT="${PORT:-8787}"

# Default write-access SSH aliases (configure in ~/.ssh/config on the Kohinoor Mac).
# The 15-node fleet is listed in docs/HETZNER-MAC-COLLECT.md.
DEFAULT_NODES="brmste-lucifer brmste-foundry-pool brmste-leading brmste-carbon-usa brmste-carbon-usa2 brmste-commercial-com brmste-bizstrat brmste-siemens brmste-retyre brmste-patent-box brmste-patent-carbon brmste-sdbm-os brmste-commercial-ai-sb brmste-shravan-hetzner brmste-db"
read -r -a NODES <<<"${MD_RENDER_NODES:-$DEFAULT_NODES}"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

echo "→ Building branded render (md-render/)"
( cd "$APP" && (npm ci --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund) && node build.mjs )
[[ -f "$APP/dist/index.html" ]] || { echo "build failed: dist/index.html missing" >&2; exit 1; }

if [[ "$DRY_RUN" == "1" ]]; then
  echo "✓ dry-run: built $APP/dist/index.html — skipping SSH deploy"
  exit 0
fi

for node in "${NODES[@]}"; do
  echo "→ Deploying to ${node}"
  ssh -o ConnectTimeout=10 "$node" "sudo mkdir -p ${REMOTE_DIR} && sudo chown \$(whoami) ${REMOTE_DIR}" || { echo "  ssh_fail ${node}" >&2; continue; }
  rsync -az --delete "$APP/dist/" "${node}:${REMOTE_DIR}/dist/"
  rsync -az "$APP/serve.mjs" "$APP/headers.mjs" "$APP/brmste-md-render.service" "${node}:${REMOTE_DIR}/"
  ssh "$node" "sudo cp ${REMOTE_DIR}/brmste-md-render.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now brmste-md-render && sudo systemctl restart brmste-md-render"
  ssh "$node" "curl -fsS -o /dev/null -w 'HSTS=%{header_json}' http://127.0.0.1:${PORT}/healthz" >/dev/null 2>&1 \
    && echo "  ✓ ${node} healthy on :${PORT}" || echo "  ⚠ ${node} health check inconclusive"
done

echo ""
echo "DONE. Next (Cloudflare, operator):"
echo "  1. Proxy docs hostname -> node(s) :${PORT} (orange-cloud)."
echo "  2. SSL/TLS -> Edge Certificates -> enable HSTS (max-age 63072000, includeSubDomains, preload)."
