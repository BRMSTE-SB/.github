#!/usr/bin/env bash
# Verify Okta OIDC manifest and worker auth wiring.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/okta-oidc.json"
INDEX="$ROOT/coming-soon/src/index.js"
OKTA="$ROOT/coming-soon/src/lib/okta.js"

fail() { echo "OKTA VERIFY FAIL: $*" >&2; exit 1; }
info() { echo "OKTA VERIFY: $*"; }

[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"
[[ -f "$INDEX" ]] || fail "missing $INDEX"
[[ -f "$OKTA" ]] || fail "missing $OKTA"

python3 - <<'PY' "$MANIFEST"
import json, sys
path = sys.argv[1]
data = json.load(open(path))
required = [
    "schema", "issuer", "client_id", "redirect_uris",
    "protected_routes", "worker", "routes",
]
for key in required:
    assert key in data, f"missing key: {key}"
assert data["schema"] == "okta-oidc/v1"
assert data["client_id"]
assert "/banking" in data["protected_routes"]
assert data["routes"]["callback"] == "/login/callback"
print("manifest ok")
PY

rg -q 'oktaConfigured|/login/callback|requireAuth' "$INDEX" || fail "index.js missing Okta wiring"
rg -q 'verifyIdToken|code_challenge_method' "$OKTA" || fail "okta.js missing PKCE/JWT logic"

info "Okta OIDC manifest and worker wiring verified"
