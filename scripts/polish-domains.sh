#!/usr/bin/env bash
# Polish auditor for every BRMSTE domain — no secrets required.
#
# Reads the edge-posture baseline from domains/registry.json (_meta.polish) and
# audits each domain over HTTPS: TLS reachability, HSTS (with min max-age), the
# required security headers, the coming-soon /health token, and the META FULL
# STOP rule (no Meta/Facebook/Instagram response headers). Writes a machine
# report to domains/polish-report.json and prints a human summary table.
#
# It is read-only and credential-free: safe to run locally, in CI, or by a
# cloud agent. It never deploys and never asks for CF_API_TOKEN — live changes
# are operator/CI/MCP only (see .cursor/rules/mcp-strict-only.mdc).
#
#   bash scripts/polish-domains.sh                 # audit + write report (exit 0)
#   bash scripts/polish-domains.sh --strict        # exit 1 if a reachable domain is unpolished
#   bash scripts/polish-domains.sh --only brmste.com
#   bash scripts/polish-domains.sh --timeout 15 --no-write
#
# BRMSTE LTD · Companies House 15310393 · GB2607860

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="${ROOT}/domains/registry.json"
REPORT="${ROOT}/domains/polish-report.json"
TIMEOUT=10
STRICT=0
WRITE=1
ONLY=""
UA="BRMSTE-polish-auditor/1.0 (+https://brmste.com)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2 ;;
    --report)   REPORT="$2"; shift 2 ;;
    --timeout)  TIMEOUT="$2"; shift 2 ;;
    --only)     ONLY="$2"; shift 2 ;;
    --strict)   STRICT=1; shift ;;
    --no-write) WRITE=0; shift ;;
    -h|--help)  sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq   >/dev/null 2>&1 || { echo "jq is required" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 2; }
[[ -f "$REGISTRY" ]] || { echo "registry not found: $REGISTRY" >&2; exit 2; }

