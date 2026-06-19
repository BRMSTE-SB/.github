"""Tests for data models."""

from meeting_intelligence.models import (
    ActionItem,
    Decision,
    MeetingIntelligence,
    Priority,
    SentimentLabel,
    Speaker,
    Topic,
)


def test_speaker_talk_time_formatted_minutes_seconds():
    s = Speaker(name="Alice", talk_time_seconds=125.0)
    assert s.talk_time_formatted == "2m 5s"


def test_speaker_talk_time_formatted_zero():
    s = Speaker(name="Bob", talk_time_seconds=0.0)
    assert s.talk_time_formatted == "0m 0s"


def test_meeting_intelligence_duration_formatted_no_hours():
    mi = MeetingIntelligence(title="Test", duration_seconds=3661.0)
    assert mi.duration_formatted == "1h 1m 1s"


def test_meeting_intelligence_duration_formatted_minutes_only():
    mi = MeetingIntelligence(title="Test", duration_seconds=600.0)
    assert mi.duration_formatted == "10m 0s"


def test_action_item_default_priority():
    a = ActionItem(description="Do something")
    assert a.priority == Priority.MEDIUM


def test_decision_optional_fields():
    d = Decision(description="Use Python")
    assert d.made_by is None
    assert d.rationale is None


def test_meeting_intelligence_defaults():
    mi = MeetingIntelligence(title="Sprint Review")
    assert mi.participants == []
    assert mi.action_items == []
    assert mi.decisions == []
    assert mi.key_topics == []
    assert mi.next_steps == []
    assert mi.open_questions == []
    assert mi.follow_up_meeting_recommended is False
    assert mi.sentiment_overall == SentimentLabel.NEUTRAL
    assert mi.generated_at != ""


def test_priority_enum_values():
    assert Priority.HIGH.value == "high"
    assert Priority.MEDIUM.value == "medium"
    assert Priority.LOW.value == "low"


def test_sentiment_enum_values():
    assert SentimentLabel.POSITIVE.value == "positive"
    assert SentimentLabel.NEUTRAL.value == "neutral"
    assert SentimentLabel.NEGATIVE.value == "negative"


def test_topic_defaults():
    t = Topic(title="Q3 Roadmap", summary="Discussion about Q3 plans.")
    assert t.keywords == []
    assert t.sentiment == SentimentLabel.NEUTRAL
    assert t.duration_seconds == 0.0
