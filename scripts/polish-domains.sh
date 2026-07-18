#!/usr/bin/env bash
# polish-domains.sh — credential-free HTTPS posture auditor for the BRMSTE
# multi-cloud domain registry (Cloudflare · Hetzner · AWS · Azure · Siemens IEM).
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
# INV. G06N3/045 · OPERATOR DOESNT BASH · MCP-first · carbon justice only
#
# Reads domains/registry.json and probes each `audit:true` domain over public
# HTTPS only — no API tokens, no Cloudflare/AWS/Azure credentials. It records
# reachability + security-header posture and emits domains/polish-report.json
# with a turnkey remediation plan. Remediations (attach-coming-soon-route /
# activate-zone / force-https / strip-meta-headers / investigate-origin) are
# executed by operator MCP or CI — never by pasted tokens in this VM.
#
# Usage:
#   bash scripts/polish-domains.sh [--timeout 12] [--out FILE] [--registry FILE]
#
# Requires: curl, jq. Network egress to public HTTPS.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${REGISTRY:-$ROOT/domains/registry.json}"
OUT="${OUT:-$ROOT/domains/polish-report.json}"
TIMEOUT="${TIMEOUT:-12}"
UA="BRMSTE-Polish-Auditor/2 (+https://brmste.com)"
HEALTH_TOKEN="brmste-coming-soon-v5"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)  TIMEOUT="$2"; shift 2 ;;
    --out)      OUT="$2"; shift 2 ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1   || { echo "FAIL: jq is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "FAIL: curl is required" >&2; exit 1; }
[[ -f "$REGISTRY" ]] || { echo "FAIL: registry not found: $REGISTRY" >&2; exit 1; }

# --- network helpers (never abort the run) --------------------------------
http_code() {
  curl -sS -m "$TIMEOUT" -o /dev/null -L -w '%{http_code}' -A "$UA" "$1" 2>/dev/null || true
}

# final response header block (last hop after redirects), CR stripped
headers_block() {
  curl -sS -m "$TIMEOUT" -o /dev/null -L -D - -A "$UA" "$1" 2>/dev/null \
    | tr -d '\r' | awk 'BEGIN{RS="";} {b=$0} END{print b}' || true
}

health_token() {
  curl -sS -m "$TIMEOUT" -L -A "$UA" "https://$1/health" 2>/dev/null \
    | jq -r '.page // empty' 2>/dev/null || true
}

echo "[polish] registry=$REGISTRY timeout=${TIMEOUT}s"
results="[]"
total=0

while IFS=$'\t' read -r domain lane cf_zone exp_https exp_hsts exp_worker; do
  [[ -n "$domain" ]] || continue
  total=$((total + 1))

  url="https://${domain}/"
  code="$(http_code "$url")"; [[ -n "$code" ]] || code="000"
  hdrs="$(headers_block "$url")"
  token="$(health_token "$domain")"

  hget() { printf '%s\n' "$hdrs" | grep -qiE "$1"; }

  reachable=false; [[ "$code" != "000" ]] && reachable=true
  https_ok=false;  [[ "$code" =~ ^[23] ]] && https_ok=true

  hsts=false;        hget '^strict-transport-security:'            && hsts=true
  nosniff=false;     hget '^x-content-type-options:[[:space:]]*nosniff' && nosniff=true
  frame=false;       hget '^x-frame-options:'                      && frame=true
  referrer=false;    hget '^referrer-policy:'                      && referrer=true
  permissions=false; hget '^permissions-policy:'                   && permissions=true
  csp=false;         hget '^content-security-policy:'              && csp=true
  worker_surface=false; hget '^x-brmste-surface:'                  && worker_surface=true
  meta_leak=false;   hget '^(x-fb-|x-facebook|x-meta-|x-fbclid)'   && meta_leak=true

  token_match=false; [[ "$token" == "$HEALTH_TOKEN" ]] && token_match=true

  # polished gate
  polished=false
  if [[ "$reachable" == true && "$https_ok" == true && "$hsts" == true ]]; then
    if [[ "$exp_worker" == true ]]; then
      if [[ "$nosniff" == true && "$frame" == true && "$referrer" == true && "$permissions" == true ]]; then
        polished=true
      fi
    else
      polished=true
    fi
  fi

  # missing-headers signal (worker domains want the full uniform set;
  # non-worker/origin domains at least want HSTS)
  missing_headers=false
  if [[ "$exp_worker" == true ]]; then
    [[ "$hsts" != true || "$nosniff" != true || "$frame" != true || "$referrer" != true || "$permissions" != true ]] && missing_headers=true
  else
    [[ "$hsts" != true ]] && missing_headers=true
  fi

  # remediation decision — HTTPS-only probe: code 000 = TLS/DNS unreachable;
  # any numeric code = HTTPS was reached (so it is never a "force-https" case).
  if [[ "$meta_leak" == true ]]; then
    action="strip-meta-headers"
    how="Meta-origin header detected — remove Meta/Facebook headers at edge (META-FULL-STOP)."
  elif [[ "$reachable" != true ]]; then
    if [[ "$cf_zone" == false ]]; then
      action="activate-zone"
      how="Zone not live (HTTP 000). Add/activate the Cloudflare zone + DNS, then attach the coming-soon route."
    else
      action="investigate-origin"
      how="Zone present but unreachable (HTTP 000) — check origin / DNS / proxy status via Cloudflare MCP."
    fi
  elif [[ "$https_ok" != true ]]; then
    # HTTPS reachable but root returns 4xx/5xx (off-edge or unmapped surface)
    if [[ "$exp_worker" == true ]]; then
      action="attach-coming-soon-route"
      how="HTTPS reachable but root returns ${code} (off-edge/unmapped) — attach *${domain}/* route to brmste-com-coming-soon."
    else
      action="investigate-origin"
      how="HTTPS reachable but root returns ${code} — check the Hetzner/origin surface for ${domain}."
    fi
  elif [[ "$missing_headers" == true ]]; then
    action="attach-coming-soon-route"
    how="Serving over HTTPS but missing uniform security headers — attach *${domain}/* route to brmste-com-coming-soon (worker sets all headers)."
  elif [[ "$polished" == true ]]; then
    action="none"
    how="Polished — HTTPS + HSTS + security headers present."
  else
    action="review"
    how="Reachable and serving but posture incomplete — review headers manually."
  fi

  obj="$(jq -n \
    --arg domain "$domain" \
    --arg lane "$lane" \
    --arg code "$code" \
    --arg token "${token:-}" \
    --arg action "$action" \
    --arg how "$how" \
    --argjson cf_zone "$cf_zone" \
    --argjson reachable "$reachable" \
    --argjson https_ok "$https_ok" \
    --argjson hsts "$hsts" \
    --argjson nosniff "$nosniff" \
    --argjson frame "$frame" \
    --argjson referrer "$referrer" \
    --argjson permissions "$permissions" \
    --argjson csp "$csp" \
    --argjson worker_surface "$worker_surface" \
    --argjson meta_leak "$meta_leak" \
    --argjson token_match "$token_match" \
    --argjson polished "$polished" \
    '{
      domain: $domain, lane: $lane, http_code: $code, cf_zone: $cf_zone,
      reachable: $reachable, https_ok: $https_ok,
      headers: {
        hsts: $hsts, nosniff: $nosniff, frame: $frame,
        referrer: $referrer, permissions: $permissions, csp: $csp
      },
      worker_surface: $worker_surface, meta_leak: $meta_leak,
      health_token: $token, health_token_match: $token_match,
      polished: $polished,
      remediation: { action: $action, how: $how }
    }')"

  results="$(jq -c --argjson o "$obj" '. + [$o]' <<<"$results")"

  flag="·"; [[ "$polished" == true ]] && flag="OK"
  printf '  [%s] %-26s code=%s action=%s\n' "$flag" "$domain" "$code" "$action"
