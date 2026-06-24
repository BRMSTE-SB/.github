#!/usr/bin/env bash
# BRMSTE git worker brand + patent gate — strict allowlist for logos and patent copy.
# GSI™ — Global Substrate Infrastructure™ · BRMSTE LTD · GB2607860
set -euo pipefail

LANE="${1:-fort_knox_private}"
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ROOT"

fail() { echo "BRMSTE-GATE FAIL: $*" >&2; exit 1; }
ok()   { echo "BRMSTE-GATE OK: $*"; }
warn() { echo "BRMSTE-GATE WARN: $*" >&2; }

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing required file: $f"
}

require_patent_notice() {
  require_file PATENT-NOTICE.md
  grep -q 'GB2607860'           PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must cite GB2607860'
  grep -q 'PCT/GB2026/050406'   PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must cite PCT/GB2026/050406'
  grep -qi 'BRMSTE LTD'         PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must name BRMSTE LTD'
  ok "patent notice: GB2607860 · PCT/GB2026/050406 present"
}

require_trademark_notice() {
  if [[ -f TRADEMARK.md ]]; then
    grep -q 'GB2607860'      TRADEMARK.md || fail 'TRADEMARK.md must cite GB2607860'
    grep -qi 'BRMSTE LTD'   TRADEMARK.md || fail 'TRADEMARK.md must name BRMSTE LTD'
    ok "trademark notice: TRADEMARK.md valid"
  fi
}

scan_logo_urls() {
  local bad=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    case "$url" in
      https://brmste.com/*|https://brmste.ai/*|https://raw.githubusercontent.com/BRMSTE-SB/*)
        ;;
      *)
        echo "BRMSTE-GATE FAIL: non-canonical logo URL: $url" >&2
        bad=1
        ;;
    esac
  done < <(grep -rhoE 'https://[^)"'\''[:space:>]+\.(svg|png|jpg|jpeg|webp|gif)' . \
    --exclude-dir=.git 2>/dev/null | sort -u || true)
  [[ "$bad" -eq 0 ]] || fail 'logo URLs must use canonical BRMSTE/GSI hosts (see BRAND.md)'
  ok "logo URLs: all canonical"
}

scan_http_plaintext() {
  # Detect http:// references to BRMSTE/GSI domains — forbidden
  local bad=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "BRMSTE-GATE FAIL: plaintext http:// BRMSTE/GSI URL: $line" >&2
    bad=1
  done < <(grep -rhoE 'http://[^)"'\''[:space:>]*(brmste\.com|brmste\.ai)[^)"'\''[:space:>]*' . \
    --exclude-dir=.git 2>/dev/null | sort -u || true)
  [[ "$bad" -eq 0 ]] || fail 'plaintext http:// URLs to BRMSTE/GSI domains are forbidden (HTTPS/HSTS required)'
  ok "HTTPS-only: no plaintext http:// BRMSTE/GSI URLs found"
}

scan_gsi_trademark() {
  # If any file references GSI as a product, the GSI trademark line must be present somewhere
  local gsi_refs
  gsi_refs=$(grep -rl '\bGSI\b' . --exclude-dir=.git --include="*.md" 2>/dev/null | wc -l || true)
  if [[ "$gsi_refs" -gt 0 ]]; then
    local tm_ok=0
    grep -rl 'Global Substrate Infrastructure' . --exclude-dir=.git --include="*.md" &>/dev/null && tm_ok=1
    if [[ "$tm_ok" -eq 0 ]]; then
      warn "GSI referenced in $gsi_refs files but 'Global Substrate Infrastructure' full form not found — add to BRAND.md or TRADEMARK.md"
    else
      ok "GSI trademark: full form 'Global Substrate Infrastructure' present"
    fi
  fi
}

require_hsts_docs() {
  # Verify that HTTPS/HSTS requirements are documented
  local hsts_ok=0
  grep -rl 'Strict-Transport-Security' . --exclude-dir=.git --include="*.md" &>/dev/null && hsts_ok=1
  [[ "$hsts_ok" -eq 1 ]] || fail 'HSTS (Strict-Transport-Security) documentation required — see SECURITY.md and whitepapers/'
  ok "HSTS documentation: Strict-Transport-Security present in docs"
}

scan_readme_identity() {
  if [[ -f README.md ]]; then
    grep -qi 'BRMSTE' README.md || fail 'README.md must reference BRMSTE'
    ok "README.md: BRMSTE identity present"
  fi
}

# ── Lane dispatch ────────────────────────────────────────────────────────────

case "$LANE" in
  human_open)
    require_patent_notice
    require_trademark_notice
    scan_readme_identity
    scan_logo_urls
    scan_http_plaintext
    scan_gsi_trademark
    require_hsts_docs
    ;;
  fort_knox_private|*)
    require_patent_notice
    require_trademark_notice
    scan_readme_identity
    scan_logo_urls
    scan_http_plaintext
    scan_gsi_trademark
    require_hsts_docs
    if [[ -f .github/workflows/brmste-brand-patent-gate.yml ]]; then
      grep -q 'brmste-brand-patent-gate-reusable' .github/workflows/brmste-brand-patent-gate.yml \
        || fail 'Fort Knox repo must call brmste-brand-patent-gate-reusable workflow'
      ok "Fort Knox caller workflow: present and references reusable"
    else
      fail 'missing .github/workflows/brmste-brand-patent-gate.yml caller workflow'
    fi
    ;;
esac

ok "lane=$LANE repo=$(basename "$ROOT") brand+patent+GSI+HSTS strict gate PASSED"
