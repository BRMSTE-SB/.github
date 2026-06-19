"""
Data models for BRMSTE Meeting Intelligence.
Patent: GB2607860 · PCT/GB2026/050406 — BRMSTE LTD
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional


class Priority(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class SentimentLabel(str, Enum):
    POSITIVE = "positive"
    NEUTRAL = "neutral"
    NEGATIVE = "negative"


@dataclass
class Speaker:
    name: str
    role: Optional[str] = None
    talk_time_seconds: float = 0.0
    utterance_count: int = 0

    @property
    def talk_time_formatted(self) -> str:
        minutes, seconds = divmod(int(self.talk_time_seconds), 60)
        return f"{minutes}m {seconds}s"


@dataclass
class ActionItem:
    description: str
    assignee: Optional[str] = None
    due_date: Optional[str] = None
    priority: Priority = Priority.MEDIUM
    source_quote: Optional[str] = None


@dataclass
class Decision:
    description: str
    made_by: Optional[str] = None
    rationale: Optional[str] = None
    source_quote: Optional[str] = None


@dataclass
class Topic:
    title: str
    summary: str
    duration_seconds: float = 0.0
    sentiment: SentimentLabel = SentimentLabel.NEUTRAL
    keywords: List[str] = field(default_factory=list)


@dataclass
class MeetingIntelligence:
    """Complete intelligence report for a meeting."""

    title: str
    date: Optional[str] = None
    duration_seconds: float = 0.0
    participants: List[Speaker] = field(default_factory=list)
    executive_summary: str = ""
    key_topics: List[Topic] = field(default_factory=list)
    action_items: List[ActionItem] = field(default_factory=list)
    decisions: List[Decision] = field(default_factory=list)
    next_steps: List[str] = field(default_factory=list)
    open_questions: List[str] = field(default_factory=list)
    sentiment_overall: SentimentLabel = SentimentLabel.NEUTRAL
    follow_up_meeting_recommended: bool = False
    generated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    model_used: str = ""
    transcript_word_count: int = 0

    @property
    def duration_formatted(self) -> str:
        hours, remainder = divmod(int(self.duration_seconds), 3600)
        minutes, seconds = divmod(remainder, 60)
        if hours:
            return f"{hours}h {minutes}m {seconds}s"
        return f"{minutes}m {seconds}s"
