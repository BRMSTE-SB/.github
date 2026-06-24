# Open `.github` to the world

This repository is prepared for **public** visibility. Org admins must flip the GitHub setting once — the Cursor agent token cannot change repository visibility.

## Prerequisites

- GitHub org **admin** (or enterprise admin) for `BRMSTE-SB`
- A personal access token or `gh` login with `admin:org` and `repo` scopes (for API path)

## Option A — GitHub UI (recommended)

1. Open [github.com/BRMSTE-SB/.github/settings](https://github.com/BRMSTE-SB/.github/settings)
2. Scroll to **Danger Zone**
3. Click **Change visibility** → **Make public**
4. Confirm the repository name

## Option B — GitHub CLI

```bash
gh auth login   # org admin account
gh api repos/BRMSTE-SB/.github -X PATCH -f visibility=public -f private=false
```

## Option C — curl

```bash
export GH_TOKEN="<org-admin-pat-with-repo-scope>"
curl -s -X PATCH \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/BRMSTE-SB/.github \
  -d '{"visibility":"public","private":false}'
```

## Verify

```bash
gh repo view BRMSTE-SB/.github --json visibility,url
curl -s https://api.github.com/repos/BRMSTE-SB/.github | jq '.private, .visibility'
```

Expected: `false` and `public`.

## After going public

- Organization profile renders from `profile/README.md`
- Reusable workflow `brmste-brand-patent-gate-reusable.yml` is callable from other public repos
- Confirm Actions still run on the default `main` branch workflow

## What must never be added

Even as a public repo, do not commit secrets, API keys, wallet material, or production configuration. See `SECURITY.md`.
