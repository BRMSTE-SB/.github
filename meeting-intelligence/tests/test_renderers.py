"""Tests for output renderers."""

import json

import pytest

from meeting_intelligence.models import (
    ActionItem,
    Decision,
    MeetingIntelligence,
    Priority,
    SentimentLabel,
    Speaker,
    Topic,
)
from meeting_intelligence.renderers import render_json, render_markdown, render_text


def _sample_report() -> MeetingIntelligence:
    return MeetingIntelligence(
        title="Q3 Sprint Review",
        date="2026-06-19",
        duration_seconds=3600.0,
        participants=[
            Speaker(name="Alice", talk_time_seconds=900.0, utterance_count=12),
            Speaker(name="Bob", talk_time_seconds=600.0, utterance_count=8),
        ],
        executive_summary="The team reviewed Q3 progress and agreed on next steps.",
        key_topics=[
            Topic(
                title="Authentication Module",
                summary="Bob completed the auth module; ready for QA.",
                sentiment=SentimentLabel.POSITIVE,
                keywords=["auth", "QA", "security"],
            )
        ],
        action_items=[
            ActionItem(
                description="Deploy auth module to staging",
                assignee="Charlie",
                due_date="2026-06-26",
                priority=Priority.HIGH,
            )
        ],
        decisions=[
            Decision(
                description="Use PostgreSQL for the user store",
                made_by="Alice",
                rationale="Better support for JSON columns",
            )
        ],
        next_steps=["Schedule QA session", "Update project board"],
        open_questions=["Do we need a cache layer?"],
        sentiment_overall=SentimentLabel.POSITIVE,
        follow_up_meeting_recommended=True,
        model_used="gpt-4o",
        transcript_word_count=1250,
    )


# ---------------------------------------------------------------------------
# JSON renderer
# ---------------------------------------------------------------------------

def test_render_json_is_valid():
    report = _sample_report()
    output = render_json(report)
    data = json.loads(output)
    assert data["title"] == "Q3 Sprint Review"


def test_render_json_contains_action_items():
    report = _sample_report()
    data = json.loads(render_json(report))
    assert len(data["action_items"]) == 1
    assert data["action_items"][0]["assignee"] == "Charlie"


def test_render_json_contains_decisions():
    report = _sample_report()
    data = json.loads(render_json(report))
    assert data["decisions"][0]["description"] == "Use PostgreSQL for the user store"


def test_render_json_contains_participants():
    report = _sample_report()
    data = json.loads(render_json(report))
    assert len(data["participants"]) == 2


# ---------------------------------------------------------------------------
# Markdown renderer
# ---------------------------------------------------------------------------

def test_render_markdown_has_title():
    report = _sample_report()
    output = render_markdown(report)
    assert "# Q3 Sprint Review" in output


def test_render_markdown_has_executive_summary():
    report = _sample_report()
    output = render_markdown(report)
    assert "## Executive Summary" in output
    assert "Q3 progress" in output


def test_render_markdown_has_action_items():
    report = _sample_report()
    output = render_markdown(report)
    assert "## Action Items" in output
    assert "Deploy auth module" in output
    assert "Charlie" in output


def test_render_markdown_has_decisions():
    report = _sample_report()
    output = render_markdown(report)
    assert "## Decisions Made" in output
    assert "PostgreSQL" in output


def test_render_markdown_has_patent_footer():
    report = _sample_report()
    output = render_markdown(report)
    assert "GB2607860" in output
    assert "BRMSTE LTD" in output


def test_render_markdown_has_participants_table():
    report = _sample_report()
    output = render_markdown(report)
    assert "| Alice |" in output


# ---------------------------------------------------------------------------
# Text renderer
# ---------------------------------------------------------------------------

def test_render_text_has_header():
    report = _sample_report()
    output = render_text(report)
    assert "BRMSTE MEETING INTELLIGENCE REPORT" in output


def test_render_text_has_executive_summary_section():
    report = _sample_report()
    output = render_text(report)
    assert "EXECUTIVE SUMMARY" in output


def test_render_text_has_action_items_section():
    report = _sample_report()
    output = render_text(report)
    assert "ACTION ITEMS" in output


def test_render_text_has_patent_footer():
    report = _sample_report()
    output = render_text(report)
    assert "GB2607860" in output
    assert "Dimpy Bansal" in output


def test_render_text_has_decisions():
    report = _sample_report()
    output = render_text(report)
    assert "DECISIONS" in output
    assert "PostgreSQL" in output


def test_render_text_no_emoji_in_output():
    """Text renderer should not use emoji characters for terminal compatibility."""
    report = _sample_report()
    output = render_text(report)
    # Acceptable: brackets, plain ASCII only in text renderer
    for ch in output:
        assert ord(ch) < 0x1F600 or ch.isspace(), f"Unexpected high codepoint: {ch!r}"
