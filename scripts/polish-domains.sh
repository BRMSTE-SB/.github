#!/usr/bin/env bash
# Credential-free HTTPS polish auditor for the BRMSTE domain fleet.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Reads domains/registry.json, probes each known apex over HTTPS ONLY
# (no tokens, no Cloudflare API), inspects the security-header surface as
# delivered (by whichever layer answers — the Hetzner domains-platform /
# Caddy or the legacy coming-soon worker), and writes domains/polish-report.json
# with a per-domain remediation plus grouped _meta.next_actions.
#
# Header policy is data-driven from registry.policy:
#   required_headers   — must appear on EVERY response (incl. redirects)
#   forbidden_headers  — stack/topology leaks that must be stripped
#
# This audits; it does not deploy. Applying remediations (activating a zone,
# hardening headers on the domains-platform / edge, stripping leak headers) is
# done via the Cloudflare-builds MCP, the Hetzner domains-platform config, or
# CI on merge — never a pasted token (MCP-strict).
#
# Usage:
#   bash scripts/polish-domains.sh [--timeout N] [--out PATH] [--quiet]
#
# Remediation taxonomy (HTTPS-only — any numeric code means HTTPS was reached,
# so we NEVER force-https):
#   activate-zone        unreachable (000) and CF zone not marked active
#   investigate-origin   unreachable but CF zone active, OR a reached 4xx/5xx
#   harden-headers       reached but one or more required security headers are
#                        missing (e.g. no Content-Security-Policy)
#   strip-meta-headers   reached with all required headers, but a forbidden
#                        header leaks stack/topology (e.g. x-middleware-rewrite)
#   none                 polished (reached, all required headers, no leaks) or
#                        an external host we only monitor
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${ROOT}/domains/registry.json"
OUT="${ROOT}/domains/polish-report.json"
TIMEOUT=12
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    --out)     OUT="${2:?--out needs a value}"; shift 2 ;;
    --quiet)   QUIET=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

fail() { echo "[polish] FAIL: $*" >&2; exit 1; }
log()  { [[ "$QUIET" -eq 1 ]] || echo "[polish] $*"; }

command -v jq   >/dev/null 2>&1 || fail "jq is required"
command -v curl >/dev/null 2>&1 || fail "curl is required"
[[ -f "$REGISTRY" ]] || fail "missing $REGISTRY"

# policy (lower-cased header names)
mapfile -t REQUIRED < <(jq -r '.policy.required_headers[]?  | ascii_downcase' "$REGISTRY")
mapfile -t FORBIDDEN < <(jq -r '.policy.forbidden_headers[]? | ascii_downcase' "$REGISTRY")
[[ "${#REQUIRED[@]}" -ge 1 ]] || fail "registry.policy.required_headers is empty"

tmp_hdr="$(mktemp)"
results="[]"
trap 'rm -f "$tmp_hdr"' EXIT

n=$(jq '.domains | length' "$REGISTRY")
EXPECTED_TOTAL=$(jq -r '.expected_total // 38' "$REGISTRY")
log "auditing $n known apexes (timeout ${TIMEOUT}s, HTTPS only, no credentials)"
log "policy: ${#REQUIRED[@]} required headers, ${#FORBIDDEN[@]} forbidden headers"