# ---- baseline (data-driven from the registry) ----
HSTS_MIN=$(jq -r '._meta.polish.hsts_min_max_age // 15552000' "$REGISTRY")
HEALTH_PATH=$(jq -r '._meta.polish.health_path // "/health"' "$REGISTRY")
HEALTH_TOKEN=$(jq -r '._meta.polish.health_token // ""' "$REGISTRY")
mapfile -t REQ_HEADERS < <(jq -r '._meta.polish.require_security_headers[]?' "$REGISTRY")
mapfile -t META_HEADERS < <(jq -r '._meta.polish.meta_forbidden_headers[]?' "$REGISTRY")
[[ ${#REQ_HEADERS[@]} -gt 0 ]] || REQ_HEADERS=(strict-transport-security x-content-type-options referrer-policy)

header_present() { printf '%s' "$1" | grep -qiE "^[[:space:]]*$2[[:space:]]*:"; }

RESULTS_DIR="$(mktemp -d)"
trap 'rm -rf "$RESULTS_DIR"' EXIT

mapfile -t DOMAINS < <(jq -r '.domains[].domain' "$REGISTRY")

printf '%-28s %5s %5s %5s %5s %5s %5s %5s  %s\n' \
  DOMAIN CODE HTTPS HSTS XCTO REFP META HLTH POLISHED
printf '%s\n' "----------------------------------------------------------------------------------------"

audited=0
unpolished_reachable=0

for d in "${DOMAINS[@]}"; do
  [[ -n "$ONLY" && "$d" != "$ONLY" ]] && continue
  audited=$((audited+1))

  role=$(jq -r --arg d "$d" '.domains[] | select(.domain==$d) | .role' "$REGISTRY")

  # Follow redirects to the effective URL and capture the final status code.
  probe=$(curl -sS -o /dev/null -L --max-time "$TIMEOUT" -A "$UA" \
            -w '%{http_code} %{url_effective}' "https://$d/" 2>/dev/null || true)
  code="${probe%% *}"
  eff="${probe#* }"
  [[ "$probe" == "$code" ]] && eff=""   # -w produced only a code
  reachable=false
  [[ -n "$code" && "$code" != "000" ]] && reachable=true

  https=false; hsts=false; xcto=false; referrer=false; meta_clean=true; health=false
  hsts_max_age="null"; missing=()

  if [[ "$reachable" == true ]]; then
    [[ "${eff:-https://$d/}" == https://* ]] && https=true
    hdr=$(curl -sS -D - -o /dev/null --max-time "$TIMEOUT" -A "$UA" "${eff:-https://$d/}" 2>/dev/null || true)

    for h in "${REQ_HEADERS[@]}"; do
      hl=$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')
      if header_present "$hdr" "$h"; then
        case "$hl" in
          strict-transport-security)
            hsts=true
            ma=$(printf '%s' "$hdr" | grep -iE '^[[:space:]]*strict-transport-security[[:space:]]*:' | head -1 \
                 | grep -oiE 'max-age=[0-9]+' | grep -oE '[0-9]+' | head -1)
            hsts_max_age="${ma:-0}"
            if [[ -z "$ma" || "$ma" -lt "$HSTS_MIN" ]]; then hsts=false; missing+=("hsts<${HSTS_MIN}"); fi
            ;;
          x-content-type-options) xcto=true ;;
          referrer-policy)        referrer=true ;;
        esac
      else
        missing+=("$hl")
        case "$hl" in
          strict-transport-security) hsts=false ;;
          x-content-type-options)    xcto=false ;;
          referrer-policy)           referrer=false ;;
        esac
      fi
    done

    for mh in "${META_HEADERS[@]}"; do
      if header_present "$hdr" "$mh"; then meta_clean=false; missing+=("meta:$mh"); fi
    done

    if [[ -n "$HEALTH_TOKEN" ]]; then
      body=$(curl -sS --max-time "$TIMEOUT" -A "$UA" "https://$d${HEALTH_PATH}" 2>/dev/null || true)
      printf '%s' "$body" | grep -q "$HEALTH_TOKEN" && health=true || health=false
    fi

    [[ "$https" != true ]] && missing+=("https")
  else
    missing+=("unreachable")
  fi

  # polished = reachable AND all required posture met (health is informational)
  polished=false
  if [[ "$reachable" == true && "$https" == true && "$hsts" == true && "$xcto" == true && "$referrer" == true && "$meta_clean" == true ]]; then
    polished=true
  fi
  [[ "$reachable" == true && "$polished" == false ]] && unpolished_reachable=$((unpolished_reachable+1))

  mark() { [[ "$1" == true ]] && echo "  y  " || echo "  -  "; }
  printf '%-28s %5s %s %s %s %s %s %s  %s\n' \
    "$d" "${code:-000}" "$(mark $https)" "$(mark $hsts)" "$(mark $xcto)" \
    "$(mark $referrer)" "$(mark $meta_clean)" "$(mark $health)" \
    "$([[ $polished == true ]] && echo POLISHED || echo review)"

  # Serialize the per-domain result.
  missing_json=$(printf '%s\n' "${missing[@]:-}" | jq -R . | jq -sc 'map(select(length>0))')
  jq -n \
    --arg domain "$d" --arg role "$role" --argjson reachable "$reachable" \
    --arg http_code "${code:-000}" --arg final_url "${eff:-}" \
    --argjson https "$https" --argjson hsts "$hsts" \
    --argjson hsts_max_age "$hsts_max_age" \
    --argjson xcto "$xcto" --argjson referrer "$referrer" \
    --argjson meta_clean "$meta_clean" --argjson health "$health" \
    --argjson polished "$polished" --argjson missing "$missing_json" \
    '{domain:$domain, role:$role, reachable:$reachable, http_code:$http_code,
      final_url:(if $final_url=="" then null else $final_url end),
      checks:{https:$https, hsts:$hsts, hsts_max_age:$hsts_max_age,
              x_content_type_options:$xcto, referrer_policy:$referrer,
              meta_full_stop:$meta_clean, health_token:$health},
      polished:$polished, missing:$missing}' > "$RESULTS_DIR/$d.json"
done

collect() { find "$RESULTS_DIR" -maxdepth 1 -name '*.json' -exec cat {} +; }
polished_count=$(collect | jq -s '[.[] | select(.polished)] | length')
reachable_count=$(collect | jq -s '[.[] | select(.reachable)] | length')

echo
echo "audited=${audited}  reachable=${reachable_count}  polished=${polished_count}  unpolished_reachable=${unpolished_reachable}"

if [[ "$WRITE" -eq 1 ]]; then
  collect | jq -s \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson expected "$(jq '._meta.expected_total' "$REGISTRY")" \
    '{_meta:{report:"brmste-domains-polish/v1",
             generated_at:$ts,
             expected_total:$expected,
             enumerated:(length),
             reachable:([.[]|select(.reachable)]|length),
             polished:([.[]|select(.polished)]|length),
             note:"Credential-free HTTPS posture audit. expected_total (38) is the live Cloudflare active-zone count; enumerated is the known apex set in registry.json."},
      domains: .}' > "$REPORT"
  echo "wrote report: ${REPORT#$ROOT/}"
fi

if [[ "$STRICT" -eq 1 && "$unpolished_reachable" -gt 0 ]]; then
  echo "STRICT: ${unpolished_reachable} reachable domain(s) not polished" >&2
  exit 1
fi
exit 0
