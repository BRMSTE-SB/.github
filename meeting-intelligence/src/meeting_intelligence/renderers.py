"""
Output renderers for BRMSTE Meeting Intelligence reports.
Patent: GB2607860 · PCT/GB2026/050406 — BRMSTE LTD
"""

from __future__ import annotations

import dataclasses
import json
from typing import Any

from .models import ActionItem, MeetingIntelligence, Priority, SentimentLabel


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_PRIORITY_EMOJI = {
    Priority.HIGH: "🔴",
    Priority.MEDIUM: "🟡",
    Priority.LOW: "🟢",
}

_SENTIMENT_EMOJI = {
    SentimentLabel.POSITIVE: "✅",
    SentimentLabel.NEUTRAL: "➖",
    SentimentLabel.NEGATIVE: "⚠️",
}


def _dataclass_to_dict(obj: Any) -> Any:
    if dataclasses.is_dataclass(obj) and not isinstance(obj, type):
        return {k: _dataclass_to_dict(v) for k, v in dataclasses.asdict(obj).items()}
    if isinstance(obj, list):
        return [_dataclass_to_dict(i) for i in obj]
    if isinstance(obj, dict):
        return {k: _dataclass_to_dict(v) for k, v in obj.items()}
    return obj


# ---------------------------------------------------------------------------
# JSON renderer
# ---------------------------------------------------------------------------

def render_json(report: MeetingIntelligence, indent: int = 2) -> str:
    return json.dumps(_dataclass_to_dict(report), indent=indent, ensure_ascii=False)


# ---------------------------------------------------------------------------
# Markdown renderer
# ---------------------------------------------------------------------------

def render_markdown(report: MeetingIntelligence) -> str:
    lines: list[str] = []

    lines.append(f"# {report.title}")
    lines.append("")

    meta_parts = []
    if report.date:
        meta_parts.append(f"**Date:** {report.date}")
    if report.duration_seconds:
        meta_parts.append(f"**Duration:** {report.duration_formatted}")
    if report.participants:
        names = ", ".join(p.name for p in report.participants)
        meta_parts.append(f"**Participants:** {names}")
    if meta_parts:
        lines.extend(meta_parts)
        lines.append("")

    overall = _SENTIMENT_EMOJI.get(report.sentiment_overall, "")
    lines.append(f"**Overall Sentiment:** {overall} {report.sentiment_overall.value.title()}")
    if report.follow_up_meeting_recommended:
        lines.append("**Follow-up Meeting:** Recommended")
    lines.append("")

    # Executive summary
    lines.append("## Executive Summary")
    lines.append("")
    lines.append(report.executive_summary)
    lines.append("")

    # Key topics
    if report.key_topics:
        lines.append("## Key Topics")
        lines.append("")
        for topic in report.key_topics:
            sentiment_icon = _SENTIMENT_EMOJI.get(topic.sentiment, "")
            lines.append(f"### {topic.title} {sentiment_icon}")
            lines.append(topic.summary)
            if topic.keywords:
                lines.append("")
                lines.append("**Keywords:** " + ", ".join(f"`{k}`" for k in topic.keywords))
            lines.append("")

    # Action items
    if report.action_items:
        lines.append("## Action Items")
        lines.append("")
        for i, item in enumerate(report.action_items, 1):
            priority_icon = _PRIORITY_EMOJI.get(item.priority, "")
            assignee = f" — *{item.assignee}*" if item.assignee else ""
            due = f" · Due: {item.due_date}" if item.due_date else ""
            lines.append(f"{i}. {priority_icon} **{item.description}**{assignee}{due}")
            if item.source_quote:
                lines.append(f"   > \"{item.source_quote}\"")
        lines.append("")

    # Decisions
    if report.decisions:
        lines.append("## Decisions Made")
        lines.append("")
        for decision in report.decisions:
            lines.append(f"- **{decision.description}**")
            if decision.made_by:
                lines.append(f"  - *Made by:* {decision.made_by}")
            if decision.rationale:
                lines.append(f"  - *Rationale:* {decision.rationale}")
            if decision.source_quote:
                lines.append(f"  > \"{decision.source_quote}\"")
        lines.append("")

    # Next steps
    if report.next_steps:
        lines.append("## Next Steps")
        lines.append("")
        for step in report.next_steps:
            lines.append(f"- {step}")
        lines.append("")

    # Open questions
    if report.open_questions:
        lines.append("## Open Questions")
        lines.append("")
        for q in report.open_questions:
            lines.append(f"- {q}")
        lines.append("")

    # Participants
    if report.participants:
        lines.append("## Participants")
        lines.append("")
        lines.append("| Name | Talk Time | Utterances |")
        lines.append("|------|-----------|------------|")
        for p in sorted(report.participants, key=lambda x: x.talk_time_seconds, reverse=True):
            lines.append(f"| {p.name} | {p.talk_time_formatted} | {p.utterance_count} |")
        lines.append("")

    # Footer
    lines.append("---")
    lines.append(
        f"*Generated by BRMSTE Meeting Intelligence · {report.generated_at} · "
        f"Model: {report.model_used} · Words analysed: {report.transcript_word_count:,}*"
    )
    lines.append("")
    lines.append(
        "*BRMSTE LTD · Companies House 15310393 · "
        "Patent GB2607860 · PCT/GB2026/050406 · "
        "Beneficiary: Dimpy Bansal · Dimpy Bansal Trust*"
    )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Plain-text renderer (for terminal output)
