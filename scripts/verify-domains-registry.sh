#!/usr/bin/env bash
# Structural gate for domains/registry.json — runs with NO credentials.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Checks:
#   - registry.json is valid JSON with schema brmste-domain-registry/v2
#   - domain ids are 1..N, unique and contiguous
#   - known_apexes == number of domains
#   - expected_total >= number of domains
#   - cloudflare_account is a 32-hex id and matches the coming-soon wrangler.toml
#   - worker matches the coming-soon wrangler.toml
#   - every domain carries all five cloud lane keys (value may be null)
#   - every domain carries expected.{https,hsts,worker_headers}
#   - every hetzner binding resolves to an id in data/hetzner/servers.json
#
# Usage: bash scripts/verify-domains-registry.sh
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${ROOT}/domains/registry.json"
SERVERS="${ROOT}/data/hetzner/servers.json"
WRANGLER="${ROOT}/coming-soon/wrangler.toml"

fail() { echo "[verify-domains] FAIL: $*" >&2; exit 1; }
ok()   { echo "[verify-domains] ok: $*"; }

command -v jq >/dev/null 2>&1 || fail "jq is required"
[[ -f "$REGISTRY" ]] || fail "missing $REGISTRY"
[[ -f "$SERVERS"  ]] || fail "missing $SERVERS"

jq -e . "$REGISTRY" >/dev/null 2>&1 || fail "registry.json is not valid JSON"
jq -e . "$SERVERS"  >/dev/null 2>&1 || fail "servers.json is not valid JSON"

schema=$(jq -r '.schema' "$REGISTRY")
[[ "$schema" == "brmste-domain-registry/v2" ]] || fail "unexpected schema: $schema"
ok "schema $schema"

n_domains=$(jq '.domains | length' "$REGISTRY")
[[ "$n_domains" -ge 1 ]] || fail "no domains in registry"

# ids: contiguous 1..N and unique
ids_ok=$(jq -e --argjson n "$n_domains" '
  ( [.domains[].id] | sort ) as $ids
  | ($ids | unique | length) == $n
    and $ids == ([range(1; $n + 1)])
' "$REGISTRY" >/dev/null 2>&1 && echo yes || echo no)
[[ "$ids_ok" == "yes" ]] || fail "domain ids are not a contiguous unique 1..$n_domains sequence"
ok "domain ids 1..$n_domains contiguous & unique"

known_apexes=$(jq -r '.known_apexes' "$REGISTRY")
[[ "$known_apexes" == "$n_domains" ]] || fail "known_apexes ($known_apexes) != domains length ($n_domains)"
ok "known_apexes == domains ($n_domains)"

expected_total=$(jq -r '.expected_total' "$REGISTRY")
[[ "$expected_total" =~ ^[0-9]+$ ]] || fail "expected_total is not an integer: $expected_total"
[[ "$expected_total" -ge "$n_domains" ]] || fail "expected_total ($expected_total) < known apexes ($n_domains)"
ok "expected_total $expected_total >= known apexes $n_domains"

cf_account=$(jq -r '.cloudflare_account' "$REGISTRY")
[[ "$cf_account" =~ ^[0-9a-f]{32}$ ]] || fail "cloudflare_account is not a 32-hex id: $cf_account"
if [[ -f "$WRANGLER" ]]; then
  wrangler_account=$(grep -oE 'account_id[[:space:]]*=[[:space:]]*"[0-9a-f]{32}"' "$WRANGLER" | grep -oE '[0-9a-f]{32}' | head -1 || true)
  [[ -n "$wrangler_account" ]] || fail "could not read account_id from $WRANGLER"
  [[ "$cf_account" == "$wrangler_account" ]] || fail "cloudflare_account ($cf_account) != wrangler account ($wrangler_account)"
  ok "cloudflare_account matches wrangler.toml"

  worker=$(jq -r '.worker' "$REGISTRY")
  wrangler_worker=$(grep -oE 'name[[:space:]]*=[[:space:]]*"[^"]+"' "$WRANGLER" | head -1 | grep -oE '"[^"]+"' | tr -d '"' || true)
  [[ "$worker" == "$wrangler_worker" ]] || fail "worker ($worker) != wrangler name ($wrangler_worker)"
  ok "worker matches wrangler.toml ($worker)"
else
  ok "wrangler.toml absent — skipping edge cross-check"
fi

# every domain has all five cloud lane keys present
lanes_ok=$(jq -e '
  [ .domains[]
    | .clouds
    | has("cloudflare") and has("hetzner") and has("aws") and has("azure") and has("siemens_iem")
  ] | all
' "$REGISTRY" >/dev/null 2>&1 && echo yes || echo no)
[[ "$lanes_ok" == "yes" ]] || fail "a domain is missing one of the five cloud lane keys"
ok "all domains carry all five cloud lanes"

# every domain has expected.{https,hsts,worker_headers}
exp_ok=$(jq -e '
  [ .domains[]
    | .expected
    | (has("https") and has("hsts") and has("worker_headers"))
  ] | all
' "$REGISTRY" >/dev/null 2>&1 && echo yes || echo no)
[[ "$exp_ok" == "yes" ]] || fail "a domain is missing expected.{https,hsts,worker_headers}"
ok "all domains declare expected https/hsts/worker_headers"

# hetzner bindings resolve to servers.json ids
mapfile -t bound_servers < <(jq -r '.domains[].clouds.hetzner // empty | .server // empty' "$REGISTRY" | sort -u)
if [[ "${#bound_servers[@]}" -gt 0 ]]; then
  for s in "${bound_servers[@]}"; do
    [[ -n "$s" ]] || continue
    jq -e --arg s "$s" '.servers[] | select(.id == $s)' "$SERVERS" >/dev/null 2>&1 \
      || fail "hetzner binding '$s' does not resolve to a server id in servers.json"
    ok "hetzner binding '$s' resolves"
  done
else
  ok "no hetzner bindings to resolve"
fi

echo "[verify-domains] PASS — $n_domains known apexes, expected_total $expected_total, account $cf_account"
