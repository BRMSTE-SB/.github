#!/usr/bin/env bash
# BRMSTE compute runner — THE KOHINOOR MAC only (not cloud agents).
# Heavy work: wrangler dev, graphify, aikido, CI deploy trigger.
#
#   bash scripts/run-on-kohinoor-mac.sh help
#   bash scripts/run-on-kohinoor-mac.sh all
#   bash scripts/run-on-kohinoor-mac.sh wrangler-dev
#   bash scripts/run-on-kohinoor-mac.sh verify-headers
#   bash scripts/run-on-kohinoor-mac.sh graphify-update
#   bash scripts/run-on-kohinoor-mac.sh aikido-scan
#   bash scripts/run-on-kohinoor-mac.sh deploy-ci
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMING_SOON="$ROOT/coming-soon"
DEV_PORT="${DEV_PORT:-8787}"
DEV_HOST="${DEV_HOST:-127.0.0.1}"

usage() {
  cat <<'EOF'
Usage: bash scripts/run-on-kohinoor-mac.sh <command>

Commands:
  help             Show this help
  wrangler-dev     npm ci + wrangler dev on :8787 (foreground)
  verify-headers   curl /health and sample JSON manifests for no-store
  graphify-update  uv tool install graphifyy + graphify update .
  graphify-query   graphify query "<question>" (pass question as 2nd arg)
  aikido-scan      npm run lint if present; remind to run Aikido MCP on desktop
  deploy-ci        gh workflow run deploy-coming-soon.yml (requires gh auth)
  all              verify-headers (needs wrangler already running) + graphify-update

Run on THE KOHINOOR MAC — cloud agents must not use this script on the VM.
See docs/COMPUTE-MAC-HETZNER.md
EOF
}

cmd_wrangler_dev() {
  echo "→ wrangler dev on ${DEV_HOST}:${DEV_PORT}"
  cd "$COMING_SOON"
  npm ci --no-audit --no-fund
  exec npx wrangler dev --ip "$DEV_HOST" --port "$DEV_PORT"
}

cmd_verify_headers() {
  local base="http://${DEV_HOST}:${DEV_PORT}"
  echo "→ GET ${base}/health"
  curl -fsSI "${base}/health" | grep -iE '^(HTTP/|cache-control|x-brmste)' || true
  echo ""
  for path in \
    "/public/banking-manifest.json" \
    "/public/portfolio-manifest.json" \
    "/public/companies-house-manifest.json"; do
    echo "→ GET ${base}${path}"
    curl -fsSI "${base}${path}" | grep -iE '^(HTTP/|cache-control|x-brmste)' || true
    echo ""
  done
  echo "Expect: Cache-Control: no-store on /health and *.json"
}

cmd_graphify_update() {
  echo "→ graphify update (AST-only)"
  if ! command -v graphify >/dev/null 2>&1; then
    if command -v uv >/dev/null 2>&1; then
      uv tool install graphifyy
    else
      echo "Install uv or graphifyy first: https://docs.astral.sh/uv/" >&2
      exit 1
    fi
  fi
  cd "$ROOT"
  graphify update .
  echo "✓ graph at graphify-out/ ($(wc -c < graphify-out/graph.json 2>/dev/null || echo 0) bytes)"
}

cmd_graphify_query() {
  local q="${1:-MCP deploy coming soon worker}"
  cd "$ROOT"
  graphify query "$q"
}

cmd_aikido_scan() {
  cd "$ROOT"
  if [[ -f package.json ]] && npm run 2>/dev/null | grep -q ' lint'; then
    npm run lint || true
  fi
  if [[ -d coming-soon ]] && [[ -f coming-soon/package.json ]]; then
    (cd coming-soon && npm run lint 2>/dev/null) || true
  fi
  cat <<'EOF'

→ Aikido: run on desktop Cursor (MCP connected), not cloud agent:
  1. Cursor → Settings → Tools & MCP → Aikido → Connect
  2. aikido_full_scan on the repo root

Questionnaire: https://app.aikido.dev/queue?questionnaire=1
EOF
}

cmd_deploy_ci() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Install GitHub CLI (gh) and auth: gh auth login" >&2
    exit 1
  fi
  cd "$ROOT"
  gh workflow run deploy-coming-soon.yml
  echo "→ Triggered deploy-coming-soon.yml — watch: gh run list --workflow=deploy-coming-soon.yml"
}

cmd_all() {
  cmd_graphify_update
  if curl -fsS "http://${DEV_HOST}:${DEV_PORT}/health" >/dev/null 2>&1; then
    cmd_verify_headers
  else
    echo "⚠ wrangler not running — start: bash scripts/run-on-kohinoor-mac.sh wrangler-dev"
  fi
}

main="${1:-help}"
case "$main" in
  help|-h|--help) usage ;;
  wrangler-dev) cmd_wrangler_dev ;;
  verify-headers) cmd_verify_headers ;;
  graphify-update) cmd_graphify_update ;;
  graphify-query) cmd_graphify_query "${2:-}" ;;
  aikido-scan) cmd_aikido_scan ;;
  deploy-ci) cmd_deploy_ci ;;
  all) cmd_all ;;
  *)
    echo "Unknown command: $main" >&2
    usage >&2
    exit 1
    ;;
esac
