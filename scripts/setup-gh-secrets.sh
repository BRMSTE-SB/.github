#!/usr/bin/env bash
# BRMSTE GitHub Secrets Setup — run this once from a terminal with admin access.
#
# Prerequisites:
#   - GitHub CLI (gh) authenticated as an org admin: gh auth login
#   - PyNaCl installed: pip install PyNaCl
#   - jq installed
#
# Usage:
#   CLOUDFLARE_API_TOKEN=<token> \
#   R2_ACCESS_KEY_ID=<key_id> \
#   R2_SECRET_ACCESS_KEY=<secret> \
#   bash scripts/setup-gh-secrets.sh
#
# What it does:
#   1. Creates the three BRMSTE GitHub Environments on this repo
#   2. Sets CLOUDFLARE_API_TOKEN on fort-knox-prod and fort-knox-staging
#   3. Sets R2_ACCESS_KEY_ID + R2_SECRET_ACCESS_KEY on fort-knox-prod and fort-knox-staging
#   4. Sets CLOUDFLARE_ACCOUNT_ID as a repo-level variable (not secret)
set -euo pipefail

REPO="BRMSTE-SB/.github"
ACCOUNT_ID="7ea6547b1d6eb1cbd6d0ac5cf960ce2a"
R2_ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"

fail()  { echo "BRMSTE-SETUP FAIL: $*" >&2; exit 1; }
ok()    { echo "BRMSTE-SETUP OK: $*"; }
info()  { echo "BRMSTE-SETUP INFO: $*"; }
sep()   { echo "------------------------------------------------------------"; }

# ── Preflight ─────────────────────────────────────────────────────────────
sep
info "Preflight checks"
command -v gh     >/dev/null 2>&1 || fail "gh CLI not found — https://cli.github.com"
command -v jq     >/dev/null 2>&1 || fail "jq not found"
command -v python3 >/dev/null 2>&1 || fail "python3 not found"
python3 -c "import nacl" 2>/dev/null || fail "PyNaCl not installed — run: pip install PyNaCl"
gh auth status >/dev/null 2>&1    || fail "Not authenticated — run: gh auth login"

CF_API_TOKEN_VAL="${CLOUDFLARE_API_TOKEN:-}"
R2_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET="${R2_SECRET_ACCESS_KEY:-}"

[[ -n "$CF_API_TOKEN_VAL" ]]  || fail "CLOUDFLARE_API_TOKEN env var is not set"
[[ -n "$R2_KEY_ID"         ]] || fail "R2_ACCESS_KEY_ID env var is not set"
[[ -n "$R2_SECRET"         ]] || fail "R2_SECRET_ACCESS_KEY env var is not set"

GH_TOKEN=$(gh auth token 2>/dev/null)
ok "Preflight passed"

# ── Encrypt helper (GitHub requires libsodium sealed-box encryption) ───────
encrypt_secret() {
  local key_id="$1" key_b64="$2" secret_value="$3"
  python3 - "$key_b64" "$secret_value" <<'PYEOF'
import sys, base64, json
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox

key_b64, value = sys.argv[1], sys.argv[2]
pub_key = PublicKey(base64.b64decode(key_b64))
box = SealedBox(pub_key)
encrypted = box.encrypt(value.encode("utf-8"))
print(base64.b64encode(encrypted).decode("utf-8"))
PYEOF
}

# ── Get repo/environment public key ───────────────────────────────────────
get_env_pubkey() {
  local env="$1"
  curl -s \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/environments/$env/secrets/public-key"
}

