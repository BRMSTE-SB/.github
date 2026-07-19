#!/usr/bin/env bash
# Polish auditor for the BRMSTE multi-cloud domain registry.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
#
# Credential-free: only DNS resolution + public HTTPS HEAD/GET. No tokens, no MCP,
# no signing. Safe for cloud agents and CI. Writes domains/polish-report.json.
#
# Usage:
#   bash scripts/polish-domains.sh [--timeout N] [--out PATH]
#
# Remediation taxonomy (per apex, evaluated against registry .policy):
#   external role .................... none        (monitor-only)
#   no A/AAAA record (NXDOMAIN) ...... publish-dns
#   resolves but no HTTP response .... investigate-origin
#   HTTP >= 400 ...................... investigate-origin
#   reached, missing required header . harden-headers
#   reached, HSTS below target ....... harden-headers
#   reached, forbidden header leaked . strip-meta-headers
#   reached, all clean ............... none        (polished)
#
# HTTPS is considered reached on ANY numeric HTTP code (never force-https).
# Redirects are NOT followed — required headers must be present on every hop.
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${ROOT}/domains/registry.json"
OUT="${ROOT}/domains/polish-report.json"
TIMEOUT=12

while [ $# -gt 0 ]; do
  case "$1" in
    --timeout) TIMEOUT="${2:?}"; shift 2 ;;
    --out) OUT="${2:?}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
[ -f "$REGISTRY" ] || { echo "missing $REGISTRY" >&2; exit 1; }

mapfile -t REQUIRED < <(jq -r '.policy.required_headers[]' "$REGISTRY")
mapfile -t FORBIDDEN < <(jq -r '.policy.forbidden_headers[]' "$REGISTRY")
TARGET_HSTS="$(jq -r '.policy.target_hsts' "$REGISTRY")"
TARGET_MAXAGE="$(printf '%s' "$TARGET_HSTS" | grep -oE 'max-age=[0-9]+' | head -1 | cut -d= -f2 || true)"
: "${TARGET_MAXAGE:=63072000}"

resolve_ip() {
  # getent exits 2 on NXDOMAIN; tolerate it (pipefail would otherwise abort under set -e)
  { getent ahostsv4 "$1" 2>/dev/null || true; } | awk 'NR==1{print $1}'
}

header_val() { # $1=header dump  $2=header name (any case) -> value, last hop wins
  # tolower() on the field is portable (mawk + gawk); IGNORECASE is gawk-only, avoid it.
  printf '%s' "$1" | tr -d '\r' | \
    awk -v h="$2" 'BEGIN{h=tolower(h)":"} tolower($1)==h {sub($1 FS,""); v=$0} END{print v}'
}

domain_entries="[]"
count="$(jq '.domains | length' "$REGISTRY")"

