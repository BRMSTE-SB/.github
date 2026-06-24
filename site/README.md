# BRMSTE site

The public BRMSTE launch site — a self-contained static site for **BRMSTE LTD ·
Global Substrate Infrastructure™**. No build framework, no external runtime
assets: every logo, style, and script is served from this repository so the site
renders offline and passes the `brmste-brand-patent-gate`.

```
site/
├── public/                     # deployable web root (static)
│   ├── index.html              # BRMSTE landing page
│   ├── assets/
│   │   ├── brmste-org-mark.svg # local canonical brand mark
│   │   ├── styles.css          # theme + layout
│   │   └── app.js              # progressive enhancement only
│   └── whitepapers/
│       └── *.html              # generated from /whitepapers/*.md by build.py
├── build.py                    # renders whitepaper Markdown -> public/whitepapers/*.html
└── requirements.txt            # build-only dependency (markdown)
```

## Build

The landing page is authored directly. `build.py` (re)generates the whitepaper
document pages from the canonical Markdown in the repo-root `whitepapers/`
directory:

```bash
pip install -r site/requirements.txt
python3 site/build.py
```

## Run locally (launch)

```bash
python3 -m http.server 8080 --directory site/public
# open http://localhost:8080/
```

## Go online (deploy)

Deployment uses **GitHub Pages via GitHub Actions** —
`.github/workflows/deploy-site-pages.yml`. On every push to `main` that touches
`site/**` or `whitepapers/**`, the workflow runs the brand + patent gate, renders
the whitepapers, and publishes `site/public`.

**One-time enablement:** in repository **Settings → Pages**, set **Source** to
**GitHub Actions**. After that the site goes live automatically; the deploy job
prints the published `page_url`.

The site uses only relative paths, so it also deploys cleanly under a sub-path
(e.g. project Pages) or behind the existing Cloudflare HTTPS/HSTS edge used for
`brmste.com`.

## Constraints honoured

- **Local assets only** — no third-party CDN logos; brand marks are served from
  `assets/` (canonical mark copied from the org `.github` repo).
- **HTTPS-only links** for off-site surfaces.
- **Patent + trademark copy** present: GB2607860 · PCT/GB2026/050406 · BRMSTE LTD.
