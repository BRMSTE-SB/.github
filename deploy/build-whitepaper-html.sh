#!/usr/bin/env bash
# BRMSTE GSI — build static HTML from Markdown whitepapers
# for embedding into the Cloudflare Worker static/ directory.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
# GSI™ — Global Substrate Infrastructure™
#
# Usage:
#   bash deploy/build-whitepaper-html.sh
#
# Outputs HTML files to deploy/static/ which can be served directly by the Worker
# or by a Cloudflare Pages project.
#
# Requires: pandoc (apt-get install pandoc) or markdown-it (npm i -g markdown-it-cli)
# Falls back to a plain pre-wrapped HTML if no Markdown renderer is found.
#
# CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/deploy/static"
mkdir -p "$OUT"

PATENT_FOOTER='<footer style="margin-top:2rem;padding-top:1rem;border-top:1px solid #1e293b;font-size:.8rem;color:#64748b">
  © BRMSTE LTD · Companies House 15310393 · Patent GB2607860 · PCT/GB2026/050406<br/>
  BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD.<br/>
  CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS
</footer>'

HTML_HEAD='<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <style>
    :root{--gold:#d4af37;--green:#10b981;--dark:#07101f;--text:#e2e8f0}
    body{background:var(--dark);color:var(--text);font-family:system-ui,sans-serif;line-height:1.7;padding:2rem 1rem;max-width:860px;margin:0 auto}
    h1,h2{color:var(--gold)} h3{color:var(--green)}
    a{color:var(--green)} table{width:100%;border-collapse:collapse;margin:1rem 0}
    th{background:#0c1829;color:var(--gold);text-align:left;padding:.5rem .75rem}
    td{padding:.45rem .75rem;border-bottom:1px solid #1e293b}
    code,pre{background:#1e293b;padding:.2rem .4rem;border-radius:4px;font-family:monospace;font-size:.85rem}
    pre{padding:1rem;overflow-x:auto}
  </style>
</head>
<body>'

HTML_FOOT='</body></html>'

render_md() {
  local src="$1" dst="$2" title="$3"
  echo "Building: $src → $dst"

  if command -v pandoc &>/dev/null; then
    pandoc --standalone --to=html5 \
      --metadata title="$title · BRMSTE GSI™" \
      --template=/dev/stdin \
      "$src" -o "$dst" <<TMPL
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>\$title\$</title>
<style>:root{--gold:#d4af37;--green:#10b981;--dark:#07101f;--text:#e2e8f0}body{background:var(--dark);color:var(--text);font-family:system-ui,sans-serif;line-height:1.7;padding:2rem 1rem;max-width:860px;margin:0 auto}h1,h2{color:var(--gold)}h3{color:var(--green)}a{color:var(--green)}table{width:100%;border-collapse:collapse;margin:1rem 0}th{background:#0c1829;color:var(--gold);text-align:left;padding:.5rem .75rem}td{padding:.45rem .75rem;border-bottom:1px solid #1e293b}code,pre{background:#1e293b;padding:.2rem .4rem;border-radius:4px;font-family:monospace;font-size:.85rem}pre{padding:1rem;overflow-x:auto}</style>
</head>
<body>
\$body\$
${PATENT_FOOTER}
</body></html>
TMPL
    echo "  pandoc OK"

  elif command -v md2html &>/dev/null; then
    { echo "$HTML_HEAD"; md2html "$src"; echo "$PATENT_FOOTER$HTML_FOOT"; } > "$dst"
    echo "  md2html OK"

  else
    # Fallback: wrap raw Markdown in a <pre> block
    { echo "${HTML_HEAD}<h1>$title</h1><pre>"; cat "$src"; echo "</pre>${PATENT_FOOTER}${HTML_FOOT}"; } > "$dst"
    echo "  fallback (no Markdown renderer found — install pandoc for full HTML output)"
  fi
}

render_md \
  "$ROOT/whitepapers/brmste-gsi-whitepaper.md" \
  "$OUT/gsi-whitepaper.html" \
  "GSI — Global Substrate Infrastructure™ Technical Whitepaper v1.0"

render_md \
  "$ROOT/whitepapers/brmste-https-hsts-whitepaper.md" \
  "$OUT/https-hsts-whitepaper.html" \
  "BRMSTE GSI — HTTPS & HSTS Enforcement Whitepaper v1.0"

echo ""
echo "Built to: $OUT"
ls -lh "$OUT/"
echo ""
echo "BRMSTE LTD · GB2607860 · GSI™ — whitepapers built successfully."