# ── Set an environment secret ──────────────────────────────────────────────
set_env_secret() {
  local env="$1" secret_name="$2" secret_value="$3"
  local pubkey_resp key_id key_b64 encrypted_val http

  pubkey_resp=$(get_env_pubkey "$env")
  key_id=$(echo "$pubkey_resp" | jq -r '.key_id')
  key_b64=$(echo "$pubkey_resp" | jq -r '.key')

  if [[ -z "$key_id" || "$key_id" == "null" ]]; then
    fail "Could not get public key for environment '$env' — does the environment exist?"
  fi

  encrypted_val=$(encrypt_secret "$key_id" "$key_b64" "$secret_value")

  http=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/environments/$env/secrets/$secret_name" \
    -d "{\"encrypted_value\":\"$encrypted_val\",\"key_id\":\"$key_id\"}")

  case "$http" in
    201|204) ok "Set secret $secret_name on environment $env" ;;
    *) fail "Failed to set $secret_name on $env (HTTP $http)" ;;
  esac
}

# ── Create environments ────────────────────────────────────────────────────
sep
info "Creating GitHub Environments"
for ENV_NAME in fort-knox-prod fort-knox-staging human-open; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/environments/$ENV_NAME" \
    -d '{}')
  case "$HTTP" in
    200|201) ok "Environment '$ENV_NAME' created/updated" ;;
    403)     fail "403 on creating '$ENV_NAME' — ensure you have admin access to $REPO" ;;
    *)       fail "Failed to create '$ENV_NAME' (HTTP $HTTP)" ;;
  esac
done

# ── Set secrets on Fort Knox environments ─────────────────────────────────
sep
info "Setting secrets on fort-knox-prod and fort-knox-staging"
for FKX_ENV in fort-knox-prod fort-knox-staging; do
  set_env_secret "$FKX_ENV" "CLOUDFLARE_API_TOKEN"  "$CF_API_TOKEN_VAL"
  set_env_secret "$FKX_ENV" "R2_ACCESS_KEY_ID"      "$R2_KEY_ID"
  set_env_secret "$FKX_ENV" "R2_SECRET_ACCESS_KEY"  "$R2_SECRET"
done

# ── Set repo-level variable (non-secret) ──────────────────────────────────
sep
info "Setting CLOUDFLARE_ACCOUNT_ID as a repo variable"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$REPO/actions/variables" \
  -d "{\"name\":\"CLOUDFLARE_ACCOUNT_ID\",\"value\":\"$ACCOUNT_ID\"}" 2>/dev/null)
# 409 = already exists — PATCH instead
if [[ "$HTTP" == "409" ]]; then
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/actions/variables/CLOUDFLARE_ACCOUNT_ID" \
    -d "{\"name\":\"CLOUDFLARE_ACCOUNT_ID\",\"value\":\"$ACCOUNT_ID\"}")
fi
case "$HTTP" in
  201|204) ok "Set variable CLOUDFLARE_ACCOUNT_ID=$ACCOUNT_ID" ;;
  *)       fail "Failed to set CLOUDFLARE_ACCOUNT_ID (HTTP $HTTP)" ;;
esac

info "Set variable R2_ENDPOINT=$R2_ENDPOINT"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$REPO/actions/variables" \
  -d "{\"name\":\"R2_ENDPOINT\",\"value\":\"$R2_ENDPOINT\"}" 2>/dev/null)
if [[ "$HTTP" == "409" ]]; then
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO/actions/variables/R2_ENDPOINT" \
    -d "{\"name\":\"R2_ENDPOINT\",\"value\":\"$R2_ENDPOINT\"}")
fi
case "$HTTP" in
  201|204) ok "Set variable R2_ENDPOINT" ;;
  *)       info "R2_ENDPOINT variable: HTTP $HTTP (non-fatal)" ;;
esac

# ── Summary ────────────────────────────────────────────────────────────────
sep
ok "GitHub Environments and secrets configured"
echo ""
echo "  Environments : fort-knox-prod | fort-knox-staging | human-open"
echo "  Secrets set  : CLOUDFLARE_API_TOKEN, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY"
echo "  Variables    : CLOUDFLARE_ACCOUNT_ID=$ACCOUNT_ID"
echo "  R2 endpoint  : $R2_ENDPOINT"
echo ""
info "Verify at: https://github.com/$REPO/settings/environments"
