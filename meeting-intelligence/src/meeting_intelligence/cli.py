"""
CLI entry point for BRMSTE Meeting Intelligence.

Usage:
    meeting-intelligence [OPTIONS] TRANSCRIPT_FILE

Patent: GB2607860 · PCT/GB2026/050406 — BRMSTE LTD
"""

from __future__ import annotations

import argparse
import logging
import os
import sys
from pathlib import Path
from typing import Optional

from .analyzer import LLMClient, MeetingAnalyzer
from .renderers import render_json, render_markdown, render_text
from .transcript import parse_transcript


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="meeting-intelligence",
        description=(
            "BRMSTE Meeting Intelligence — AI-powered meeting transcript analyser.\n"
            "Patent GB2607860 · PCT/GB2026/050406 · BRMSTE LTD"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  meeting-intelligence transcript.txt\n"
            "  meeting-intelligence transcript.vtt --format markdown -o report.md\n"
            "  meeting-intelligence transcript.srt --model gpt-4o --date 2026-06-19\n"
            "  echo 'Alice: Hello\\nBob: Hi' | meeting-intelligence -\n"
        ),
    )

    parser.add_argument(
        "transcript",
        metavar="TRANSCRIPT",
        help="Path to transcript file (.txt, .srt, .vtt) or '-' to read from stdin.",
    )
    parser.add_argument(
        "--format", "-f",
        choices=["text", "markdown", "json"],
        default="text",
        help="Output format (default: text).",
    )
    parser.add_argument(
        "--output", "-o",
        metavar="FILE",
        help="Write output to FILE instead of stdout.",
    )
    parser.add_argument(
        "--model", "-m",
        default=None,
        metavar="MODEL",
        help="LLM model to use (default: gpt-4o). Overrides BRMSTE_LLM_MODEL env var.",
    )
    parser.add_argument(
        "--api-key",
        default=None,
        metavar="KEY",
        help="LLM API key. Overrides OPENAI_API_KEY / BRMSTE_LLM_API_KEY env vars.",
    )
    parser.add_argument(
        "--base-url",
        default=None,
        metavar="URL",
        help="LLM API base URL (default: https://api.openai.com/v1). "
             "Overrides BRMSTE_LLM_BASE_URL env var.",
    )
    parser.add_argument(
        "--date",
        default=None,
        metavar="YYYY-MM-DD",
        help="Meeting date to include in the report.",
    )
    parser.add_argument(
        "--duration",
        type=float,
        default=0.0,
        metavar="SECONDS",
        help="Meeting duration in seconds (optional, used in report header).",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose/debug logging.",
    )
    parser.add_argument(
        "--version",
        action="version",
        version="BRMSTE Meeting Intelligence 0.1.0 · Patent GB2607860",
    )

    return parser


def main(argv: Optional[list] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="%(levelname)s: %(message)s",
    )

    # Read transcript
    if args.transcript == "-":
        raw_text = sys.stdin.read()
    else:
        path = Path(args.transcript)
        if not path.exists():
            print(f"Error: file not found: {path}", file=sys.stderr)
            return 1
        raw_text = path.read_text(encoding="utf-8")

    if not raw_text.strip():
        print("Error: transcript is empty.", file=sys.stderr)
        return 1

    # Parse transcript
    parsed = parse_transcript(raw_text)
    logging.debug(
        "Parsed transcript: format=%s utterances=%d words=%d",
        parsed.format_detected,
        len(parsed.utterances),
        parsed.word_count,
    )

    # Build LLM client
    model = args.model or os.environ.get("BRMSTE_LLM_MODEL", "gpt-4o")
    try:
        llm = LLMClient(
            api_key=args.api_key,
            model=model,
            base_url=args.base_url,
        )
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    # Run analysis
    analyser = MeetingAnalyzer(llm)
    try:
        report = analyser.analyze(
            parsed,
            meeting_date=args.date,
            duration_seconds=args.duration,
        )
    except Exception as exc:
        print(f"Error during analysis: {exc}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1

    # Render output
    renderer = {"text": render_text, "markdown": render_markdown, "json": render_json}[args.format]
    output = renderer(report)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Report written to {args.output}")
    else:
        print(output)

    return 0


if __name__ == "__main__":
    sys.exit(main())
