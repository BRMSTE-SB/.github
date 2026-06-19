"""
LLM-powered meeting analysis engine for BRMSTE Meeting Intelligence.
Patent: GB2607860 · PCT/GB2026/050406 — BRMSTE LTD
"""

from __future__ import annotations

import json
import logging
import os
import textwrap
from typing import Any, Dict, List, Optional

from .models import (
    ActionItem,
    Decision,
    MeetingIntelligence,
    Priority,
    SentimentLabel,
    Speaker,
    Topic,
)
from .transcript import ParsedTranscript, compute_speaker_stats

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Prompt templates
# ---------------------------------------------------------------------------

_SYSTEM_PROMPT = textwrap.dedent("""
    You are BRMSTE Meeting Intelligence, an expert analyst that extracts
    structured insights from meeting transcripts.

    BRMSTE LTD · GB2607860 · PCT/GB2026/050406
    Beneficiary: Dimpy Bansal · Dimpy Bansal Trust

    Always respond with valid JSON matching the schema provided.
    Be concise, factual, and attribute quotes accurately to speakers.
""").strip()

_ANALYSIS_PROMPT_TEMPLATE = textwrap.dedent("""
    Analyse the following meeting transcript and return a JSON object with
    this exact schema:

    {{
      "title": "<short meeting title inferred from content>",
      "executive_summary": "<2-4 sentence summary of the whole meeting>",
      "key_topics": [
        {{
          "title": "<topic title>",
          "summary": "<1-2 sentence summary>",
          "sentiment": "positive|neutral|negative",
          "keywords": ["<keyword>", ...]
        }}
      ],
      "action_items": [
        {{
          "description": "<what needs to be done>",
          "assignee": "<person name or null>",
          "due_date": "<date string or null>",
          "priority": "high|medium|low",
          "source_quote": "<verbatim quote that generated this item or null>"
        }}
      ],
      "decisions": [
        {{
          "description": "<what was decided>",
          "made_by": "<person or group or null>",
          "rationale": "<brief rationale or null>",
          "source_quote": "<verbatim quote or null>"
        }}
      ],
      "next_steps": ["<step>", ...],
      "open_questions": ["<question>", ...],
      "sentiment_overall": "positive|neutral|negative",
      "follow_up_meeting_recommended": true|false
    }}

    Meeting transcript:
    ---
    {transcript}
    ---
""").strip()


# ---------------------------------------------------------------------------
# Provider-agnostic LLM client wrapper
# ---------------------------------------------------------------------------

class LLMClient:
    """Thin wrapper supporting OpenAI-compatible chat completion APIs."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "gpt-4o",
        base_url: Optional[str] = None,
        max_tokens: int = 4096,
        temperature: float = 0.2,
    ) -> None:
        self.model = model
        self.max_tokens = max_tokens
        self.temperature = temperature
        self._api_key = api_key or os.environ.get("OPENAI_API_KEY") or os.environ.get("BRMSTE_LLM_API_KEY", "")
        self._base_url = base_url or os.environ.get("BRMSTE_LLM_BASE_URL") or "https://api.openai.com/v1"

        if not self._api_key:
            raise ValueError(
                "No LLM API key found. Set OPENAI_API_KEY or BRMSTE_LLM_API_KEY environment variable."
            )

    def complete(self, system: str, user: str) -> str:
        """Send a chat completion request and return the assistant message text."""
        try:
            import httpx
        except ImportError as exc:
            raise ImportError("httpx is required: pip install httpx") from exc

        payload = {
            "model": self.model,
            "max_tokens": self.max_tokens,
            "temperature": self.temperature,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        url = self._base_url.rstrip("/") + "/chat/completions"

        logger.debug("POST %s model=%s", url, self.model)
        with httpx.Client(timeout=120) as client:
            response = client.post(url, json=payload, headers=headers)

        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"]


# ---------------------------------------------------------------------------
# Main analyser
# ---------------------------------------------------------------------------

class MeetingAnalyzer:
    """Orchestrates transcript parsing, LLM analysis, and report assembly."""

    def __init__(self, llm: LLMClient) -> None:
        self.llm = llm

    def analyze(
        self,
        parsed: ParsedTranscript,
        meeting_date: Optional[str] = None,
        duration_seconds: float = 0.0,
    ) -> MeetingIntelligence:
        """Run full analysis and return a MeetingIntelligence report."""
        transcript_text = parsed.plain_text
        # Truncate to ~120 000 chars to stay within common context windows
        if len(transcript_text) > 120_000:
            logger.warning("Transcript truncated to 120 000 characters for LLM context window.")
            transcript_text = transcript_text[:120_000] + "\n[... transcript truncated ...]"

        prompt = _ANALYSIS_PROMPT_TEMPLATE.format(transcript=transcript_text)
        raw = self.llm.complete(_SYSTEM_PROMPT, prompt)
        data = self._parse_json_response(raw)

        return self._build_report(
            data=data,
            parsed=parsed,
            meeting_date=meeting_date,
            duration_seconds=duration_seconds,
        )

    def _parse_json_response(self, raw: str) -> Dict[str, Any]:
        """Extract JSON from LLM response, handling markdown code fences."""
        text = raw.strip()
        # Strip ```json ... ``` fences if present
        if text.startswith("```"):
            lines = text.splitlines()
            text = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            logger.error("Failed to parse LLM response as JSON: %s", exc)
            logger.debug("Raw LLM response: %s", raw)
            raise ValueError(f"LLM returned invalid JSON: {exc}") from exc

    def _build_report(
        self,
        data: Dict[str, Any],
        parsed: ParsedTranscript,
        meeting_date: Optional[str],
        duration_seconds: float,
    ) -> MeetingIntelligence:
        speaker_stats = compute_speaker_stats(parsed)
        participants = [
            Speaker(
                name=name,
                talk_time_seconds=stats["seconds"],
                utterance_count=stats["utterances"],
            )
            for name, stats in speaker_stats.items()
        ]

        action_items = [
            ActionItem(
                description=a.get("description", ""),
                assignee=a.get("assignee"),
                due_date=a.get("due_date"),
                priority=Priority(a.get("priority", "medium")),
                source_quote=a.get("source_quote"),
            )
            for a in data.get("action_items", [])
        ]

        decisions = [
            Decision(
                description=d.get("description", ""),
                made_by=d.get("made_by"),
                rationale=d.get("rationale"),
                source_quote=d.get("source_quote"),
            )
            for d in data.get("decisions", [])
        ]

        key_topics = [
            Topic(
                title=t.get("title", ""),
                summary=t.get("summary", ""),
                sentiment=SentimentLabel(t.get("sentiment", "neutral")),
                keywords=t.get("keywords", []),
            )
            for t in data.get("key_topics", [])
        ]

        return MeetingIntelligence(
            title=data.get("title", "Meeting"),
            date=meeting_date,
            duration_seconds=duration_seconds,
            participants=participants,
            executive_summary=data.get("executive_summary", ""),
            key_topics=key_topics,
            action_items=action_items,
            decisions=decisions,
            next_steps=data.get("next_steps", []),
            open_questions=data.get("open_questions", []),
            sentiment_overall=SentimentLabel(data.get("sentiment_overall", "neutral")),
            follow_up_meeting_recommended=data.get("follow_up_meeting_recommended", False),
            model_used=self.llm.model,
            transcript_word_count=parsed.word_count,
        )
