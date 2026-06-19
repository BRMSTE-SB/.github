"""Tests for transcript parsing."""

import pytest

from meeting_intelligence.transcript import (
    ParsedTranscript,
    Utterance,
    compute_speaker_stats,
    parse_transcript,
)


# ---------------------------------------------------------------------------
# Labeled format
# ---------------------------------------------------------------------------

LABELED_TRANSCRIPT = """\
Alice: Good morning everyone. Let's get started with the sprint review.
Bob: Thanks Alice. I've completed the authentication module.
Alice: Great work Bob. Any blockers?
Bob: No blockers. Ready for QA.
Charlie: I can pick up QA starting tomorrow.
"""

def test_parse_labeled_detects_format():
    result = parse_transcript(LABELED_TRANSCRIPT)
    assert result.format_detected == "labeled"


def test_parse_labeled_utterance_count():
    result = parse_transcript(LABELED_TRANSCRIPT)
    assert len(result.utterances) == 5


def test_parse_labeled_speakers():
    result = parse_transcript(LABELED_TRANSCRIPT)
    assert result.speaker_names == ["Alice", "Bob", "Charlie"]


def test_parse_labeled_text_content():
    result = parse_transcript(LABELED_TRANSCRIPT)
    assert "authentication module" in result.utterances[1].text


# ---------------------------------------------------------------------------
# SRT format
# ---------------------------------------------------------------------------

SRT_TRANSCRIPT = """\
1
00:00:01,000 --> 00:00:04,000
Alice: We need to finalise the roadmap.

2
00:00:04,500 --> 00:00:08,000
Bob: Agreed. Let's target Q3 release.

3
00:00:08,500 --> 00:00:12,000
Alice: Perfect. I'll update the board.
"""

def test_parse_srt_format():
    result = parse_transcript(SRT_TRANSCRIPT)
    assert result.format_detected == "srt"


def test_parse_srt_utterances():
    result = parse_transcript(SRT_TRANSCRIPT)
    assert len(result.utterances) == 3


def test_parse_srt_timestamps():
    result = parse_transcript(SRT_TRANSCRIPT)
    assert result.utterances[0].start_seconds == pytest.approx(1.0)
    assert result.utterances[0].end_seconds == pytest.approx(4.0)


def test_parse_srt_speakers():
    result = parse_transcript(SRT_TRANSCRIPT)
    assert result.utterances[0].speaker == "Alice"
    assert result.utterances[1].speaker == "Bob"


# ---------------------------------------------------------------------------
# VTT format
# ---------------------------------------------------------------------------

VTT_TRANSCRIPT = """\
WEBVTT

00:00:01.000 --> 00:00:03.500
Alice: Hello team.

00:00:04.000 --> 00:00:07.000
Bob: Hi Alice, ready to start.
"""

def test_parse_vtt_format():
    result = parse_transcript(VTT_TRANSCRIPT)
    assert result.format_detected == "vtt"


def test_parse_vtt_utterances():
    result = parse_transcript(VTT_TRANSCRIPT)
    assert len(result.utterances) == 2


def test_parse_vtt_first_speaker():
    result = parse_transcript(VTT_TRANSCRIPT)
    assert result.utterances[0].speaker == "Alice"


# ---------------------------------------------------------------------------
# Plain text fallback
# ---------------------------------------------------------------------------

def test_parse_plain_fallback():
    text = "This is an unformatted transcript with no speaker labels."
    result = parse_transcript(text)
    assert result.format_detected == "plain"
    assert len(result.utterances) == 1
    assert result.utterances[0].speaker == "Unknown"


# ---------------------------------------------------------------------------
# Speaker stats
# ---------------------------------------------------------------------------

def test_compute_speaker_stats_basic():
    parsed = parse_transcript(LABELED_TRANSCRIPT)
    stats = compute_speaker_stats(parsed)
    assert "Alice" in stats
    assert "Bob" in stats
    assert "Charlie" in stats
    assert stats["Alice"]["utterances"] == 2
    assert stats["Bob"]["utterances"] == 2
    assert stats["Charlie"]["utterances"] == 1


def test_compute_speaker_stats_words():
    parsed = parse_transcript(LABELED_TRANSCRIPT)
    stats = compute_speaker_stats(parsed)
    assert stats["Alice"]["words"] > 0


# ---------------------------------------------------------------------------
# Word count
# ---------------------------------------------------------------------------

def test_word_count():
    result = parse_transcript(LABELED_TRANSCRIPT)
    assert result.word_count > 30


def test_plain_text_includes_speakers():
    result = parse_transcript(LABELED_TRANSCRIPT)
    pt = result.plain_text
    assert "Alice:" in pt
    assert "Bob:" in pt
