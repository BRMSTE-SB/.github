#!/usr/bin/env bash
# verify-domains-registry.sh — structural gate for the multi-cloud domain registry.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
# Credential-free: validates JSON shape + invariants only. No network, no tokens.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${REGISTRY:-$ROOT/domains/registry.json}"
SCHEMA="${SCHEMA:-$ROOT/domains/registry.schema.json}"

command -v jq >/dev/null 2>&1 || { echo "FAIL: jq is required" >&2; exit 1; }

fail=0
err() { echo "FAIL: $*" >&2; fail=1; }
ok()  { echo "ok: $*"; }

[[ -f "$REGISTRY" ]] || { echo "FAIL: registry not found: $REGISTRY" >&2; exit 1; }
jq empty "$REGISTRY" 2>/dev/null || { echo "FAIL: registry is not valid JSON" >&2; exit 1; }
ok "registry is valid JSON"

[[ -f "$SCHEMA" ]] && { jq empty "$SCHEMA" 2>/dev/null && ok "schema is valid JSON" || err "schema is not valid JSON"; }

schema_v="$(jq -r '._meta.schema' "$REGISTRY")"
[[ "$schema_v" == "brmste-domain-registry/v2" ]] && ok "schema tag $schema_v" || err "unexpected schema tag: $schema_v"

# counts
known="$(jq -r '._meta.known_apexes' "$REGISTRY")"
total_expected="$(jq -r '._meta.expected_total' "$REGISTRY")"
domains_len="$(jq -r '.domains | length' "$REGISTRY")"

[[ "$known" == "$domains_len" ]] \
  && ok "known_apexes ($known) == domains[] ($domains_len)" \
  || err "known_apexes ($known) != domains[] length ($domains_len)"

[[ "$total_expected" -ge "$domains_len" ]] \
  && ok "expected_total ($total_expected) >= domains[] ($domains_len)" \
  || err "expected_total ($total_expected) < domains[] ($domains_len)"

# account id consistency (registry _meta vs cloudflare cloud block)
acct_meta="$(jq -r '._meta.cloudflare_account' "$REGISTRY")"
acct_cf="$(jq -r '.clouds.cloudflare.account_id' "$REGISTRY")"
[[ "$acct_meta" == "$acct_cf" && -n "$acct_meta" ]] \
  && ok "cloudflare account id consistent ($acct_meta)" \
  || err "cloudflare account id mismatch: meta=$acct_meta cloud=$acct_cf"

# every declared cloud has a clouds.* block
missing_cloud="$(jq -r '[._meta.clouds[] | select(. as $c | ($clouds | has($c)) | not)] | join(",")' \
  --argjson clouds "$(jq -c '.clouds' "$REGISTRY")" "$REGISTRY")"
[[ -z "$missing_cloud" ]] \
  && ok "all declared clouds have config blocks" \
  || err "clouds declared in _meta but missing config: $missing_cloud"

# unique + sequential ids
dupes="$(jq -r '[.domains[].id] | (length as $n | (unique | length) as $u | if $n==$u then "" else "dupe" end)' "$REGISTRY")"
[[ -z "$dupes" ]] && ok "domain ids are unique" || err "duplicate domain ids present"

seq_ok="$(jq -r '([.domains[].id] | sort) == ([range(1; (.domains|length)+1)])' "$REGISTRY")"
[[ "$seq_ok" == "true" ]] && ok "domain ids are 1..N sequential" || err "domain ids are not 1..N sequential"

# unique domains
ddupes="$(jq -r '[.domains[].domain] | (length as $n | (unique|length) as $u | if $n==$u then "" else "dupe" end)' "$REGISTRY")"
[[ -z "$ddupes" ]] && ok "domain names are unique" || err "duplicate domain names present"

# each domain carries all five cloud keys + expected block
bad="$(jq -r '
  .domains[]
  | select(
      (.clouds | has("cloudflare") and has("hetzner") and has("aws") and has("azure") and has("siemens_iem") | not)
      or (.expected | has("https") and has("hsts") and has("worker_headers") | not)
      or (.clouds.cloudflare | has("zone") and has("worker_route") and has("role") | not)
    )
  | .domain' "$REGISTRY" | paste -sd, -)"
[[ -z "$bad" ]] \
  && ok "every domain has full clouds + expected shape" \
  || err "domains with missing cloud/expected keys: $bad"

# hetzner references must resolve to a server id in data/hetzner/servers.json (when present)
SERVERS="$ROOT/data/hetzner/servers.json"
if [[ -f "$SERVERS" ]]; then
  unknown="$(jq -r --slurpfile s "$SERVERS" '
    ($s[0].servers | map(.id)) as $ids
    | [ .domains[] | .clouds.hetzner | select(. != null) | select((. as $h | $ids | index($h)) | not) ]
    | unique | join(",")' "$REGISTRY")"
  [[ -z "$unknown" ]] \
    && ok "all hetzner bindings resolve to known servers" \
    || err "hetzner bindings not in servers.json: $unknown"
fi

if [[ "$fail" -eq 0 ]]; then
  echo "PASS: domains registry verified ($domains_len known apexes, expected_total $total_expected)"
else
  echo "verification FAILED" >&2
  exit 1
fi