for i in $(seq 0 $((count - 1))); do
  apex="$(jq -r ".domains[$i].apex" "$REGISTRY")"
  role="$(jq -r ".domains[$i].role" "$REGISTRY")"
  external="$(jq -r ".domains[$i].external" "$REGISTRY")"

  ip="$(resolve_ip "$apex")"
  status="unknown"; action="none"; code="000"
  cf_proxied=false; via=""; origin=""; hsts=""; hsts_ok=false
  missing_json="[]"; present_json="[]"; forbidden_json="[]"; issues_json="[]"

  add_issue() { # $1=issue $2=action $3=detail
    issues_json="$(jq -c --arg is "$1" --arg ac "$2" --arg dt "$3" \
      '. + [{issue:$is, action:$ac, detail:$dt}]' <<<"$issues_json")"
  }

  if [ "$external" = "true" ]; then
    status="external"; action="none"
    add_issue "external" "none" "External-managed host ($role) — monitor only, out of BRMSTE header scope."
  elif [ -z "$ip" ]; then
    status="unpublished"; action="publish-dns"
    add_issue "nxdomain" "publish-dns" "No A/AAAA record. Publish DNS to the intended origin, then bind at the Caddy domains-platform."
  else
    hdr="$(curl -sS -D - -o /dev/null --max-time "$TIMEOUT" "https://${apex}/" 2>/dev/null || true)"
    code="$(printf '%s' "$hdr" | tr -d '\r' | awk 'NR==1 && $2 ~ /^[0-9]+$/ {print $2; exit}')"
    : "${code:=000}"
    if printf '%s' "$hdr" | grep -qi '^cf-ray:'; then cf_proxied=true; fi
    via="$(header_val "$hdr" 'via')"
    origin="$(header_val "$hdr" 'x-brmste-origin')"
    hsts="$(header_val "$hdr" 'strict-transport-security')"

    if [ "$code" = "000" ]; then
      status="unreachable"; action="investigate-origin"
      add_issue "no-http" "investigate-origin" "DNS resolves to ${ip} but no HTTP response within ${TIMEOUT}s. Check origin/Caddy service."
    elif [ "$code" -ge 400 ] 2>/dev/null; then
      status="error"; action="investigate-origin"
      add_issue "http-${code}" "investigate-origin" "Origin returned HTTP ${code}. Check Caddy route / upstream health."
    else
      # reached (2xx/3xx) — evaluate headers
      for h in "${REQUIRED[@]}"; do
        v="$(header_val "$hdr" "$(printf '%s' "$h" | tr 'A-Z' 'a-z')")"
        if [ -n "$v" ]; then
          present_json="$(jq -c --arg h "$h" '. + [$h]' <<<"$present_json")"
        else
          missing_json="$(jq -c --arg h "$h" '. + [$h]' <<<"$missing_json")"
        fi
      done
      for h in "${FORBIDDEN[@]}"; do
        v="$(header_val "$hdr" "$(printf '%s' "$h" | tr 'A-Z' 'a-z')")"
        [ -n "$v" ] && forbidden_json="$(jq -c --arg h "$h" '. + [$h]' <<<"$forbidden_json")"
      done

      cur_maxage="$(printf '%s' "$hsts" | grep -oE 'max-age=[0-9]+' | head -1 | cut -d= -f2 || true)"
      if [ -n "$cur_maxage" ] && [ "$cur_maxage" -ge "$TARGET_MAXAGE" ] 2>/dev/null; then
        hsts_ok=true
      fi

      n_missing="$(jq 'length' <<<"$missing_json")"
      n_forbidden="$(jq 'length' <<<"$forbidden_json")"

      if [ "$n_missing" -gt 0 ]; then
        add_issue "missing-required" "harden-headers" \
          "Missing required header(s): $(jq -r 'join(", ")' <<<"$missing_json"). Add at the Caddy domains-platform layer (see domains/POLISH.md)."
      fi
      if [ "$hsts_ok" != "true" ]; then
        add_issue "weak-hsts" "harden-headers" \
          "HSTS is '${hsts:-absent}' — below target max-age=${TARGET_MAXAGE} (2yr, preload). Raise to ${TARGET_HSTS}."
      fi
      if [ "$n_forbidden" -gt 0 ]; then
        add_issue "leaked-headers" "strip-meta-headers" \
          "Forbidden header(s) leaked: $(jq -r 'join(", ")' <<<"$forbidden_json"). Strip at Caddy (header -X-Powered-By etc.)."
      fi

      if [ "$n_missing" -gt 0 ] || [ "$hsts_ok" != "true" ]; then
        status="needs-work"; action="harden-headers"
      elif [ "$n_forbidden" -gt 0 ]; then
        status="needs-work"; action="strip-meta-headers"
      else
        status="polished"; action="none"
      fi
    fi
  fi

  entry="$(jq -n \
    --argjson id "$((i + 1))" \
    --arg apex "$apex" --arg role "$role" --argjson external "$external" \
    --arg ip "${ip:-}" --argjson cf "$cf_proxied" \
    --arg code "$code" --arg via "$via" --arg origin "$origin" \
    --arg hsts "$hsts" --argjson hsts_ok "$hsts_ok" \
    --arg status "$status" --arg action "$action" \
    --argjson present "$present_json" --argjson missing "$missing_json" \
    --argjson forbidden "$forbidden_json" --argjson issues "$issues_json" \
    '{id:$id, apex:$apex, role:$role, external:$external,
      resolved_ip:(if $ip=="" then null else $ip end),
      cloudflare_proxied:$cf, http_code:$code,
      via:(if $via=="" then null else $via end),
      x_brmste_origin:(if $origin=="" then null else $origin end),
      hsts:(if $hsts=="" then null else $hsts end), hsts_meets_target:$hsts_ok,
      status:$status, action:$action,
      present_required:$present, missing_required:$missing,
      forbidden_present:$forbidden, remediation:$issues}')"
  domain_entries="$(jq -c --argjson e "$entry" '. + [$e]' <<<"$domain_entries")"

  printf '[polish] %-26s %-11s ip=%-15s code=%-3s cf=%-5s csp=%s hsts_ok=%s\n' \
    "$apex" "$status" "${ip:-NXDOMAIN}" "$code" "$cf_proxied" \
    "$(jq 'index("Content-Security-Policy") != null' <<<"$present_json")" "$hsts_ok" >&2
done

# --- grouped next actions ---
next_actions="$(jq -n --argjson d "$domain_entries" '
  $d | map(.remediation[] as $r | {apex:.apex, action:$r.action, issue:$r.issue, detail:$r.detail})
     | map(select(.action != "none"))
     | group_by(.action)
     | map({action: .[0].action, count: length,
            domains: (map(.apex) | unique),
            items: map({apex:.apex, issue:.issue, detail:.detail})})' )"

summary="$(jq -n --argjson d "$domain_entries" '
  { total: ($d | length),
    polished: ($d | map(select(.status=="polished")) | length),
    needs_work: ($d | map(select(.status=="needs-work")) | length),
    unreachable: ($d | map(select(.status=="unreachable" or .status=="error")) | length),
    unpublished: ($d | map(select(.status=="unpublished")) | length),
    external: ($d | map(select(.status=="external")) | length) }')"

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg target_hsts "$TARGET_HSTS" \
  --argjson timeout "$TIMEOUT" \
  --argjson summary "$summary" \
  --argjson domains "$domain_entries" \
  --argjson next_actions "$next_actions" \
  '{schema:"brmste-polish-report/v2",
    headline:"BRMSTE MULTI-CLOUD DOMAIN POLISH REPORT",
    operator:"Shravan Bansal · BRMSTE LTD · CH 15310393",
    generated_at:$generated_at,
    method:"credential-free · DNS + public HTTPS · no tokens · no signing",
    target_hsts:$target_hsts,
    timeout_seconds:$timeout,
    _meta:{summary:$summary, next_actions:$next_actions},
    domains:$domains}' > "$OUT"

echo "[polish] wrote $OUT" >&2
jq -r '"[polish] summary: total=\(._meta.summary.total) polished=\(._meta.summary.polished) needs_work=\(._meta.summary.needs_work) unreachable=\(._meta.summary.unreachable) unpublished=\(._meta.summary.unpublished) external=\(._meta.summary.external)"' "$OUT" >&2
