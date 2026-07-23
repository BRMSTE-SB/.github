#!/usr/bin/env bash
# BRMSTE git worker brand + patent gate — strict allowlist for logos and patent copy.
set -euo pipefail

LANE="${1:-fort_knox_private}"
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ROOT"

fail() { echo "BRMSTE-GATE FAIL: $*" >&2; exit 1; }
ok() { echo "BRMSTE-GATE OK: $*"; }

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing required file: $f"
}

require_patent_notice() {
  require_file PATENT-NOTICE.md
  grep -q 'GB2607860' PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must cite GB2607860'
  grep -q 'PCT/GB2026/050406' PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must cite PCT/GB2026/050406'
  grep -qi 'BRMSTE LTD' PATENT-NOTICE.md || fail 'PATENT-NOTICE.md must name BRMSTE LTD'
}

scan_logo_urls() {
  local bad=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    case "$url" in
      https://brmste.com/*|https://brmste.ai/*|https://raw.githubusercontent.com/BRMSTE-SB/*)
        ;;
      *)
        echo "non-canonical logo URL: $url" >&2
        bad=1
        ;;
    esac
  done < <(grep -rhoE 'https://[^)"'\''[:space:>]+\.(svg|png|jpg|jpeg|webp|gif)' . \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=.wrangler \
    --exclude-dir=dist 2>/dev/null | sort -u || true)
  [[ "$bad" -eq 0 ]] || fail 'logo URLs must use canonical BRMSTE hosts (see BRAND.md)'
}

scan_readme_identity() {
  if [[ -f README.md ]]; then
    grep -qi 'BRMSTE' README.md || fail 'README.md must reference BRMSTE'
  fi
}

case "$LANE" in
  human_open)
    require_patent_notice
    scan_readme_identity
    scan_logo_urls
    ;;
  fort_knox_private|*)
    require_patent_notice
    scan_readme_identity
    scan_logo_urls
    if [[ -f .github/workflows/brmste-brand-patent-gate.yml ]]; then
      grep -q 'brmste-brand-patent-gate-reusable' .github/workflows/brmste-brand-patent-gate.yml \
        || fail 'Fort Knox repo must call brmste-brand-patent-gate-reusable workflow'
    else
      fail 'missing .github/workflows/brmste-brand-patent-gate.yml caller workflow'
    fi
    ;;
esac

ok "lane=$LANE repo=$(basename "$ROOT") brand+patent strict"
