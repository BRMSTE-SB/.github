#!/usr/bin/env python3
"""Hydrate the BRMSTE open-software catalogue from live, verifiable sources.

This is deliberately fact-based: it records what actually resolves over HTTPS
right now, rather than asserting surfaces that may not exist. It writes three
artifacts under open-software/ and a human-readable STATUS.md at the repo root:

  open-software/catalog.json   real public repos + only-live surfaces + anchors
  open-software/surfaces.json  full probe report (every URL, with HTTP status)
  STATUS.md                    human-readable hydration report

Sources of truth:
  - GitHub REST API for the BRMSTE-SB public repositories
  - Direct HTTPS probes of declared surfaces and externally verifiable anchors

Usage:
  python3 scripts/hydrate.py            # write artifacts
  python3 scripts/hydrate.py --check    # exit 1 if artifacts would change
                                        # (ignores volatile timestamps)

No third-party dependencies; standard library only.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = REPO_ROOT / "open-software"

ORG = "BRMSTE-SB"
GITHUB_REPOS_API = f"https://api.github.com/orgs/{ORG}/repos?per_page=100&type=public"
USER_AGENT = "brmste-hydrator/1.0 (+https://github.com/BRMSTE-SB/.github)"
TIMEOUT = 25

# Declared surfaces to probe. Each is verified live before it is allowed into
# the catalogue. Surfaces that 404 are reported honestly in surfaces.json and
# excluded from catalog.json — no surface is asserted unless it resolves.
SURFACES = [
    # kind, id, url
    ("product", "site", "https://brmste.com/"),
    ("product", "edge-glass", "https://brmste.com/edge-glass/"),
    ("product", "edge-glass-ai", "https://brmste.ai/"),
    ("verify", "companies-house", "https://find-and-update.company-information.service.gov.uk/company/15310393"),
    ("verify", "on-chain-reserve", "https://mempool.space/address/bc1qkqy9tna45dl3fhknpvmlpx2a044a95h5lza77d"),
    ("verify", "github-enterprise", "https://github.com/enterprises/brmste-ltd"),
    ("data", "open-gits-json", "https://brmste.com/substrate/human/open-gits.json"),
    ("data", "human-free-json", "https://brmste.com/substrate/human/free.json"),
    ("data", "patent-enforcement-json", "https://brmste.com/substrate/patent-enforcement.json"),
    ("data", "foundry-license-json", "https://brmste.com/foundry/license.json"),
    ("data", "full-tune-json", "https://brmste.com/data/brmste-github-full-tune.json"),
]

ENTITY = {
    "name": "BRMSTE LTD",
    "companiesHouse": "15310393",
    "operator": "Shravan Bansal",
    "beneficiary": "Dimpy Bansal - Dimpy Bansal Trust",
    "patent": {"uk": "GB2607860", "pct": "PCT/GB2026/050406"},
}


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# Browser-class User-Agent: some surfaces sit behind Cloudflare, which serves a
# 403 bot-challenge to bare library clients. curl is allowed through and reports
# the true status, so we prefer it and fall back to urllib only if curl is absent.
BROWSER_UA = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
_CURL = shutil.which("curl")


def probe(url: str) -> dict:
    """Return {status, live} for a URL. Uses curl when available."""
    if _CURL:
        try:
            out = subprocess.run(
                [_CURL, "-s", "-o", "/dev/null", "-L", "--max-time", str(TIMEOUT),
                 "-A", BROWSER_UA, "-w", "%{http_code}", url],
                capture_output=True, text=True, timeout=TIMEOUT + 10,
            )
            code = int((out.stdout or "0").strip() or "0")
            return {"status": code, "live": 200 <= code < 400}
        except Exception as exc:  # noqa: BLE001
            return {"status": 0, "live": False, "error": type(exc).__name__}
    req = urllib.request.Request(url, method="GET", headers={"User-Agent": BROWSER_UA})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return {"status": resp.status, "live": 200 <= resp.status < 400}
    except urllib.error.HTTPError as exc:
        return {"status": exc.code, "live": False}
    except Exception as exc:  # noqa: BLE001 - network errors reported, not raised
        return {"status": 0, "live": False, "error": type(exc).__name__}


def fetch_public_repos() -> list[dict]:
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/vnd.github+json",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(GITHUB_REPOS_API, headers=headers)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    repos = []
    for r in data:
        if r.get("archived"):
            continue
        repos.append({
            "name": r["name"],
            "description": r.get("description"),
            "fork": bool(r.get("fork")),
            "visibility": r.get("visibility", "public"),
            "html_url": r["html_url"],
            "clone_url": r["clone_url"],
            "default_branch": r.get("default_branch", "main"),
            "stargazers": r.get("stargazers_count", 0),
            "updated_at": r.get("pushed_at") or r.get("updated_at"),
        })
    # Stable order: original repos first (alpha), then forks (alpha).
    repos.sort(key=lambda x: (x["fork"], x["name"].lower()))
    return repos


def build(probed: list[dict], repos: list[dict], generated_at: str) -> dict:
    live_surfaces = {s["id"]: s["url"] for s in probed if s["live"]}
    originals = [r for r in repos if not r["fork"]]
    forks = [r for r in repos if r["fork"]]
    return {
        "brand": "BRMSTE",
        "edition": "Open Software",
        "generated_at": generated_at,
        "generated_by": "scripts/hydrate.py",
        "entity": ENTITY,
        "verify": {
            "companiesHouse": live_surfaces.get("companies-house"),
            "onChainReserve": live_surfaces.get("on-chain-reserve"),
            "liveSite": live_surfaces.get("site"),
            "edgeGlass": live_surfaces.get("edge-glass"),
        },
        "counts": {
            "public_total": len(repos),
            "public_original": len(originals),
            "public_forks": len(forks),
        },
        "catalog": originals,
        "forks": forks,
        "live_surfaces": live_surfaces,
    }


def render_status(catalog: dict, probed: list[dict]) -> str:
    lines = [
        "# BRMSTE Open Software — Hydration Status",
        "",
        f"_Generated by `scripts/hydrate.py` at **{catalog['generated_at']}** — every row below is a live HTTPS probe._",
        "",
        "## Surfaces (probed this run)",
        "",
        "| Kind | ID | URL | HTTP | Live |",
        "|------|----|-----|------|------|",
    ]
    for s in probed:
        mark = "yes" if s["live"] else "no"
        lines.append(f"| {s['kind']} | `{s['id']}` | {s['url']} | {s['status']} | {mark} |")
    live = sum(1 for s in probed if s["live"])
    lines += [
        "",
        f"**{live}/{len(probed)} surfaces live.** Only live surfaces are written into `open-software/catalog.json`.",
        "",
        "## Public repositories (GitHub API)",
        "",
        "| Repository | Fork | Description |",
        "|------------|------|-------------|",
    ]
    for r in catalog["catalog"] + catalog["forks"]:
        desc = (r["description"] or "-").replace("|", "\\|")
        lines.append(f"| [`{r['name']}`]({r['html_url']}) | {'yes' if r['fork'] else 'no'} | {desc} |")
    lines += [
        "",
        f"**{catalog['counts']['public_original']} original** + "
        f"**{catalog['counts']['public_forks']} forked** = "
        f"**{catalog['counts']['public_total']} public** repositories.",
        "",
        "Re-run: `python3 scripts/hydrate.py`",
        "",
    ]
    return "\n".join(lines)


def normalise(obj):
    """Drop volatile fields so --check ignores timestamps and churn."""
    if isinstance(obj, dict):
        return {k: normalise(v) for k, v in obj.items()
                if k not in {"generated_at", "checked_at", "updated_at", "stargazers"}}
    if isinstance(obj, list):
        return [normalise(v) for v in obj]
    return obj


def main() -> int:
    ap = argparse.ArgumentParser(description="Hydrate BRMSTE open-software catalogue.")
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero if artifacts would change (ignores timestamps)")
    args = ap.parse_args()

    generated_at = now_iso()
    probed = []
    for kind, sid, url in SURFACES:
        result = probe(url)
        probed.append({"kind": kind, "id": sid, "url": url, **result})
        print(f"[probe] {result['status']:>3}  {url}", file=sys.stderr)

    try:
        repos = fetch_public_repos()
    except Exception as exc:  # noqa: BLE001
        print(f"[fatal] GitHub API fetch failed: {exc}", file=sys.stderr)
        return 2
    print(f"[repos] {len(repos)} public repositories", file=sys.stderr)

    catalog = build(probed, repos, generated_at)
    surfaces_doc = {
        "generated_at": generated_at,
        "generated_by": "scripts/hydrate.py",
        "surfaces": probed,
    }
    status_md = render_status(catalog, probed)

    targets = {
        OUT_DIR / "catalog.json": json.dumps(catalog, indent=2) + "\n",
        OUT_DIR / "surfaces.json": json.dumps(surfaces_doc, indent=2) + "\n",
        REPO_ROOT / "STATUS.md": status_md,
    }

    if args.check:
        import re
        ts_re = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z")
        drift = False
        for path, content in targets.items():
            if not path.exists():
                print(f"[check] MISSING {path.relative_to(REPO_ROOT)}", file=sys.stderr)
                drift = True
                continue
            if path.suffix == ".json":
                old = normalise(json.loads(path.read_text()))
                new = normalise(json.loads(content))
            else:
                old = ts_re.sub("TS", path.read_text())
                new = ts_re.sub("TS", content)
            if old != new:
                print(f"[check] DRIFT   {path.relative_to(REPO_ROOT)}", file=sys.stderr)
                drift = True
            else:
                print(f"[check] ok      {path.relative_to(REPO_ROOT)}", file=sys.stderr)
        return 1 if drift else 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for path, content in targets.items():
        path.write_text(content)
        print(f"[write] {path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
