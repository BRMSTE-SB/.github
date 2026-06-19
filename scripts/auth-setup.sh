#!/usr/bin/env bash
# BRMSTE auth setup — validates local + CI auth posture for Fort Knox and human-open lanes.
#
# Usage:
#   bash scripts/auth-setup.sh [lane] [environment] [cloudflare_account_id]
#
#   lane                  : fort_knox_private | human_open   (default: fort_knox_private)
#   environment           : fort-knox-prod | fort-knox-staging | human-open (default: fort-knox-staging)
#   cloudflare_account_id : Cloudflare account ID (optional — enables Workers scope check)
#
# Token resolution (in priority order):
#   CLOUDFLARE_API_TOKEN  — wrangler canonical name (preferred)
#   CF_API_TOKEN          — legacy alias
set -euo pipefail

LANE="${1:-fort_knox_private}"
ENV="${2:-fort-knox-staging}"
# Real BRMSTE account ID — default so the Workers scope check runs out of the box.
CF_ACCOUNT_ID="${3:-7ea6547b1d6eb1cbd6d0ac5cf960ce2a}"
FAIL=0

fail()  { echo "BRMSTE-AUTH FAIL: $*" >&2; FAIL=1; }
ok()    { echo "BRMSTE-AUTH OK: $*"; }
info()  { echo "BRMSTE-AUTH INFO: $*"; }
warn()  { echo "BRMSTE-AUTH WARN: $*" >&2; }
sep()   { echo "------------------------------------------------------------"; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. Brand + patent gate ────────────────────────────────────────────────
sep
info "Running brand + patent gate (lane=$LANE)"
if bash "$ROOT/scripts/git-worker-brand-patent-gate.sh" "$LANE"; then
  ok "Brand + patent gate passed"
else
  fail "Brand + patent gate failed — fix errors before configuring auth"
fi

# ── 2. GitHub CLI authentication ──────────────────────────────────────────
sep
info "Checking GitHub CLI authentication"
if ! command -v gh >/dev/null 2>&1; then
  fail "GitHub CLI (gh) not installed — https://cli.github.com"
elif ! gh auth status >/dev/null 2>&1; then
  fail "Not authenticated — run: gh auth login"
else
  GH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
  ok "GitHub CLI authenticated as: $GH_USER"
fi

# ── 3. Environment allowlist + OIDC audience ─────────────────────────────
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

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || echo "")
  if [[ -n "$REPO" ]]; then
    ENV_NAME=$(gh api "repos/$REPO/environments/$ENV" --jq '.name' 2>/dev/null || echo "")
    if [[ -z "$ENV_NAME" ]]; then
      warn "GitHub Environment '$ENV' does not exist on $REPO"
      info "Create it at: https://github.com/$REPO/settings/environments"
    else
      ok "GitHub Environment '$ENV' confirmed on $REPO"
    fi
  fi
fi

# ── 4. Cloudflare API token ───────────────────────────────────────────────
sep
info "Checking Cloudflare API token"

# Prefer the wrangler-canonical name; fall back to legacy alias.
CF_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"

if [[ -z "$CF_TOKEN" ]]; then
  info "Neither CLOUDFLARE_API_TOKEN nor CF_API_TOKEN is set — skipping Cloudflare checks"
  info "For Workers deployments add CLOUDFLARE_API_TOKEN to GitHub Environment '$ENV'"
  info "Token dashboard: https://dash.cloudflare.com/profile/api-tokens"