for i in $(seq 0 $((n - 1))); do
  domain=$(jq -r ".domains[$i].domain" "$REGISTRY")
  id=$(jq -r ".domains[$i].id" "$REGISTRY")
  role=$(jq -r ".domains[$i].role" "$REGISTRY")
  cf_zone=$(jq -r ".domains[$i].clouds.cloudflare.zone // false" "$REGISTRY")
  managed=$(jq -r ".domains[$i].expected.managed_headers // false" "$REGISTRY")

  : > "$tmp_hdr"
  code=$(curl -sS -o /dev/null -D "$tmp_hdr" -w '%{http_code}' \
    --max-time "$TIMEOUT" "https://${domain}/" 2>/dev/null) || code="000"

  reached=false; [[ "$code" != "000" ]] && reached=true

  # header inspection (empty file when unreachable → all absent)
  hsts_value=$(grep -i '^strict-transport-security:' "$tmp_hdr" | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//' || true)
  server_hdr=$(grep -i '^server:' "$tmp_hdr" | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//' || true)
  via_hdr=$(grep -i '^via:' "$tmp_hdr" | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//' || true)
  origin_hdr=$(grep -i '^x-brmste-origin:' "$tmp_hdr" | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//' || true)
  location_hdr=$(grep -i '^location:' "$tmp_hdr" | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//' || true)

  missing=()
  if [[ "$managed" == true ]]; then
    for h in "${REQUIRED[@]}"; do
      grep -qi "^${h}:" "$tmp_hdr" || missing+=("$h")
    done
  fi
  leaks=()
  for h in "${FORBIDDEN[@]}"; do
    grep -qi "^${h}:" "$tmp_hdr" && leaks+=("$h")
  done
  missing_json=$(printf '%s\n' "${missing[@]:-}"  | jq -R . | jq -sc 'map(select(length>0))')
  leaks_json=$(printf '%s\n'   "${leaks[@]:-}"    | jq -R . | jq -sc 'map(select(length>0))')

  # ---- classify ----
  remediation="none"; detail=""

  if [[ "$role" == "external" ]]; then
    if [[ "$reached" == true ]]; then
      remediation="none"
      detail="off-edge external host (HTTP ${code}); not on BRMSTE domains-platform — monitor only"
    else
      remediation="none"
      detail="external host unreachable (000); not on BRMSTE domains-platform — monitor only"
    fi
  elif [[ "$reached" == false ]]; then
    if [[ "$cf_zone" == true ]]; then
      remediation="investigate-origin"
      detail="HTTPS unreachable (000) though Cloudflare zone marked active — check DNS/origin"
    else
      remediation="activate-zone"
      detail="HTTPS unreachable (000); Cloudflare zone not active — activate zone + front on domains-platform"
    fi
  elif [[ "$code" -ge 400 ]]; then
    remediation="investigate-origin"
    detail="HTTPS reached HTTP ${code} — origin/app error (server='${server_hdr}')"
  else
    n_missing=$(echo "$missing_json" | jq 'length')
    n_leaks=$(echo "$leaks_json" | jq 'length')
    if [[ "$n_missing" -gt 0 ]]; then
      remediation="harden-headers"
      detail="HTTP ${code} reached but missing: $(echo "$missing_json" | jq -r 'join(", ")') — set uniform security headers on domains-platform"
      [[ "$n_leaks" -gt 0 ]] && detail="${detail}; also leaks: $(echo "$leaks_json" | jq -r 'join(", ")')"
    elif [[ "$n_leaks" -gt 0 ]]; then
      remediation="strip-meta-headers"
      detail="HTTP ${code} has all required headers but leaks: $(echo "$leaks_json" | jq -r 'join(", ")') — strip at edge/platform"
    else
      remediation="none"
      detail="polished — HTTP ${code}, all required headers present, no leaks (server='${server_hdr}')"
    fi
  fi

  status="polished"; [[ "$remediation" != "none" ]] && status="needs-work"

  entry=$(jq -nc \
    --argjson id "$id" \
    --arg domain "$domain" \
    --arg role "$role" \
    --argjson cf_zone "$cf_zone" \
    --argjson managed "$managed" \
    --arg code "$code" \
    --argjson reached "$reached" \
    --arg hsts "$hsts_value" \
    --argjson missing "$missing_json" \
    --argjson leaks "$leaks_json" \
    --arg server "$server_hdr" \
    --arg via "$via_hdr" \
    --arg origin "$origin_hdr" \
    --arg location "$location_hdr" \
    --arg status "$status" \
    --arg remediation "$remediation" \
    --arg detail "$detail" \
    '{
      id: $id, domain: $domain, role: $role,
      cf_zone: $cf_zone, managed_headers: $managed,
      http_code: $code, reached: $reached,
      hsts: (if $hsts == "" then null else $hsts end),
      missing_required_headers: $missing,
      leak_headers: $leaks,
      server: (if $server == "" then null else $server end),
      via: (if $via == "" then null else $via end),
      x_brmste_origin: (if $origin == "" then null else $origin end),
      location: (if $location == "" then null else $location end),
      status: $status, remediation: $remediation, detail: $detail
    }')
  results=$(jq -c --argjson e "$entry" '. + [$e]' <<<"$results")

  log "$(printf '%-26s %-4s %-14s %s' "$domain" "$code" "$status" "$remediation")"
done

polished=$(jq '[.[] | select(.status=="polished")] | length' <<<"$results")
needs=$(jq '[.[] | select(.status=="needs-work")] | length' <<<"$results")

next_actions=$(jq -c '
  [ .[] | select(.remediation != "none") ]
  | group_by(.remediation)
  | map({ (.[0].remediation): (map(.domain)) })
  | add // {}
' <<<"$results")

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson timeout "$TIMEOUT" \
  --argjson total "$n" \
  --argjson polished "$polished" \
  --argjson needs "$needs" \
  --argjson expected_total "$EXPECTED_TOTAL" \
  --argjson required "$(printf '%s\n' "${REQUIRED[@]}" | jq -R . | jq -sc .)" \
  --argjson forbidden "$(printf '%s\n' "${FORBIDDEN[@]:-}" | jq -R . | jq -sc 'map(select(length>0))')" \
  --argjson results "$results" \
  --argjson next_actions "$next_actions" \
  '{
    schema: "brmste-polish-report/v2",
    _meta: {
      owner: "BRMSTE LTD",
      companies_house: "15310393",
      patent: "GB2607860",
      probe: "HTTPS only · credential-free · no Cloudflare API · redirects not followed (headers required on every hop)",
      doctrine: "OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS",
      generated_at: $generated_at,
      timeout_seconds: $timeout,
      known_apexes: $total,
      expected_total_zones: $expected_total,
      required_headers: $required,
      forbidden_headers: $forbidden,
      polished: $polished,
      needs_work: $needs,
      next_actions: $next_actions,
      apply_via: "Cloudflare-builds MCP, Hetzner domains-platform config, or CI on merge — never a pasted token"
    },
    domains: $results
  }' > "$OUT"

log "wrote $OUT"
log "summary: ${polished}/${n} polished, ${needs} need work (expected fleet total ${EXPECTED_TOTAL} zones)"
