# Sarvam AI · Indian language lane

**BRMSTE LTD · Companies House 15310393 · GB2607860**

[Sarvam AI](https://sarvam.ai) provides chat, speech-to-text, text-to-speech, and translation APIs optimized for Indian languages. On the human-open lane it is **free from BRMSTE charges** — **only carbon justice** (see [CARBON-JUSTICE.md](../CARBON-JUSTICE.md)).

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

Official docs: [docs.sarvam.ai](https://docs.sarvam.ai/api-reference-docs/getting-started/quickstart)

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
| Sarvam AI on human-open public repos | **None** |
| Fort Knox production keys / wallet lanes | Live patent enforcement |

Third-party Sarvam usage billing is between you and Sarvam — BRMSTE does not meter the open lane.