else
  # 4a. Token liveness via /user/tokens/verify.
  # R2-scoped tokens (cfat_ prefix) return error 1000 from this endpoint
  # but are fully valid for Workers API calls — fall through in that case.
  VERIFY_RESP=$(curl --silent \
    -H "Authorization: Bearer $CF_TOKEN" \
    "https://api.cloudflare.com/client/v4/user/tokens/verify")
  CF_SUCCESS=$(echo "$VERIFY_RESP" | jq -r '.success')
  CF_STATUS=$(echo  "$VERIFY_RESP" | jq -r '.result.status // "unknown"')
  CF_TOKEN_ID=$(echo "$VERIFY_RESP" | jq -r '.result.id    // "unknown"')
  CF_ERR_CODE=$(echo "$VERIFY_RESP" | jq -r '.errors[0].code // 0')
  CF_TOKEN_TYPE="standard"

  if [[ "$CF_SUCCESS" == "true" && "$CF_STATUS" == "active" ]]; then
    ok "Cloudflare token active (id=$CF_TOKEN_ID type=standard)"
  elif [[ "$CF_ERR_CODE" == "1000" ]]; then
    CF_TOKEN_TYPE="r2"
    warn "R2-type token detected — /user/tokens/verify not supported for R2 tokens"
    info "Workers scope check below will confirm actual API access"
  else
    CF_ERRORS=$(echo "$VERIFY_RESP" | jq -r '[.errors[]?.message] | join(", ")' 2>/dev/null || echo "")
    fail "Cloudflare token rejected (status=$CF_STATUS code=$CF_ERR_CODE errors=$CF_ERRORS)" \
      "— rotate at https://dash.cloudflare.com/profile/api-tokens"
  fi

  # 4b. Workers Scripts scope check — runs regardless of token type.
  if [[ -n "$CF_ACCOUNT_ID" ]]; then
    info "Verifying Workers Scripts access on account $CF_ACCOUNT_ID (token_type=$CF_TOKEN_TYPE)"
    WS_RESP=$(curl --silent \
      -H "Authorization: Bearer $CF_TOKEN" \
      "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts?per_page=1")
    WS_SUCCESS=$(echo "$WS_RESP" | jq -r '.success')
    WS_COUNT=$(echo   "$WS_RESP" | jq -r '.result | length')
    WS_ERR=$(echo     "$WS_RESP" | jq -r '.errors[0].code // 0')

    if [[ "$WS_SUCCESS" == "true" ]]; then
      ok "Workers Scripts access confirmed on account $CF_ACCOUNT_ID ($WS_COUNT scripts visible)"
    else
      WS_MSG=$(echo "$WS_RESP" | jq -r '.errors[0].message // "unknown"')
      case "$WS_ERR" in
        10000)
          fail "Token auth failed on Workers API (code=$WS_ERR) — rotate at https://dash.cloudflare.com/profile/api-tokens"
          ;;
        10007|9109)
          fail "Token lacks Account.Workers Scripts permission on account $CF_ACCOUNT_ID (code=$WS_ERR)" \
            "— add 'Account.Workers Scripts:Edit' at https://dash.cloudflare.com/profile/api-tokens"
          ;;
        7003|7000)
          fail "Account '$CF_ACCOUNT_ID' not found (code=$WS_ERR)" \
            "— confirm at https://dash.cloudflare.com/?to=/:account/workers"
          ;;
        *)
          fail "Workers Scripts API error (code=$WS_ERR msg=$WS_MSG) for account $CF_ACCOUNT_ID"
          ;;
      esac
    fi
  fi
fi

# ── 5. R2 S3 credential check ────────────────────────────────────────────
sep
info "Checking R2 S3 credentials"
R2_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET="${R2_SECRET_ACCESS_KEY:-}"
R2_ENDPOINT="https://${CF_ACCOUNT_ID}.r2.cloudflarestorage.com"

if [[ -z "$R2_KEY_ID" || -z "$R2_SECRET" ]]; then
  info "R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY not set — skipping R2 check"
  info "Set them to verify R2 access: R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... bash $0"