# ---------------------------------------------------------------------------

def render_text(report: MeetingIntelligence) -> str:
    sep = "=" * 72
    thin = "-" * 72
    lines: list[str] = []

    lines.append(sep)
    lines.append(f"  BRMSTE MEETING INTELLIGENCE REPORT")
    lines.append(f"  {report.title}")
    lines.append(sep)
    lines.append("")

    if report.date:
        lines.append(f"  Date      : {report.date}")
    if report.duration_seconds:
        lines.append(f"  Duration  : {report.duration_formatted}")
    if report.participants:
        lines.append(f"  Attendees : {', '.join(p.name for p in report.participants)}")
    lines.append(f"  Sentiment : {report.sentiment_overall.value.upper()}")
    lines.append(f"  Words     : {report.transcript_word_count:,}")
    lines.append("")

    lines.append(thin)
    lines.append("  EXECUTIVE SUMMARY")
    lines.append(thin)
    for chunk in _wrap(report.executive_summary, 68):
        lines.append(f"  {chunk}")
    lines.append("")

    if report.key_topics:
        lines.append(thin)
        lines.append("  KEY TOPICS")
        lines.append(thin)
        for t in report.key_topics:
            lines.append(f"  [{t.sentiment.value.upper()}] {t.title}")
            for chunk in _wrap(t.summary, 66):
                lines.append(f"    {chunk}")
            if t.keywords:
                lines.append(f"    Keywords: {', '.join(t.keywords)}")
            lines.append("")

    if report.action_items:
        lines.append(thin)
        lines.append("  ACTION ITEMS")
        lines.append(thin)
        for i, a in enumerate(report.action_items, 1):
            assignee = f" ({a.assignee})" if a.assignee else ""
            due = f" [Due: {a.due_date}]" if a.due_date else ""
            lines.append(f"  {i}. [{a.priority.value.upper()}]{assignee}{due}")
            for chunk in _wrap(a.description, 66):
                lines.append(f"     {chunk}")
        lines.append("")

    if report.decisions:
        lines.append(thin)
        lines.append("  DECISIONS")
        lines.append(thin)
        for d in report.decisions:
            lines.append(f"  * {d.description}")
            if d.made_by:
                lines.append(f"    By: {d.made_by}")
        lines.append("")

    if report.next_steps:
        lines.append(thin)
        lines.append("  NEXT STEPS")
        lines.append(thin)
        for s in report.next_steps:
            for chunk in _wrap(s, 66, prefix="  > "):
                lines.append(chunk)
        lines.append("")

    if report.open_questions:
        lines.append(thin)
        lines.append("  OPEN QUESTIONS")
        lines.append(thin)
        for q in report.open_questions:
            for chunk in _wrap(q, 66, prefix="  ? "):
                lines.append(chunk)
        lines.append("")

    lines.append(sep)
    lines.append(
        "  BRMSTE LTD · CH 15310393 · Patent GB2607860 · PCT/GB2026/050406"
    )
    lines.append("  Beneficiary: Dimpy Bansal · Dimpy Bansal Trust")
    lines.append(sep)

    return "\n".join(lines)


def _wrap(text: str, width: int, prefix: str = "") -> list[str]:
    import textwrap
    wrapper = textwrap.TextWrapper(width=width, subsequent_indent=" " * len(prefix))
    return [prefix + line for line in wrapper.wrap(text)] if text else []
