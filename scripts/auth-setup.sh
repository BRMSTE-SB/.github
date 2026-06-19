#!/usr/bin/env bash
# BRMSTE auth setup — validates local + CI auth posture for Fort Knox and human-open lanes.
# Usage: bash scripts/auth-setup.sh [lane] [environment]
#   lane        : fort_knox_private | human_open   (default: fort_knox_private)
#   environment : fort-knox-prod | fort-knox-staging | human-open (default: fort-knox-staging)
set -euo pipefail

LANE="${1:-fort_knox_private}"
ENV="${2:-fort-knox-staging}"
FAIL=0

fail()  { echo "BRMSTE-AUTH FAIL: $*" >&2; FAIL=1; }
ok()    { echo "BRMSTE-AUTH OK: $*"; }
info()  { echo "BRMSTE-AUTH INFO: $*"; }
warn()  { echo "BRMSTE-AUTH WARN: $*" >&2; }
sep()   { echo "------------------------------------------------------------"; }

# ---------------------------------------------------------------------------
# 1. Brand + patent gate
# ---------------------------------------------------------------------------
sep
info "Running brand + patent gate (lane=$LANE)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if bash "$ROOT/scripts/git-worker-brand-patent-gate.sh" "$LANE"; then
  ok "Brand + patent gate passed"
else
  fail "Brand + patent gate failed — fix errors before configuring auth"
fi

# ---------------------------------------------------------------------------
# 2. GitHub CLI authentication
# ---------------------------------------------------------------------------
sep
info "Checking GitHub CLI authentication"
if ! command -v gh >/dev/null 2>&1; then
  fail "GitHub CLI (gh) not installed — install from https://cli.github.com"
elif ! gh auth status >/dev/null 2>&1; then
  fail "Not authenticated — run: gh auth login"
else
  GH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
  ok "GitHub CLI authenticated as: $GH_USER"
fi

# ---------------------------------------------------------------------------
# 3. GitHub Environment check
# ---------------------------------------------------------------------------
sep
info "Checking GitHub Environment '$ENV'"
case "$ENV" in
  fort-knox-prod|fort-knox-staging)
    OIDC_AUDIENCE="brmste-fort-knox"
    ;;
  human-open)
    OIDC_AUDIENCE="brmste-human-open"
    ;;
  *)
    fail "Unknown environment '$ENV' — must be fort-knox-prod, fort-knox-staging, or human-open"
    OIDC_AUDIENCE="unknown"
    ;;
esac
ok "OIDC audience for '$ENV': $OIDC_AUDIENCE"

# Determine the current GitHub repo for environment lookup.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || echo "")
  if [[ -n "$REPO" ]]; then
    ENV_EXISTS=$(gh api "repos/$REPO/environments/$ENV" --jq '.name' 2>/dev/null || echo "")
    if [[ -z "$ENV_EXISTS" ]]; then
      warn "GitHub Environment '$ENV' does not exist on $REPO"
      info "Create it at: https://github.com/$REPO/settings/environments"
    else
      ok "GitHub Environment '$ENV' exists on $REPO"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 4. Cloudflare API token (optional — only checked when CF_API_TOKEN is set)
# ---------------------------------------------------------------------------
sep
info "Checking Cloudflare API token"
if [[ -n "${CF_API_TOKEN:-}" ]]; then
  HTTP=$(curl --silent --output /dev/null --write-out "%{http_code}" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    "https://api.cloudflare.com/client/v4/user/tokens/verify")
  if [[ "$HTTP" == "200" ]]; then
    ok "Cloudflare API token valid"
  else
    fail "Cloudflare API token is set but returned HTTP $HTTP — token may be expired or revoked"
  fi
else
  info "CF_API_TOKEN not set — skipping Cloudflare auth check"
  info "For Cloudflare Workers deployments store CF_API_TOKEN in the GitHub Environment '$ENV'"
fi

# ---------------------------------------------------------------------------
# 5. Secret hygiene — confirm no forbidden files are tracked in git
# ---------------------------------------------------------------------------
sep
info "Checking for accidentally tracked secrets"
FORBIDDEN_PATTERNS=("cf-workers\.env" "\.pem$" "\.p12$" "\.pfx$" "wallet\.key" "\.env\.prod")
FOUND_SECRET=0
for pat in "${FORBIDDEN_PATTERNS[@]}"; do
  MATCH=$(git -C "$ROOT" ls-files 2>/dev/null | grep -E "$pat" || true)
  if [[ -n "$MATCH" ]]; then
    warn "Forbidden file tracked in git (pattern: $pat): $MATCH"
    FOUND_SECRET=1
    FAIL=1
  fi
done
[[ "$FOUND_SECRET" -eq 0 ]] && ok "No forbidden secret files tracked in git"

# ---------------------------------------------------------------------------
# 6. OIDC workflow presence check
# ---------------------------------------------------------------------------
sep
info "Checking for OIDC auth setup workflow"
WORKFLOW_PATH="$ROOT/.github/workflows/brmste-auth-setup-reusable.yml"
if [[ -f "$WORKFLOW_PATH" ]]; then
  ok "brmste-auth-setup-reusable.yml present"
else
  warn "brmste-auth-setup-reusable.yml not found at $WORKFLOW_PATH"
  info "Add it from: BRMSTE-SB/.github/.github/workflows/brmste-auth-setup-reusable.yml"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
sep
if [[ "$FAIL" -eq 0 ]]; then
  ok "Auth setup complete — lane=$LANE env=$ENV audience=$OIDC_AUDIENCE"
  info "Next steps:"
  info "  1. Ensure GitHub Environment '$ENV' is configured in repo Settings → Environments"
  info "  2. Add CF_API_TOKEN and any other secrets to the '$ENV' environment (not repo-level)"
  info "  3. In deploy workflows call: uses: BRMSTE-SB/.github/.github/workflows/brmste-auth-setup-reusable.yml@main"
  info "     with: environment: $ENV, lane: $LANE, verify_cloudflare: true"
  exit 0
else
  echo "BRMSTE-AUTH FAIL: One or more checks failed — review errors above" >&2
  exit 1
fi
