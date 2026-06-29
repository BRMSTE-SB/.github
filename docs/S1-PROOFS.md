# S-1 Proof Bundle

Public proof downloads for all **3 IPO lanes** on the BRMSTE human-open register.

## Important

| Issuer | Public S-1 on EDGAR? | What this bundle contains |
|--------|----------------------|---------------------------|
| **Anthropic PBC** | No (confidential draft) | Rule 135 announcement from [anthropic.com](https://www.anthropic.com/news/confidential-draft-s1-sec) |
| **OpenAI, Inc.** | No (confidential draft) | Rule 135 announcement from [openai.com](https://openai.com/index/openai-submits-confidential-s-1/) |
| **xAI / Grok** | Via **SpaceX consolidated S-1/A** | Public SEC EDGAR filing + mirror PDF (xAI segment) |

Confidential draft Form S-1 documents are **not publicly downloadable** until the issuer files a public registration statement.

## Download

```bash
bash scripts/download-s1-proofs.sh
```

### On your Mac (403-safe)

Paste in **Terminal** — uses `github.com/raw` first, then jsDelivr, then git sparse clone:

```bash
curl -fsSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) BRMSTE-SB/1.0" \
  "https://github.com/BRMSTE-SB/.github/raw/BRMSTE-CURSORanthropic-ipo-full-sweep-6a86/scripts/download-s1-proofs-on-mac.sh" | bash
```

Output: `~/Downloads/brmste-s1-proofs/s-1/` (opens in Finder when done).

**If everything is 403**, clone the repo:

```bash
git clone -b BRMSTE-CURSORanthropic-ipo-full-sweep-6a86 --depth 1 \
  https://github.com/BRMSTE-SB/.github.git ~/Downloads/brmste-s1-proofs/repo
cp -R ~/Downloads/brmste-s1-proofs/repo/data/proofs/s-1 ~/Downloads/brmste-s1-proofs/s-1
open ~/Downloads/brmste-s1-proofs/s-1
```

## Bundle layout

```
data/proofs/s-1/
├── manifest.json              # Index + sha256 checksums
├── anthropic/
│   ├── proof.json
│   ├── rule-135-announcement.html
│   ├── rule-135-announcement.txt
│   └── brmste-register.json
├── openai/
│   ├── proof.json
│   ├── rule-135-announcement.txt
│   └── brmste-register.json
└── xai-spacex-consolidated/
    ├── proof.json
    ├── spacex-s1a-edgar.htm
    ├── spacex-s1a-mirror.pdf
    ├── xai-segment-extract.txt
    └── brmste-register.json
```

## Registers

- [data/anthropic-ipo.json](../../anthropic-ipo.json)
- [data/openai-ipo.json](../../openai-ipo.json)
- [data/xai-ipo.json](../../xai-ipo.json)

BRMSTE LTD · Companies House 15310393 · GB2607860
