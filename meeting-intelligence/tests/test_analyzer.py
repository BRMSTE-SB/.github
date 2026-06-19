"""Tests for the meeting analyser (uses a mock LLM client)."""

import json
from unittest.mock import MagicMock, patch

import pytest

from meeting_intelligence.analyzer import MeetingAnalyzer
from meeting_intelligence.models import MeetingIntelligence, Priority, SentimentLabel
from meeting_intelligence.transcript import parse_transcript


_MOCK_LLM_RESPONSE = json.dumps({
    "title": "Weekly Sync",
    "executive_summary": "The team synced on progress and agreed on a PostgreSQL migration.",
    "key_topics": [
        {
            "title": "Database Migration",
            "summary": "Team agreed to migrate to PostgreSQL.",
            "sentiment": "positive",
            "keywords": ["database", "PostgreSQL", "migration"],
        }
    ],
    "action_items": [
        {
            "description": "Write migration scripts",
            "assignee": "Bob",
            "due_date": "2026-06-30",
            "priority": "high",
            "source_quote": "Bob: I'll write the migration scripts.",
        }
    ],
    "decisions": [
        {
            "description": "Migrate to PostgreSQL",
            "made_by": "Alice",
            "rationale": "Better scalability",
            "source_quote": "Alice: Let's go with Postgres.",
        }
    ],
    "next_steps": ["Complete migration scripts", "Schedule testing"],
    "open_questions": ["What is the downtime window?"],
    "sentiment_overall": "positive",
    "follow_up_meeting_recommended": True,
})

SAMPLE_TRANSCRIPT = """\
Alice: Good morning. Today we'll discuss the database migration.
Bob: I think we should move to PostgreSQL.
Alice: Agreed. Bob, can you write the migration scripts?
Bob: I'll write the migration scripts.
Alice: Let's go with Postgres.
"""


def _make_mock_llm(response: str = _MOCK_LLM_RESPONSE) -> MagicMock:
    llm = MagicMock()
    llm.complete.return_value = response
    llm.model = "gpt-4o-mock"
    return llm


def test_analyze_returns_meeting_intelligence():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert isinstance(report, MeetingIntelligence)


def test_analyze_title():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert report.title == "Weekly Sync"


def test_analyze_executive_summary():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert "PostgreSQL" in report.executive_summary


def test_analyze_action_items():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert len(report.action_items) == 1
    assert report.action_items[0].assignee == "Bob"
    assert report.action_items[0].priority == Priority.HIGH


def test_analyze_decisions():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert len(report.decisions) == 1
    assert report.decisions[0].made_by == "Alice"


def test_analyze_sentiment():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert report.sentiment_overall == SentimentLabel.POSITIVE


def test_analyze_follow_up_recommended():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert report.follow_up_meeting_recommended is True


def test_analyze_participants_extracted_from_transcript():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    names = [p.name for p in report.participants]
    assert "Alice" in names
    assert "Bob" in names


def test_analyze_word_count():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert report.transcript_word_count > 0


def test_analyze_with_date_and_duration():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed, meeting_date="2026-06-19", duration_seconds=1800.0)
    assert report.date == "2026-06-19"
    assert report.duration_seconds == 1800.0


def test_parse_json_response_strips_markdown_fence():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    fenced = "```json\n" + _MOCK_LLM_RESPONSE + "\n```"
    data = analyser._parse_json_response(fenced)
    assert data["title"] == "Weekly Sync"


def test_parse_json_response_raises_on_invalid():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    with pytest.raises(ValueError, match="invalid JSON"):
        analyser._parse_json_response("not json at all {{}")


def test_analyze_open_questions():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert "downtime" in report.open_questions[0].lower()


def test_analyze_next_steps():
    parsed = parse_transcript(SAMPLE_TRANSCRIPT)
    analyser = MeetingAnalyzer(_make_mock_llm())
    report = analyser.analyze(parsed)
    assert len(report.next_steps) == 2
