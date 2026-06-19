"""Tests for the CLI entry point."""

import json
import sys
from io import StringIO
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from meeting_intelligence.cli import main
from meeting_intelligence.models import (
    ActionItem,
    Decision,
    MeetingIntelligence,
    Priority,
    SentimentLabel,
    Speaker,
    Topic,
)


def _sample_report() -> MeetingIntelligence:
    return MeetingIntelligence(
        title="CLI Test Meeting",
        date="2026-06-19",
        duration_seconds=1800.0,
        participants=[Speaker(name="Alice", talk_time_seconds=500.0, utterance_count=5)],
        executive_summary="A test meeting for CLI validation.",
        action_items=[ActionItem(description="Write tests", assignee="Alice", priority=Priority.HIGH)],
        decisions=[Decision(description="Use pytest")],
        sentiment_overall=SentimentLabel.POSITIVE,
        model_used="gpt-4o",
        transcript_word_count=50,
    )


TRANSCRIPT_CONTENT = """\
Alice: Good morning. Let's start the meeting.
Bob: Sure, I'm ready.
Alice: Let's review the action items.
"""


@pytest.fixture
def transcript_file(tmp_path):
    f = tmp_path / "meeting.txt"
    f.write_text(TRANSCRIPT_CONTENT)
    return f


def _patch_analyzer(report=None):
    if report is None:
        report = _sample_report()
    mock_analyzer_cls = MagicMock()
    mock_analyzer_cls.return_value.analyze.return_value = report
    return mock_analyzer_cls


def test_cli_text_output(transcript_file, capsys):
    with patch("meeting_intelligence.cli.LLMClient") as mock_llm_cls:
        mock_llm_cls.return_value = MagicMock()
        with patch("meeting_intelligence.cli.MeetingAnalyzer", _patch_analyzer()):
            result = main([str(transcript_file), "--api-key", "test-key"])

    assert result == 0
    captured = capsys.readouterr()
    assert "BRMSTE MEETING INTELLIGENCE REPORT" in captured.out


def test_cli_markdown_output(transcript_file, capsys):
    with patch("meeting_intelligence.cli.LLMClient") as mock_llm_cls:
        mock_llm_cls.return_value = MagicMock()
        with patch("meeting_intelligence.cli.MeetingAnalyzer", _patch_analyzer()):
            result = main([str(transcript_file), "--format", "markdown", "--api-key", "test-key"])

    assert result == 0
    captured = capsys.readouterr()
    assert "# CLI Test Meeting" in captured.out


def test_cli_json_output(transcript_file, capsys):
    with patch("meeting_intelligence.cli.LLMClient") as mock_llm_cls:
        mock_llm_cls.return_value = MagicMock()
        with patch("meeting_intelligence.cli.MeetingAnalyzer", _patch_analyzer()):
            result = main([str(transcript_file), "--format", "json", "--api-key", "test-key"])

    assert result == 0
    captured = capsys.readouterr()
    data = json.loads(captured.out)
    assert data["title"] == "CLI Test Meeting"


def test_cli_missing_file(capsys):
    result = main(["nonexistent_file.txt"])
    assert result == 1
    captured = capsys.readouterr()
    assert "not found" in captured.err


def test_cli_no_api_key(transcript_file, capsys):
    with patch.dict("os.environ", {}, clear=True):
        # Remove all potential API key env vars
        import os
        for k in ["OPENAI_API_KEY", "BRMSTE_LLM_API_KEY"]:
            os.environ.pop(k, None)
        result = main([str(transcript_file)])
    assert result == 1


def test_cli_write_to_file(transcript_file, tmp_path, capsys):
    output_file = tmp_path / "report.md"
    with patch("meeting_intelligence.cli.LLMClient") as mock_llm_cls:
        mock_llm_cls.return_value = MagicMock()
        with patch("meeting_intelligence.cli.MeetingAnalyzer", _patch_analyzer()):
            result = main([
                str(transcript_file),
                "--format", "markdown",
                "--output", str(output_file),
                "--api-key", "test-key",
            ])

    assert result == 0
    assert output_file.exists()
    content = output_file.read_text()
    assert "# CLI Test Meeting" in content
