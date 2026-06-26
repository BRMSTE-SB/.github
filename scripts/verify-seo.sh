#!/usr/bin/env bash
# Verify Google SEO surface for the BRMSTE edge site.
# Checks canonical tags, robots meta, Open Graph/Twitter cards, JSON-LD
# structured data (Organization + Person "Shravan Bansal"), robots.txt and
# sitemap.xml coverage across every page served by the coming-soon Worker.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT/coming-soon/site"

fail() { echo "SEO FAIL: $*" >&2; exit 1; }
ok() { echo "SEO OK: $*"; }

[[ -d "$SITE" ]] || fail "site directory not found: $SITE"

python3 - "$SITE" <<'PY'
import json, re, sys, pathlib
from xml.etree import ElementTree as ET

site = pathlib.Path(sys.argv[1])
base = "https://brmste.com"

# file -> canonical URL
pages = {
    "index.html": f"{base}/",
    "shravan-bansal.html": f"{base}/shravan-bansal",
    "brand.html": f"{base}/brand",
    "open.html": f"{base}/open",
    "portfolio.html": f"{base}/portfolio",
    "broadcast.html": f"{base}/broadcast",
}

errors = []
LD_RE = re.compile(
    r'<script type="application/ld\+json">(.*?)</script>', re.S
)

def need(cond, msg):
    if not cond:
        errors.append(msg)

org_seen = person_seen = False

for fname, canon in pages.items():
    p = site / fname
    if not p.exists():
        errors.append(f"{fname}: missing file")
        continue
    html = p.read_text(encoding="utf-8")

    need(f'<link rel="canonical" href="{canon}"' in html,
         f"{fname}: missing/incorrect canonical -> {canon}")
    need('name="robots"' in html and "index,follow" in html,
         f"{fname}: missing robots index,follow meta")
    need('property="og:title"' in html, f"{fname}: missing og:title")
    need(f'property="og:url" content="{canon}"' in html,
         f"{fname}: missing/incorrect og:url -> {canon}")
    need('property="og:image"' in html, f"{fname}: missing og:image")
    need('name="twitter:card"' in html, f"{fname}: missing twitter:card")

    blocks = LD_RE.findall(html)
    need(bool(blocks), f"{fname}: no JSON-LD block")
    page_has_org = page_has_person = False
    for raw in blocks:
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as e:
            errors.append(f"{fname}: invalid JSON-LD ({e})")
            continue
        nodes = data.get("@graph", [data]) if isinstance(data, dict) else []
        for node in nodes:
            t = node.get("@type")
            types = t if isinstance(t, list) else [t]
            if "Organization" in types:
                page_has_org = True
                if node.get("name") == "BRMSTE LTD":
                    org_seen = True
            if "Person" in types:
                page_has_person = True
                if node.get("name") == "Shravan Bansal":
                    person_seen = True
    need(page_has_org, f"{fname}: JSON-LD missing Organization node")
    need(page_has_person, f"{fname}: JSON-LD missing Person node")

# Shravan Bansal page must be a ProfilePage about the Person and link worksFor.
op = site / "shravan-bansal.html"
if op.exists():
    html = op.read_text(encoding="utf-8")
    need("ProfilePage" in html, "shravan-bansal.html: missing ProfilePage type")
    need('"worksFor"' in html, "shravan-bansal.html: Person missing worksFor")
    need("<h1>Shravan Bansal</h1>" in html,
         "shravan-bansal.html: missing <h1>Shravan Bansal</h1>")

need(org_seen, "no Organization 'BRMSTE LTD' found in any JSON-LD")
need(person_seen, "no Person 'Shravan Bansal' found in any JSON-LD")

# robots.txt
robots = site / "robots.txt"
if not robots.exists():
    errors.append("robots.txt: missing")
else:
    rtxt = robots.read_text(encoding="utf-8")
    need("User-agent: *" in rtxt, "robots.txt: missing 'User-agent: *'")
    need(f"Sitemap: {base}/sitemap.xml" in rtxt,
         "robots.txt: missing Sitemap directive")

# sitemap.xml
sm = site / "sitemap.xml"
if not sm.exists():
    errors.append("sitemap.xml: missing")
else:
    try:
        tree = ET.fromstring(sm.read_text(encoding="utf-8"))
        ns = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        locs = {e.text.strip() for e in tree.findall(".//s:loc", ns)}
        expected = set(pages.values())
        missing = expected - locs
        extra = locs - expected
        need(not missing, f"sitemap.xml: missing locs {sorted(missing)}")
        need(not extra, f"sitemap.xml: unexpected locs {sorted(extra)}")
    except ET.ParseError as e:
        errors.append(f"sitemap.xml: invalid XML ({e})")

if errors:
    print("\n".join(f"  - {e}" for e in errors), file=sys.stderr)
    raise SystemExit(f"{len(errors)} SEO problem(s) found")

print(f"pages={len(pages)} canonical=ok robots=ok og=ok twitter=ok jsonld=ok")
print("structured-data: Organization=BRMSTE LTD · Person=Shravan Bansal")
print("robots.txt + sitemap.xml aligned")
PY

ok "Google SEO surface verified — Shravan Bansal of BRMSTE LTD"
