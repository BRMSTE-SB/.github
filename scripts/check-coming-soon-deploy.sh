#!/usr/bin/env bash
# Diagnose blockers for brmste-com-coming-soon deploy + carbonjustice.uk go-live.
# BRMSTE LTD · Companies House 15310393 · GB2607860
#
# Usage: bash scripts/check-coming-soon-deploy.sh
# Exit 0 only when production health reports brmste-coming-soon-v5 and carbonjustice.uk resolves.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_NAME="brmste-com-coming-soon"
ACCOUNT_ID="7ea6547b1d6eb1cbd6d0ac5cf960ce2a"
EXPECTED_PAGE="brmste-coming-soon-v5"
CARBON_HOST="carbonjustice.uk"

log()  { echo "[CHECK] $*"; }
ok()   { echo "[CHECK] ✓ $*"; }
warn() { echo "[CHECK] ⚠ $*"; }
fail() { echo "[CHECK] ✗ $*"; }

BLOCKERS=0

log "BRMSTE coming-soon deploy diagnostics"
log "Worker: ${WORKER_NAME} · Account: ${ACCOUNT_ID}"
echo

# 1. Repo catalog + worker bundle
if bash "${ROOT}/scripts/verify-carbon-justice-catalog.sh" >/dev/null 2>&1; then
  ok "Carbon justice catalog validates"
else
  fail "Carbon justice catalog validation failed"
  BLOCKERS=$((BLOCKERS + 1))
fi

if (cd "${ROOT}/coming-soon" && npx wrangler deploy --dry-run >/dev/null 2>&1); then
  ok "Wrangler dry-run bundle OK (v5 assets + handler)"
else
  fail "Wrangler dry-run failed — fix coming-soon/ before deploy"
  BLOCKERS=$((BLOCKERS + 1))
fi

echo

# 2. Deploy credentials (local)
if [[ -n "${CLOUDFLARE_API_TOKEN:-}" || -n "${CF_API_TOKEN:-}" ]]; then
  ok "Cloudflare API token present in shell env"
else
  warn "No CLOUDFLARE_API_TOKEN / CF_API_TOKEN in shell — use Cloudflare-builds MCP or GitHub Actions secrets"
  BLOCKERS=$((BLOCKERS + 1))
fi

echo

# 3. GitHub Actions deploy path
if command -v gh >/dev/null 2>&1; then
  last_run=$(gh run list --workflow=deploy-coming-soon.yml --limit 1 --json conclusion,displayTitle,url -q '.[0]' 2>/dev/null || echo '{}')
  if [[ "$last_run" != "{}" && "$last_run" != "null" ]]; then
    conclusion=$(echo "$last_run" | jq -r '.conclusion // "unknown"')
    title=$(echo "$last_run" | jq -r '.displayTitle // "deploy"')
    url=$(echo "$last_run" | jq -r '.url // ""')
    if [[ "$conclusion" == "success" ]]; then
      ok "Latest GitHub deploy workflow succeeded (${title})"
    else
      fail "Latest GitHub deploy workflow: ${conclusion} — ${title}"
      [[ -n "$url" ]] && warn "See ${url}"
      warn "Set GitHub secrets CF_API_TOKEN + CF_ACCOUNT_ID=${ACCOUNT_ID} (production environment or repo secrets)"
      BLOCKERS=$((BLOCKERS + 1))
    fi
  else
    warn "Could not read GitHub Actions deploy workflow status"
  fi
else
  warn "gh CLI unavailable — skip GitHub Actions check"
fi

echo

# 4. Production worker version (any routed host)
PROD_PAGE=""
for host in brmste.com brmste.ai businessscience.ai re-tyre.com; do
  body=$(curl -fsS --max-time 15 "https://${host}/health" 2>/dev/null || echo "")
  if [[ -n "$body" ]]; then
    page=$(echo "$body" | jq -r '.page // .service // empty' 2>/dev/null || true)
    if [[ -n "$page" ]]; then
      log "${host}/health → ${page}"
      if [[ "$page" == "$EXPECTED_PAGE" ]]; then
        PROD_PAGE="$EXPECTED_PAGE"
      fi
    fi
  fi
done

if [[ "$PROD_PAGE" == "$EXPECTED_PAGE" ]]; then
  ok "Production serving ${EXPECTED_PAGE}"
else
  fail "Production not yet on ${EXPECTED_PAGE} (deployed worker is stale — MCP or CI deploy required)"
  BLOCKERS=$((BLOCKERS + 1))
fi

echo

# 5. carbonjustice.uk DNS
if dig +short "${CARBON_HOST}" NS A 2>/dev/null | grep -q .; then
  ok "${CARBON_HOST} DNS records present"
  ns=$(dig +short "${CARBON_HOST}" NS 2>/dev/null | head -2 | tr '\n' ' ')
  log "Nameservers: ${ns:-unknown}"
else
  fail "${CARBON_HOST} does not resolve — add zone in Cloudflare and point registrar nameservers"
  BLOCKERS=$((BLOCKERS + 1))
fi

if curl -fsS --max-time 15 "https://${CARBON_HOST}/health" 2>/dev/null | jq -e '.surface == "carbon-justice"' >/dev/null 2>&1; then
  ok "${CARBON_HOST}/health → carbon-justice surface live"
else
  warn "${CARBON_HOST}/health not reachable or not on carbon-justice surface yet"
  if dig +short "${CARBON_HOST}" A 2>/dev/null | grep -q .; then
    BLOCKERS=$((BLOCKERS + 1))
  fi
fi

echo
if [[ "$BLOCKERS" -eq 0 ]]; then
  ok "All checks passed — carbonjustice.uk deploy path clear"
  exit 0
fi

fail "${BLOCKERS} blocker(s) remain"
echo
cat <<'EOF'
Resolve (operator — no tokens in chat):

  1. Cursor → Settings → Tools & MCP → Connect → Cloudflare-builds
     Then tell the agent: SEND

  OR GitHub → BRMSTE-SB/.github → Settings → Secrets → Actions:
     CF_API_TOKEN (Workers:Edit + Zone:Worker Routes:Edit)
     CF_ACCOUNT_ID = 7ea6547b1d6eb1cbd6d0ac5cf960ce2a
     Re-run: Actions → BRMSTE Coming Soon — Deploy to All CF Zones

  2. Cloudflare Dashboard → Add site carbonjustice.uk → update registrar NS
     After zone active, deploy script attaches *carbonjustice.uk/* route automatically

  3. Verify:
     curl -s https://carbonjustice.uk/health
     → {"ok":true,"page":"brmste-coming-soon-v5","domain":"carbonjustice.uk","surface":"carbon-justice"}
EOF
exit 1
