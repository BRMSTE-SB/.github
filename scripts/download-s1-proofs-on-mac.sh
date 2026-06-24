#!/usr/bin/env bash
# Download all 3 S-1 proofs to this Mac — 403-safe fallbacks (GitHub raw + git sparse clone).
#
# One-liner (paste in Terminal on Mac):
#   curl -fsSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) BRMSTE-SB/1.0" \
#     "https://github.com/BRMSTE-SB/.github/raw/BRMSTE-CURSORanthropic-ipo-full-sweep-6a86/scripts/download-s1-proofs-on-mac.sh" | bash
#
# Custom folder:
#   ... | bash -s -- ~/Desktop/brmste-s1-proofs
set -uo pipefail

BRANCH="${BRMSTE_BRANCH:-BRMSTE-CURSORanthropic-ipo-full-sweep-6a86}"
REPO="BRMSTE-SB/.github"
OUT="${1:-${HOME}/Downloads/brmste-s1-proofs}"

# Browser UA — many networks block bare curl / bot User-Agents (403).
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 BRMSTE-SB/1.0"
UA_SEC="BRMSTE LTD (Companies House 15310393) contact@brmste.com"

mkdir -p "$OUT"
cd "$OUT"

github_urls() {
  local relpath="$1"
  printf '%s\n' \
    "https://github.com/${REPO}/raw/${BRANCH}/${relpath}" \
    "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${relpath}" \
    "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${relpath}"
}

curl_try_urls() {
  local dest="$1"
  shift
  local url code
  for url in "$@"; do
    code="$(curl -sSL -A "$UA" -L -w "%{http_code}" -o "$dest" "$url" 2>/dev/null || echo "000")"
    if [[ "$code" == "200" ]] && [[ -s "$dest" ]]; then
      echo "   ok $code ${url%%\?*}"
      return 0
    fi
    echo "   skip $code ${url%%\?*}"
    rm -f "$dest"
  done
  return 1
}

git_sparse_fetch() {
  local relpath="$1"
  local dest="$2"
  local tmp="${OUT}/.brmste-github-sparse"
  rm -rf "$tmp"
  if ! command -v git >/dev/null 2>&1; then
    return 1
  fi
  echo "   git sparse clone fallback…"
  if ! GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$BRANCH" --single-branch \
    --filter=blob:none --sparse "https://github.com/${REPO}.git" "$tmp" 2>/dev/null; then
    if ! GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$BRANCH" --single-branch \
      "https://github.com/${REPO}.git" "$tmp" 2>/dev/null; then
      rm -rf "$tmp"
      return 1
    fi
  fi
  (
    cd "$tmp"
    git sparse-checkout set "$relpath" 2>/dev/null || true
    git checkout "$BRANCH" 2>/dev/null || true
  )
  if [[ -f "$tmp/$relpath" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$tmp/$relpath" "$dest"
    rm -rf "$tmp"
    echo "   ok git $relpath"
    return 0
  fi
  rm -rf "$tmp"
  return 1
}

fetch_file() {
  local relpath="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  echo "-> $relpath"
  if curl_try_urls "$dest" $(github_urls "$relpath"); then
    return 0
  fi
  if git_sparse_fetch "$relpath" "$dest"; then
    return 0
  fi
  echo "FAILED: could not download $relpath (403/network). Try: git clone -b $BRANCH https://github.com/${REPO}.git"
  return 1
}

echo "==> BRMSTE S-1 proofs → $OUT"
echo "    Branch: $BRANCH"

FAILED=0

if fetch_file "data/proofs/s-1-proofs-bundle.tar.gz" "s-1-proofs-bundle.tar.gz"; then
  echo "-> Extract tarball"
  tar -xzf s-1-proofs-bundle.tar.gz
else
  echo "-> Tarball failed — downloading files individually"
  mkdir -p s-1/anthropic s-1/openai s-1/xai-spacex-consolidated
  for pair in \
    "data/proofs/s-1/manifest.json:s-1/manifest.json" \
    "data/proofs/s-1/anthropic/proof.json:s-1/anthropic/proof.json" \
    "data/proofs/s-1/anthropic/rule-135-announcement.html:s-1/anthropic/rule-135-announcement.html" \
    "data/proofs/s-1/anthropic/rule-135-announcement.txt:s-1/anthropic/rule-135-announcement.txt" \
    "data/proofs/s-1/anthropic/brmste-register.json:s-1/anthropic/brmste-register.json" \
    "data/proofs/s-1/openai/proof.json:s-1/openai/proof.json" \
    "data/proofs/s-1/openai/rule-135-announcement.html:s-1/openai/rule-135-announcement.html" \
    "data/proofs/s-1/openai/rule-135-announcement.txt:s-1/openai/rule-135-announcement.txt" \
    "data/proofs/s-1/openai/brmste-register.json:s-1/openai/brmste-register.json" \
    "data/proofs/s-1/xai-spacex-consolidated/proof.json:s-1/xai-spacex-consolidated/proof.json" \
    "data/proofs/s-1/xai-spacex-consolidated/spacex-s1a-edgar.htm:s-1/xai-spacex-consolidated/spacex-s1a-edgar.htm" \
    "data/proofs/s-1/xai-spacex-consolidated/spacex-s1a-mirror.pdf:s-1/xai-spacex-consolidated/spacex-s1a-mirror.pdf" \
    "data/proofs/s-1/xai-spacex-consolidated/xai-segment-extract.txt:s-1/xai-spacex-consolidated/xai-segment-extract.txt" \
    "data/proofs/s-1/xai-spacex-consolidated/brmste-register.json:s-1/xai-spacex-consolidated/brmste-register.json"; do
  rel="${pair%%:*}"
  dest="${pair##*:}"
  if ! fetch_file "$rel" "$dest"; then
    FAILED=$((FAILED + 1))
  fi
  sleep 0.3
  done
fi

# Optional live refresh — never fail the run (bundle already has copies)
echo "-> Optional live issuer / SEC refresh (403-safe)"
mkdir -p s-1/anthropic s-1/openai s-1/xai-spacex-consolidated
curl -sSL -A "$UA" -L -o s-1/anthropic/rule-135-announcement.live.html \
  "https://www.anthropic.com/news/confidential-draft-s1-sec" 2>/dev/null || true
curl -sSL -A "$UA" -L -o s-1/openai/rule-135-announcement.live.html \
  "https://openai.com/index/openai-submits-confidential-s-1/" 2>/dev/null || true
sleep 2
curl -sSL -A "$UA_SEC" -L -o s-1/xai-spacex-consolidated/spacex-s1a-edgar.live.htm \
  "https://www.sec.gov/Archives/edgar/data/1181412/000162828026040610/spacexfwp.htm" 2>/dev/null || true

if [[ ! -f s-1/manifest.json ]] && [[ -f s-1/anthropic/proof.json ]]; then
  echo "   (manifest missing — proofs still in s-1/)"
fi

echo ""
if [[ -d s-1/anthropic ]] && [[ -d s-1/openai ]] && [[ -d s-1/xai-spacex-consolidated ]]; then
  echo "DONE — S-1 proofs on this Mac:"
  echo "  $OUT/s-1/"
  command -v open >/dev/null && open "$OUT/s-1"
  find "$OUT/s-1" -type f | head -20
  exit 0
fi

echo "ERROR — download incomplete. Git fallback:"
echo "  git clone -b $BRANCH --depth 1 https://github.com/${REPO}.git \"$OUT/repo\""
echo "  cp -R \"$OUT/repo/data/proofs/s-1\" \"$OUT/s-1\""
exit 1
