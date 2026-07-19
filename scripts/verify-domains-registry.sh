#!/usr/bin/env bash
# Verify the BRMSTE multi-cloud domain registry is structurally sound.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Credential-free structural gate — no network, no tokens. Safe for CI and agents.
#
# Usage:
#   bash scripts/verify-domains-registry.sh
#
# Checks:
#   - registry.json is valid JSON with schema brmste-domain-registry/v2
#   - domain ids are unique and contiguous 1..N
#   - known_apexes == number of domains; expected_total >= known_apexes
#   - Cloudflare account id in cloud lane matches coming-soon/wrangler.toml
#   - every domain declares all 5 cloud lanes (cloudflare/hetzner/aws/azure/siemens_iem)
#   - policy.required_headers is non-empty and includes Content-Security-Policy
#   - every hetzner server binding resolves to an id in data/hetzner/servers.json
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${ROOT}/domains/registry.json"
SCHEMA="${ROOT}/domains/registry.schema.json"
WRANGLER="${ROOT}/coming-soon/wrangler.toml"
SERVERS="${ROOT}/data/hetzner/servers.json"

pass() { echo "[verify-domains] PASS: $*"; }
fail() { echo "[verify-domains] FAIL: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required"

[ -f "$REGISTRY" ] || fail "missing $REGISTRY"
[ -f "$SCHEMA" ]   || fail "missing $SCHEMA"
[ -f "$WRANGLER" ] || fail "missing $WRANGLER"
[ -f "$SERVERS" ]  || fail "missing $SERVERS"

jq -e . "$REGISTRY" >/dev/null 2>&1 || fail "registry.json is not valid JSON"
jq -e . "$SCHEMA"   >/dev/null 2>&1 || fail "registry.schema.json is not valid JSON"

schema_id="$(jq -r '.schema' "$REGISTRY")"
[ "$schema_id" = "brmste-domain-registry/v2" ] || fail "unexpected schema: $schema_id"
pass "schema is brmste-domain-registry/v2"

# --- ids unique and contiguous 1..N ---
n="$(jq '.domains | length' "$REGISTRY")"
[ "$n" -ge 1 ] || fail "no domains defined"
ids_ok="$(jq -r --argjson n "$n" '
  ([.domains[].id] | sort) == ([range(1; $n + 1)]) ' "$REGISTRY")"
[ "$ids_ok" = "true" ] || fail "domain ids are not unique/contiguous 1..$n"
pass "domain ids unique and contiguous 1..$n"

# --- known_apexes == N ; expected_total >= N ---
known="$(jq -r '.known_apexes' "$REGISTRY")"
[ "$known" = "$n" ] || fail "known_apexes ($known) != domain count ($n)"
expected_total="$(jq -r '.expected_total' "$REGISTRY")"
[ "$expected_total" -ge "$n" ] || fail "expected_total ($expected_total) < domain count ($n)"
pass "known_apexes=$n · expected_total=$expected_total"

# --- Cloudflare account id matches wrangler.toml ---
wr_account="$(grep -E '^account_id' "$WRANGLER" | head -1 | sed -E 's/.*"(.*)".*/\1/')"
[ -n "$wr_account" ] || fail "could not read account_id from wrangler.toml"
if ! jq -e --arg a "$wr_account" '.clouds.cloudflare | contains($a)' "$REGISTRY" >/dev/null; then
  fail "Cloudflare account $wr_account not referenced in registry .clouds.cloudflare"
fi
pass "Cloudflare account $wr_account matches wrangler.toml"

# --- top-level clouds has all 5 lanes ---
for lane in cloudflare hetzner aws azure siemens_iem; do
  jq -e --arg l "$lane" '.clouds | has($l)' "$REGISTRY" >/dev/null \
    || fail "top-level clouds missing lane: $lane"
done
pass "top-level clouds declares all 5 lanes"

# --- policy required_headers non-empty + includes CSP ---
req_count="$(jq '.policy.required_headers | length' "$REGISTRY")"
[ "$req_count" -ge 1 ] || fail "policy.required_headers is empty"
jq -e '.policy.required_headers | index("Content-Security-Policy")' "$REGISTRY" >/dev/null \
  || fail "policy.required_headers must include Content-Security-Policy"
pass "policy.required_headers has $req_count entries incl Content-Security-Policy"

# --- per-domain: all 5 lanes present; expected block complete ---
bad_lane="$(jq -r '
  [ .domains[]
    | select((.clouds | has("cloudflare") and has("hetzner") and has("aws") and has("azure") and has("siemens_iem")) | not)
    | .apex ] | join(",")' "$REGISTRY")"
[ -z "$bad_lane" ] || fail "domains missing a cloud lane: $bad_lane"

bad_expected="$(jq -r '
  [ .domains[]
    | select((.expected | has("https") and has("hsts") and has("managed_headers")) | not)
    | .apex ] | join(",")' "$REGISTRY")"
[ -z "$bad_expected" ] || fail "domains missing expected fields: $bad_expected"
pass "every domain declares 5 cloud lanes + complete expected block"

# --- hetzner bindings resolve to servers.json ids ---
server_ids="$(jq -r '.servers[].id' "$SERVERS" | sort -u)"
missing=""
while IFS= read -r sid; do
  [ -z "$sid" ] && continue
  echo "$server_ids" | grep -qx "$sid" || missing="${missing} $sid"
done < <(jq -r '.domains[].clouds.hetzner // empty | .server // empty' "$REGISTRY")
[ -z "$missing" ] || fail "hetzner server bindings not found in servers.json:${missing}"
pass "all hetzner server bindings resolve to servers.json ids"

echo "[verify-domains] ALL CHECKS PASSED ($n known apexes, expected_total=$expected_total)"
