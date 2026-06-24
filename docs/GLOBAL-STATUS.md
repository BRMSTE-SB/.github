# BRMSTE-SB `.github` · Full Global status

Last verified: 2026-06-24

## OPEN ALL (verified)

Every repository under **github.com/BRMSTE-SB** is **public**.

```bash
bash scripts/verify-open-all.sh
```

Manifest: [data/open-all.json](../data/open-all.json) · [docs/OPEN-ALL.md](./OPEN-ALL.md)

## FULL OPEN TUNE (verified)

Master open-lane tune: [data/brmste-github-full-tune.json](../data/brmste-github-full-tune.json) · [docs/FULL-OPEN-TUNE.md](./FULL-OPEN-TUNE.md)

```bash
bash scripts/verify-full-open-tune.sh
```

## Visibility (this repo)

| Check | Status |
|-------|--------|
| `private` | `false` |
| `visibility` | `public` |
| Public API reachable | Yes — unauthenticated `GET /repos/BRMSTE-SB/.github` returns 200 |
| URL | https://github.com/BRMSTE-SB/.github |

Run local verification:

```bash
bash scripts/verify-global-open.sh
```

## Repository name (not renamed)

GitHub requires the org profile repository to stay named **`.github`**. Renaming would break:

- Organization profile from `profile/README.md`
- Default community health file inheritance
- Reusable workflow path `BRMSTE-SB/.github/.github/workflows/...`

**Public brand:** BRMSTE-SB · **Full Global** governance (this document and org profile README).

## GitHub settings metadata (admin)

The integration token cannot PATCH repository metadata. Org admin should align Settings → General with:

| Field | Target value |
|-------|----------------|
| Description | `BRMSTE-SB Full Global governance — public org profile, brand gate, GB2607860. Made in Global Blocks.` |
| Website | `https://brmste.com` |
| Topics | `brmste`, `global-blocks`, `governance`, `open-source`, `patent-notice` |

```bash
bash scripts/set-github-global-metadata.sh
```

Or: [github.com/BRMSTE-SB/.github/settings](https://github.com/BRMSTE-SB/.github/settings)

## Lanes

| Lane | This repo |
|------|-----------|
| Fort Knox (private production) | Not this repo — production IP stays private |
| Human open / Full Global | **This repo** — patent-enforced public governance · AI, MCP, cloud **full free** |
