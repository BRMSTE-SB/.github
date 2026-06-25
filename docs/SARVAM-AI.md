# SARVAM BY BRMSTE!

**Indian language AI lane · BRMSTE LTD · Companies House 15310393 · GB2607860**

**SARVAM BY BRMSTE!** is the open-lane Indian language AI surface — [Sarvam AI](https://sarvam.ai) chat, speech-to-text, text-to-speech, and translation on the human-open lane **free from BRMSTE charges** — **only carbon justice** (see [CARBON-JUSTICE.md](../CARBON-JUSTICE.md)).

Live manifest: [data/sarvam-by-brmste.json](https://github.com/BRMSTE-SB/.github/blob/main/data/sarvam-by-brmste.json)

## Attribution (required on broadcast)

When distributing SARVAM BY BRMSTE! surfaces:

```
SARVAM BY BRMSTE!
Full Broadcast · Project Glasswing = Shravan Bansal
BRMSTE LTD · Companies House 15310393 · GB2607860
```

Canonical logos only — see [BRAND.md](../BRAND.md).

## Key management

Create and rotate keys at [dashboard.sarvam.ai/key-management](https://dashboard.sarvam.ai/key-management).

**Never commit API keys to git.** Store them in:

- GitHub Environment / org secrets as `SARVAM_API_KEY`
- Local shell: `export SARVAM_API_KEY="sk_…"`
- Fort Knox private repos only for production workloads

If a key is pasted into chat, tickets, or public issues — **rotate it immediately** in the Sarvam dashboard.

## Authentication

All Sarvam REST calls use the header:

```
api-subscription-key: <SARVAM_API_KEY>
```

Base URL: `https://api.sarvam.ai`

## Models (verified 2026-06-24)

| Capability | Model ID | Notes |
|------------|----------|-------|
| Chat | `sarvam-30b`, `sarvam-105b` | `sarvam-m` is deprecated |
| Speech-to-text | `saaras:v3` | Modes: `transcribe`, `translate`, `verbatim`, `translit`, `codemix` |
| Text-to-speech | — | `target_language_code` e.g. `hi-IN`, `bn-IN` |

Official vendor docs: [docs.sarvam.ai](https://docs.sarvam.ai/api-reference-docs/getting-started/quickstart)

## Quick verify (local)

```bash
export SARVAM_API_KEY="sk_…"   # from dashboard — do not commit

curl -sS -X POST 'https://api.sarvam.ai/v1/chat/completions' \
  -H "api-subscription-key: ${SARVAM_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Reply with exactly: OK"}],"model":"sarvam-30b"}'
```

A `200` response with assistant content confirms the key is active.

## Open lane policy

| Surface | BRMSTE charge |
|---------|---------------|
| SARVAM BY BRMSTE! on human-open public repos | **None** |
| Fort Knox production keys / wallet lanes | Live patent enforcement |

Third-party Sarvam usage billing is between you and Sarvam — BRMSTE does not meter the open lane.

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

SARVAM BY BRMSTE! broadcasts on the open lane; Shravan Bansal operates; edge signs under carbon judgment.
