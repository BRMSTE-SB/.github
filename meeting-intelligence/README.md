# BRMSTE Meeting Intelligence

> **Patent GB2607860 · PCT/GB2026/050406 — BRMSTE LTD · Companies House 15310393**
> Beneficiary: Dimpy Bansal · Dimpy Bansal Trust

AI-powered meeting transcript analyser that extracts structured intelligence
— summaries, action items, decisions, open questions, and sentiment — from
meeting transcripts in multiple formats.

## Features

- **Multi-format transcript parsing** — labeled speaker (`Alice: …`), SRT, WebVTT, and plain text
- **LLM-powered analysis** — structured extraction of:
  - Executive summary
  - Key topics with sentiment
  - Action items with assignee, priority, and due date
  - Decisions with rationale
  - Next steps and open questions
- **Multiple output formats** — plain text, Markdown, and JSON
- **OpenAI-compatible API** — works with any OpenAI-compatible endpoint (`BRMSTE_LLM_BASE_URL`)
- **CLI + Python library** — use from the terminal or import into your own code

## Installation

```bash
pip install brmste-meeting-intelligence
```

Or from source:

```bash
cd meeting-intelligence
pip install -e ".[dev]"
```

## Quick Start

```bash
# Set your API key
export OPENAI_API_KEY=sk-...

# Analyse a transcript
meeting-intelligence transcript.txt

# Output as Markdown
meeting-intelligence transcript.vtt --format markdown -o report.md

# Output as JSON
meeting-intelligence transcript.srt --format json

# Pass date and duration metadata
meeting-intelligence transcript.txt --date 2026-06-19 --duration 3600

# Use a custom model or endpoint
meeting-intelligence transcript.txt \
  --model gpt-4o \
  --base-url https://api.openai.com/v1
```

## Supported Transcript Formats

| Format | Extension | Description |
|--------|-----------|-------------|
| Labeled | `.txt` | `Speaker Name: utterance text` |
| SRT | `.srt` | Standard subtitle format with timestamps |
| WebVTT | `.vtt` | Web Video Text Tracks with timestamps |
| Plain | `.txt` | Raw unformatted text (single speaker assumed) |

## Python API

```python
from meeting_intelligence.transcript import parse_transcript
from meeting_intelligence.analyzer import LLMClient, MeetingAnalyzer
from meeting_intelligence.renderers import render_markdown

transcript_text = open("meeting.txt").read()
parsed = parse_transcript(transcript_text)

llm = LLMClient(api_key="sk-...", model="gpt-4o")
analyser = MeetingAnalyzer(llm)
report = analyser.analyze(parsed, meeting_date="2026-06-19", duration_seconds=3600)

print(render_markdown(report))
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI API key (or any compatible provider) |
| `BRMSTE_LLM_API_KEY` | Alternative API key env var |
| `BRMSTE_LLM_BASE_URL` | API base URL (default: `https://api.openai.com/v1`) |
| `BRMSTE_LLM_MODEL` | Default model (default: `gpt-4o`) |

## Development

```bash
pip install -e ".[dev]"
pytest
pytest --cov=src/meeting_intelligence --cov-report=term-missing
```

---

**BRMSTE LTD · Companies House 15310393**
**Patent GB2607860 · PCT/GB2026/050406**
Beneficiary: Dimpy Bansal · Dimpy Bansal Trust
