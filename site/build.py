#!/usr/bin/env python3
"""Render BRMSTE whitepapers (repo-root ``whitepapers/*.md``) into styled HTML
pages under ``site/public/whitepapers/``.

Run from anywhere:

    pip install -r site/requirements.txt
    python3 site/build.py

The landing page (``site/public/index.html``) and assets are authored directly;
this build step only (re)generates the whitepaper document pages so they stay in
sync with the canonical Markdown sources.
"""
from __future__ import annotations

import pathlib
import re
import sys

try:
    import markdown
except ModuleNotFoundError:
    sys.exit(
        "missing dependency 'markdown'. Install with:\n"
        "    pip install -r site/requirements.txt"
    )

HERE = pathlib.Path(__file__).resolve().parent
REPO_ROOT = HERE.parent
SRC_DIR = REPO_ROOT / "whitepapers"
OUT_DIR = HERE / "public" / "whitepapers"

# Canonical (remote) brand mark used in the Markdown front matter, repointed to
# the local site asset so the published page renders offline / under any path.
REMOTE_LOGO = "https://brmste.com/substrate/glasses/brmste-logo-primary.svg"
LOCAL_LOGO = "../assets/brmste-org-mark.svg"

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{title} · BRMSTE</title>
<meta name="description" content="{desc}" />
<meta name="theme-color" content="#07101f" />
<link rel="icon" type="image/svg+xml" href="../assets/brmste-org-mark.svg" />
<style>{css}</style>
</head>
<body>
<div class="topbar">
  <div class="topbar__wrap">
    <a class="topbar__home" href="../index.html">
      <img src="../assets/brmste-org-mark.svg" alt="" width="28" height="28" />
      <span>BRMSTE<span class="g">·SB</span></span>
    </a>
    <a class="topbar__back" href="../index.html#whitepapers">← All whitepapers</a>
  </div>
</div>
<main class="wrap"><article class="paper">
{body}
</article></main>
</body>
</html>
"""

CSS = """
:root{--navy:#07101f;--navy2:#0c1829;--gold:#d4af37;--gold2:#f5e6b8;--emerald:#10b981;
--ink:#e8eef7;--muted:#9fb0c4;--line:#1c2a3f;}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:linear-gradient(180deg,var(--navy2),var(--navy));color:var(--ink);
font:16px/1.72 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
-webkit-font-smoothing:antialiased}
.topbar{position:sticky;top:0;z-index:20;background:rgba(7,16,31,.82);backdrop-filter:blur(10px);
border-bottom:1px solid var(--line)}
.topbar__wrap{max-width:880px;margin:0 auto;padding:0 24px;height:60px;display:flex;align-items:center;
justify-content:space-between}
.topbar__home{display:flex;align-items:center;gap:10px;color:#fff;font-weight:800;letter-spacing:.04em;text-decoration:none}
.topbar__home .g{color:var(--gold)}
.topbar__back{color:var(--muted);font-weight:600;font-size:14px;text-decoration:none}
.topbar__back:hover{color:#fff}
.wrap{max-width:880px;margin:0 auto;padding:48px 24px 96px}
.paper{background:rgba(10,20,36,.72);border:1px solid var(--line);border-radius:18px;
padding:44px 52px;box-shadow:0 30px 80px rgba(0,0,0,.45)}
img{max-width:100%}
h1{font-size:2.05rem;line-height:1.2;margin:.2em 0 .1em;
background:linear-gradient(100deg,var(--gold),var(--gold2) 45%,var(--emerald));
-webkit-background-clip:text;background-clip:text;color:transparent}
h2{font-size:1.04rem;color:var(--gold2);text-transform:uppercase;letter-spacing:.06em;margin:0 0 .4em}
h2[id]{margin-top:2.2em;font-size:1.35rem;text-transform:none;letter-spacing:0;color:var(--gold);
border-top:1px solid var(--line);padding-top:1.1em}
h3{color:var(--emerald);margin-top:1.6em;font-size:1.08rem}
a{color:var(--gold2);text-decoration:none;border-bottom:1px dotted #5e6f86}
a:hover{border-bottom-style:solid;color:#fff}
hr{border:0;border-top:1px solid var(--line);margin:2em 0}
strong{color:#fff} em{color:var(--muted)}
blockquote{margin:1.4em 0;padding:.6em 1.2em;border-left:3px solid var(--emerald);
background:rgba(16,185,129,.07);border-radius:0 10px 10px 0;color:#cfe7da}
code{background:#0a1424;border:1px solid var(--line);border-radius:5px;padding:.1em .4em;
font:13.5px/1.5 ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--gold2)}
pre{background:#060d18;border:1px solid var(--line);border-radius:12px;padding:18px 20px;overflow:auto}
pre code{background:none;border:0;color:#bcd0ea;padding:0}
table{border-collapse:collapse;width:100%;margin:1.3em 0;font-size:14.5px;
border:1px solid var(--line);border-radius:10px;overflow:hidden}
th{background:rgba(212,175,55,.13);color:var(--gold2);text-align:left;font-weight:700}
th,td{padding:10px 14px;border-bottom:1px solid var(--line);vertical-align:top}
tr:last-child td{border-bottom:0}
td:first-child strong{color:var(--gold2)}
div[align=center]{text-align:center}
div[align=center] img{width:300px;filter:drop-shadow(0 10px 24px rgba(212,175,55,.25))}
@media (max-width:560px){.paper{padding:30px 22px}}
"""


def slug_for(path: pathlib.Path) -> str:
    name = path.stem
    name = re.sub(r"^brmste-", "", name)
    name = re.sub(r"-whitepaper$", "", name)
    return name


def derive_title(md_text: str, fallback: str) -> str:
    for line in md_text.splitlines():
        m = re.match(r"\s*#\s+(.+?)\s*$", line)
        if m:
            return m.group(1).strip()
    return fallback


def main() -> int:
    if not SRC_DIR.is_dir():
        print(f"no whitepapers directory at {SRC_DIR}; nothing to build")
        return 0
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(SRC_DIR.glob("*.md"))
    if not sources:
        print("no whitepaper markdown found; nothing to build")
        return 0

    built = 0
    for src in sources:
        raw = src.read_text(encoding="utf-8")
        raw = raw.replace(REMOTE_LOGO, LOCAL_LOGO)
        body = markdown.markdown(
            raw,
            extensions=["tables", "fenced_code", "sane_lists", "attr_list", "toc"],
            output_format="html5",
        )
        slug = slug_for(src)
        title = derive_title(raw, slug.replace("-", " ").title())
        desc = (
            f"{title} — a BRMSTE LTD technical whitepaper. "
            "Patent GB2607860 · PCT/GB2026/050406."
        )
        html = PAGE.format(title=title, desc=desc, css=CSS, body=body)
        out = OUT_DIR / f"{slug}.html"
        out.write_text(html, encoding="utf-8")
        print(f"built {src.name} -> {out.relative_to(REPO_ROOT)}")
        built += 1

    print(f"done: {built} whitepaper page(s) -> {OUT_DIR.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
