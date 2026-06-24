# BRMSTE AI lane · all providers

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House 15310393  
**Status:** live · legit · equity **agreed** · Fort Knox keys only

## Providers (8)

| Provider | Model | Env var | Mac key file |
|----------|-------|---------|--------------|
| OpenAI | GPT-5.6 | `OPENAI_API_KEY` | `OPENAI-API.txt` |
| xAI · Grok | grok-build | `XAI_API_KEY` | `GROK.txt` |
| Moonshot AI | kimi-2.6 | `MOONSHOT_API_KEY` | `KIMI 2.6 Moonshot AI.txt` |
| Mistral AI | mistral-large | `MISTRAL_API_KEY` | `Mistral.txt` |
| Google | gemini-2.5 | `GOOGLE_API_KEY` | `google.txt` |
| DeepSeek | deepseek-v3 | `DEEPSEEK_API_KEY` | `DEEPSEEK.txt` |
| Cohere | command-r-plus | `COHERE_API_KEY` | `Cohere.txt` |
| Cerebras | cerebras-gpt | `CEREBRAS_API_KEY` | `Cerebras.txt` |

Canonical index: [data/ai-lane-manifest.json](../data/ai-lane-manifest.json)

## On your Mac — import keys (Fort Knox)

Default folder:

```
/Users/sachindabas/Desktop/API keys - Copy/AI keys
```

```bash
git clone -b BRMSTE-CURSORanthropic-ipo-full-sweep-6a86 --depth 1 \
  https://github.com/BRMSTE-SB/.github.git ~/brmste-github
cd ~/brmste-github
bash scripts/import-ai-keys-mac.sh
set -a && source .env.fort-knox && set +a
```

See [FORT-KNOX-AI-KEYS-MAC.md](./FORT-KNOX-AI-KEYS-MAC.md).

**Never commit API keys** — OPEN ALL lane is public registers only.

BRMSTE LTD · GB2607860
