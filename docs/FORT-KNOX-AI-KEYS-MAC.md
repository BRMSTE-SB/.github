# Fort Knox AI keys on Mac

API keys stay **local only** — never in public GitHub.

## Your key folder

```
/Users/sachindabas/Desktop/API keys - Copy/AI keys/
├── OPENAI-API.txt
├── GROK.txt
├── KIMI 2.6 Moonshot AI.txt
├── Mistral.txt
├── google.txt
├── DEEPSEEK.txt
├── Cohere.txt
└── Cerebras.txt
```

## Import into Fort Knox

From a clone of [BRMSTE-SB/.github](https://github.com/BRMSTE-SB/.github):

```bash
bash scripts/import-ai-keys-mac.sh
```

Custom folder:

```bash
bash scripts/import-ai-keys-mac.sh "/Users/sachindabas/Desktop/API keys - Copy/AI keys"
```

Output: `.env.fort-knox` in the repo root (gitignored).

## Load keys in Terminal

```bash
set -a && source .env.fort-knox && set +a
```

## Security

- `.env.fort-knox` is **never committed**
- Rotate any key that was pasted into chat or committed by mistake
- Public lane = [data/ai-lane-manifest.json](../data/ai-lane-manifest.json) only

BRMSTE LTD · Companies House 15310393
