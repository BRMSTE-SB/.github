#!/usr/bin/env bash
# BRMSTE LTD · Companies House PSC04+CH01 via Hetzner → Cloudflare Worker
#
# Run on THE KOHINOOR MAC (ops IP 152.37.108.90) with ~/.ssh/config brmste-* aliases.
# Hetzner fleet SSH is firewall-restricted — cloud agents cannot reach it directly.
#
# Flow:
#   Kohinoor Mac → SSH Hetzner (lucifer) → git pull → wrangler deploy → CF Worker
#   → POST https://brmste.com/api/ch/file/brmste-correspondence
#
# Usage:
#   bash scripts/run-companies-house-via-hetzner-cf.sh deploy
#   bash scripts/run-companies-house-via-hetzner-cf.sh file-correspondence
#   bash scripts/run-companies-house-via-hetzner-cf.sh all
#   bash scripts/run-companies-house-via-hetzner-cf.sh oauth-url
#   bash scripts/run-companies-house-via-hetzner-cf.sh status
#
# Env (optional):
#   BRMSTE_HETZNER_CF_HOST     SSH alias (default brmste-lucifer)
#   BRMSTE_HETZNER_REPO        repo path on Hetzner (default ~/BRMSTE-SB/.github)
#   BRMSTE_HETZNER_BRANCH      git branch to checkout (default BRMSTE-CURSORfile-correspondence-6a86)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/hetzner-ssh.sh
source "$ROOT/scripts/lib/hetzner-ssh.sh"

CMD="${1:-all}"
shift || true

HOST="$(hetzner_default_cf_host)"
REPO="${BRMSTE_HETZNER_REPO:-$HOME/BRMSTE-SB/.github}"
BRANCH="${BRMSTE_HETZNER_BRANCH:-BRMSTE-CURSORfile-correspondence-6a86}"

remote_block() {
  cat <<EOF
set -euo pipefail
cd "$REPO"
if [[ -d .git ]]; then
  git fetch origin "$BRANCH" 2>/dev/null || git fetch origin
  git checkout "$BRANCH" 2>/dev/null || git checkout -B "$BRANCH" "origin/$BRANCH"
  git pull --ff-only origin "$BRANCH" 2>/dev/null || true
fi
if [[ -f .env.fort-knox ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.fort-knox
  set +a
fi
export COMPANIES_HOUSE_OAUTH_REDIRECT_URI="\${COMPANIES_HOUSE_OAUTH_REDIRECT_URI:-https://brmste.com/api/ch/oauth/callback}"
EOF
}

run_remote() {
  local inner="$1"
  echo "-> Hetzner $HOST · $CMD"
  hetzner_ssh_cmd "$HOST" bash -s <<EOF
$(remote_block)
$inner
EOF
}

case "$CMD" in
  deploy)
    run_remote "bash scripts/deploy-companies-house-worker-mac.sh"
    ;;
  file-correspondence)
    run_remote "bash scripts/file-companies-house-brmste-cf.sh file-correspondence"
    ;;
  file-it)
    run_remote "bash scripts/file-companies-house-brmste-cf.sh file-it"
    ;;
  oauth-url)
    run_remote "bash scripts/file-companies-house-brmste-cf.sh oauth-url"
    ;;
  status)
    run_remote "bash scripts/file-companies-house-brmste-cf.sh status"
    ;;
  health)
    run_remote "curl -sS https://brmste.com/api/ch/health | python3 -m json.tool"
    ;;
  all)
    run_remote "
      bash scripts/deploy-companies-house-worker-mac.sh
      bash scripts/file-companies-house-brmste-cf.sh file-correspondence
    "
    ;;
  help|*)
    echo "BRMSTE · Companies House via Hetzner → Cloudflare"
    echo "SSH host: $HOST (set BRMSTE_HETZNER_CF_HOST)"
    echo "Remote repo: $REPO"
    echo ""
    echo "  deploy              wrangler deploy brmste-companies-house-live"
    echo "  file-correspondence POST PSC04+CH01 via CF Worker"
    echo "  file-it             ROA + correspondence"
    echo "  oauth-url           OAuth authorize URL"
    echo "  status              Worker bundle status"
    echo "  health              curl /api/ch/health"
    echo "  all                 deploy + file-correspondence"
    echo ""
    echo "Requires: npm run setup:server-ssh · Fort Knox on Hetzner · Kohinoor ops IP"
    ;;
esac
