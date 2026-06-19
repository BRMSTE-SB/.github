"""
Transcript parsing and pre-processing for BRMSTE Meeting Intelligence.
Patent: GB2607860 · PCT/GB2026/050406 — BRMSTE LTD
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List, Optional, Tuple


@dataclass
class Utterance:
    speaker: str
    text: str
    start_seconds: Optional[float] = None
    end_seconds: Optional[float] = None

    @property
    def duration_seconds(self) -> float:
        if self.start_seconds is not None and self.end_seconds is not None:
            return self.end_seconds - self.start_seconds
        return 0.0


@dataclass
class ParsedTranscript:
    raw_text: str
    utterances: List[Utterance] = field(default_factory=list)
    format_detected: str = "plain"

    @property
    def word_count(self) -> int:
        return len(self.raw_text.split())

    @property
    def speaker_names(self) -> List[str]:
        seen = []
        for u in self.utterances:
            if u.speaker not in seen:
                seen.append(u.speaker)
        return seen

    @property
    def plain_text(self) -> str:
        if self.utterances:
            return "\n".join(f"{u.speaker}: {u.text}" for u in self.utterances)
        return self.raw_text


# ---------------------------------------------------------------------------
# Format detection helpers
# ---------------------------------------------------------------------------

_SPEAKER_LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 '\-\.]{0,39}):\s+(.+)$", re.MULTILINE)
_TIMESTAMP_RE = re.compile(r"\[(\d{1,2}:\d{2}(?::\d{2})?)\]")
_VTT_HEADER = re.compile(r"^WEBVTT", re.MULTILINE)
_SRT_BLOCK_RE = re.compile(
    r"(\d+)\n(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n([\s\S]+?)(?=\n\n|\Z)"
)


def _hms_to_seconds(hms: str) -> float:
    parts = hms.replace(",", ".").split(":")
    if len(parts) == 3:
        h, m, s = parts
        return int(h) * 3600 + int(m) * 60 + float(s)
    elif len(parts) == 2:
        m, s = parts
        return int(m) * 60 + float(s)
    return float(parts[0])


def _parse_srt(text: str) -> List[Utterance]:
    utterances: List[Utterance] = []
    for match in _SRT_BLOCK_RE.finditer(text):
        start = _hms_to_seconds(match.group(2))
        end = _hms_to_seconds(match.group(3))
        body = match.group(4).strip()
        speaker_match = _SPEAKER_LABEL_RE.match(body)
        if speaker_match:
            speaker, line_text = speaker_match.group(1).strip(), speaker_match.group(2).strip()
        else:
            speaker, line_text = "Unknown", body
        utterances.append(Utterance(speaker=speaker, text=line_text, start_seconds=start, end_seconds=end))
    return utterances


def _parse_vtt(text: str) -> List[Utterance]:
    cue_re = re.compile(
        r"(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3}).*\n([\s\S]+?)(?=\n\n|\Z)"
    )
    utterances: List[Utterance] = []
    for match in cue_re.finditer(text):
        start = _hms_to_seconds(match.group(1))
        end = _hms_to_seconds(match.group(2))
        body = match.group(3).strip()
        speaker_match = _SPEAKER_LABEL_RE.match(body)
        if speaker_match:
            speaker, line_text = speaker_match.group(1).strip(), speaker_match.group(2).strip()
        else:
            speaker, line_text = "Unknown", body
        utterances.append(Utterance(speaker=speaker, text=line_text, start_seconds=start, end_seconds=end))
    return utterances


def _parse_labeled(text: str) -> List[Utterance]:
    utterances: List[Utterance] = []
    current_speaker: Optional[str] = None
    current_lines: List[str] = []

    for line in text.splitlines():
        line = line.strip()
        if not line:
            if current_speaker and current_lines:
                utterances.append(Utterance(speaker=current_speaker, text=" ".join(current_lines)))
                current_lines = []
            continue
        m = _SPEAKER_LABEL_RE.match(line)
        if m:
            if current_speaker and current_lines:
                utterances.append(Utterance(speaker=current_speaker, text=" ".join(current_lines)))
                current_lines = []
            current_speaker = m.group(1).strip()
            rest = m.group(2).strip()
            if rest:
                current_lines = [rest]
        else:
            current_lines.append(line)

    if current_speaker and current_lines:
        utterances.append(Utterance(speaker=current_speaker, text=" ".join(current_lines)))

    return utterances


def parse_transcript(text: str) -> ParsedTranscript:
    """Detect transcript format and parse into structured utterances."""
    text = text.strip()

    if _VTT_HEADER.search(text):
        utterances = _parse_vtt(text)
        fmt = "vtt"
    elif _SRT_BLOCK_RE.search(text):
        utterances = _parse_srt(text)
        fmt = "srt"
    elif _SPEAKER_LABEL_RE.search(text):
        utterances = _parse_labeled(text)
        fmt = "labeled"
    else:
        utterances = [Utterance(speaker="Unknown", text=text)]
        fmt = "plain"

    return ParsedTranscript(raw_text=text, utterances=utterances, format_detected=fmt)


def compute_speaker_stats(parsed: ParsedTranscript) -> dict:
    """Return per-speaker talk time and utterance count."""
    stats: dict = {}
    for u in parsed.utterances:
        if u.speaker not in stats:
            stats[u.speaker] = {"utterances": 0, "seconds": 0.0, "words": 0}
        stats[u.speaker]["utterances"] += 1
        stats[u.speaker]["seconds"] += u.duration_seconds
        stats[u.speaker]["words"] += len(u.text.split())
    return stats
