# AGENTS.md

## Cursor Cloud specific instructions

This is the **BRMSTE-SB `.github`** governance/profile repository. It is **not a buildable application** — there is no package manager manifest, no source app, and no server to run. Do not look for `npm`/`pip`/`go` projects here.

### What this repo contains
- `profile/README.md` — the org profile README rendered on GitHub.
- `BRAND.md`, `PATENT-NOTICE.md`, `PATENT-NOTICE-TEMPLATE.md`, `SECURITY.md` — governance/brand/patent copy.
- `assets/brmste-org-mark.svg` — canonical org logo asset.
- `scripts/git-worker-brand-patent-gate.sh` — the runnable core: the strict brand + patent gate.
- `.github/workflows/` — a caller workflow and a `workflow_call` reusable workflow that run the gate on push/PR to `main`.

### Running the core (the brand + patent gate)
The gate is the only executable surface. Run it locally exactly as CI does:

```bash
bash scripts/git-worker-brand-patent-gate.sh fort_knox_private   # default lane
bash scripts/git-worker-brand-patent-gate.sh human_open          # public-lane checks
```

Exit `0` = pass, non-zero = fail (prints `BRMSTE-GATE FAIL: ...`). It checks for `PATENT-NOTICE.md` (must cite `GB2607860` and `PCT/GB2026/050406` and name `BRMSTE LTD`), that `README.md` references BRMSTE, scans logo URLs against canonical hosts, and (Fort Knox lane) requires the caller workflow file.

### Gotchas
- The gate runs `cd "${GITHUB_WORKSPACE:-$(pwd)}"`. To run it against a copy/sandbox, set `GITHUB_WORKSPACE` to that directory, otherwise it operates on the repo root.
- The reusable workflow checks out `BRMSTE-SB/.github` into `_brmste-governance/` and runs the script from there — i.e. CI always uses the gate from the `main` branch of this repo, not the PR branch.
- There are no dependencies to install. `bash` (and `python3` for optional YAML parsing) are already present on the base image; the startup update script is intentionally a no-op.
- Lint/test for this repo means: `bash -n scripts/git-worker-brand-patent-gate.sh` (syntax) plus running the gate itself. There is no separate test framework.