else
  # AWS Signature V4 ListBuckets probe against the R2 S3 endpoint.
  DATE=$(date -u +"%Y%m%d")
  DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
  HOST="${CF_ACCOUNT_ID}.r2.cloudflarestorage.com"

  CANONICAL_REQUEST="GET\n/\n\nhost:${HOST}\nx-amz-date:${DATETIME}\n\nhost;x-amz-date\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  PAYLOAD_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  CR_HASH=$(printf '%s' "$CANONICAL_REQUEST" | openssl dgst -sha256 | awk '{print $2}')
  STRING_TO_SIGN="AWS4-HMAC-SHA256\n${DATETIME}\n${DATE}/auto/s3/aws4_request\n${CR_HASH}"

  _hmac() { printf '%s' "$2" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$1" | awk '{print $2}'; }
  _hmac_key() { printf '%s' "$2" | openssl dgst -sha256 -mac HMAC -macopt "key:$1" | awk '{print $2}'; }

  K_DATE=$(_hmac_key "AWS4${R2_SECRET}" "$DATE")
  K_REGION=$(_hmac "$K_DATE" "auto")
  K_SERVICE=$(_hmac "$K_REGION" "s3")
  K_SIGNING=$(_hmac "$K_SERVICE" "aws4_request")
  SIGNATURE=$(printf '%s' "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:${K_SIGNING}" | awk '{print $2}')

  HTTP=$(curl -s -o /tmp/r2_list.xml -w "%{http_code}" \
    -H "Host: $HOST" \
    -H "x-amz-date: $DATETIME" \
    -H "Authorization: AWS4-HMAC-SHA256 Credential=${R2_KEY_ID}/${DATE}/auto/s3/aws4_request,SignedHeaders=host;x-amz-date,Signature=${SIGNATURE}" \
    "${R2_ENDPOINT}/")

  if [[ "$HTTP" == "200" ]]; then
    BUCKET_COUNT=$(grep -o '<Name>' /tmp/r2_list.xml 2>/dev/null | wc -l | tr -d ' ')
    ok "R2 credentials valid — $BUCKET_COUNT bucket(s) visible at $R2_ENDPOINT"
  else
    R2_ERR=$(grep -oP '(?<=<Code>)[^<]+' /tmp/r2_list.xml 2>/dev/null || echo "unknown")
    fail "R2 S3 probe failed (HTTP $HTTP code=$R2_ERR) — check R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY"
  fi
fi

# ── 7. Secret hygiene ─────────────────────────────────────────────────────
sep
info "Scanning for accidentally tracked secrets"
declare -a FORBIDDEN_PATTERNS=(
  "cf-workers\\.env"
  "\\.env\\.prod"
  "\\.env\\.local"
  "wallet\\.key"
  "\\.pem$"
  "\\.p12$"
  "\\.pfx$"
  "\\.pkcs12$"
)
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

# ── 8. OIDC workflow presence check ──────────────────────────────────────
sep
info "Checking for OIDC auth setup workflow"
WORKFLOW="$ROOT/.github/workflows/brmste-auth-setup-reusable.yml"
if [[ -f "$WORKFLOW" ]]; then
  ok "brmste-auth-setup-reusable.yml present"
else
  warn "brmste-auth-setup-reusable.yml not found — expected at $WORKFLOW"
fi

# ── Summary ───────────────────────────────────────────────────────────────
sep
if [[ "$FAIL" -eq 0 ]]; then
  ok "Auth setup complete"
  echo ""
  echo "  lane          : $LANE"
  echo "  environment   : $ENV"
  echo "  oidc_audience : $OIDC_AUDIENCE"
  echo "  cf_account_id : ${CF_ACCOUNT_ID:-(not provided)}"
  echo ""
  info "Next steps:"
  info "  1. Confirm GitHub Environment '$ENV' exists in repo Settings → Environments"
  info "  2. Store CLOUDFLARE_API_TOKEN as an environment secret (not repo-level)"
  info "  3. In deploy workflows call the reusable auth-setup workflow before any deploy step:"
  info "       uses: BRMSTE-SB/.github/.github/workflows/brmste-auth-setup-reusable.yml@main"
  info "       with:"
  info "         environment: $ENV"
  info "         lane: $LANE"
  info "         cloudflare_account_id: $CF_ACCOUNT_ID"
  info "         verify_cloudflare: true"
  exit 0
else
  echo "" >&2
  echo "BRMSTE-AUTH FAIL: One or more checks failed — see errors above" >&2
  exit 1
fi