done < <(jq -r '.domains[] | select(.audit==true)
  | [ .domain, .lane, (.clouds.cloudflare.zone|tostring),
      (.expected.https|tostring), (.expected.hsts|tostring),
      (.expected.worker_headers|tostring) ] | @tsv' "$REGISTRY")

polished_count="$(jq '[.[] | select(.polished==true)] | length' <<<"$results")"

jq -n \
  --slurpfile reg "$REGISTRY" \
  --argjson results "$results" \
  --argjson total "$total" \
  --argjson polished_count "$polished_count" \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg timeout "$TIMEOUT" \
  '{
    _meta: {
      schema: "brmste-polish-report/v2",
      headline: "BRMSTE MULTI-CLOUD DOMAIN POLISH REPORT",
      owner: "BRMSTE LTD",
      companies_house: "15310393",
      patent_pct: "PCT/GB2026/050406",
      registry: "domains/registry.json",
      expected_total: ($reg[0]._meta.expected_total),
      known_apexes: ($reg[0]._meta.known_apexes),
      audited: $total,
      polished: $polished_count,
      timeout_seconds: ($timeout | tonumber),
      credential_free: true,
      doctrine: "OPERATOR DOESNT BASH · MCP-first · carbon justice only",
      generated_at: $generated_at,
      next_actions: (
        $results
        | map(select(.remediation.action != "none"))
        | group_by(.remediation.action)
        | map({ (.[0].remediation.action): { count: length, domains: map(.domain) } })
        | add // {}
      )
    },
    domains: $results
  }' > "$OUT"

echo "[polish] wrote $OUT — audited ${total}, polished ${polished_count}"
