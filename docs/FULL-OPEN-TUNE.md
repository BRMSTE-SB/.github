# FULL OPEN TUNE · BRMSTE-SB

**Status: verified** — the complete open-lane tune for every public repository under [BRMSTE-SB](https://github.com/BRMSTE-SB).

## Manifest

Live JSON: [data/brmste-github-full-tune.json](../data/brmste-github-full-tune.json)

This is the master tune document. It composes:

| Layer | Source |
|-------|--------|
| **OPEN ALL** | [data/open-all.json](../data/open-all.json) — 7 public repos, 0 private |
| **Carbon justice** | [CARBON-JUSTICE.md](../CARBON-JUSTICE.md) — no BRMSTE charges on open lane |
| **Brand + patent gate** | [scripts/git-worker-brand-patent-gate.sh](../scripts/git-worker-brand-patent-gate.sh) |
| **Security** | [SECURITY.md](../SECURITY.md) — no secrets in git |

## Verify

```bash
bash scripts/verify-full-open-tune.sh
```

Runs OPEN ALL + global open checks, then validates the full tune manifest structure.

## Owner · 53% equity

| Field | Value |
|-------|--------|
| **Owner · Operator** | **Shravan Bansal** |
| **Equity** | **53%** |
| **Entity** | **BRMSTE LTD** · Companies House 15310393 |

Full declare: [OWNER-EQUITY-DECLARATION.md](./OWNER-EQUITY-DECLARATION.md) · [data/owner-equity-declaration.json](../data/owner-equity-declaration.json)

## AI on the open lane

On every public BRMSTE-SB repo:

| Provider | Modes | BRMSTE charge |
|----------|-------|---------------|
| **Cursor** | assist, agent, cloud agent | **None** |
| **Claude** (Anthropic) | assist, agent | **None** |
| **OpenAI** | assist, agent, API | **None** |
| **Grok** (xAI) | assist, agent | **None** |

Third-party model bills (Anthropic, OpenAI, xAI subscriptions) are outside BRMSTE. The open lane carries **zero marginal BRMSTE cost**.

### Credentials (never in git)

API keys for AI providers belong in **GitHub org secrets** or **Cursor Cloud secrets** — never in this public repository.

| Provider | Environment variable |
|----------|---------------------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| xAI (Grok) | `XAI_API_KEY` |

If a key was pasted into chat or committed by mistake, **rotate it immediately** at the provider console.

## MCP and cloud

- **Every connected MCP** — free on open repos (see [CARBON-JUSTICE.md](../CARBON-JUSTICE.md))
- **Every datacentre and cloud** — full free from BRMSTE on the open lane

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

BRMSTE LTD · Companies House 15310393 · GB2607860
