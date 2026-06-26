#!/usr/bin/env python3
"""GOV.UK Companies House Streaming API — live events for BRMSTE lane companies."""
from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Iterator

ROOT = Path(__file__).resolve().parents[1]
ENDPOINTS_PATH = ROOT / "data" / "brmste-live-companies-house-endpoints.json"
CONFIG_PATH = ROOT / "data" / "companies-house-api-config.json"


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def load_endpoints() -> dict[str, Any]:
    return json.loads(ENDPOINTS_PATH.read_text())


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text())


def api_env_name() -> str:
    return env("COMPANIES_HOUSE_API_ENV", "live")


def streaming_base(endpoints: dict[str, Any]) -> str:
    mode = api_env_name()
    hosts = endpoints.get("hosts", {})
    block = hosts.get(mode if mode in hosts else "live", hosts["live"])
    return block["streaming_api"].rstrip("/")


def public_api_base(endpoints: dict[str, Any]) -> str:
    mode = api_env_name()
    hosts = endpoints.get("hosts", {})
    block = hosts.get(mode if mode in hosts else "live", hosts["live"])
    return block["public_api"].rstrip("/")


def filing_api_base(cfg: dict[str, Any]) -> str:
    mode = api_env_name()
    api = cfg.get("api", {})
    block = api.get(mode if mode in api else "live", api["live"])
    return block["filing_api"].rstrip("/")


def basic_auth_header(api_key: str) -> str:
    token = base64.b64encode(f"{api_key}:".encode()).decode()
    return f"Basic {token}"


def company_number_from_event(payload: dict[str, Any]) -> str | None:
    data = payload.get("data") or {}
    for key in ("company_number", "companyNumber", "company_id"):
        val = data.get(key)
        if val:
            return str(val)
    resource_uri = payload.get("resource_uri") or ""
    if "/company/" in resource_uri:
        segment = resource_uri.split("/company/")[-1].split("/")[0]
        if segment:
            return segment
    return None


def iter_stream_lines(url: str, api_key: str, timeout: float = 120.0) -> Iterator[str]:
    req = urllib.request.Request(url)
    req.add_header("Authorization", basic_auth_header(api_key))
    req.add_header("Accept", "application/json")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        while True:
            line = resp.readline()
            if not line:
                break
            yield line.decode(errors="replace").strip()


def cmd_list_endpoints(args: argparse.Namespace) -> None:
    reg = load_endpoints()
    out: dict[str, Any] = {
        "schema": reg.get("schema"),
        "status": reg.get("status"),
        "watch_company_numbers": reg.get("watch_company_numbers"),
        "streaming_base": streaming_base(reg),
        "streams": [
            {
                "id": s["id"],
                "url": f"{streaming_base(reg)}{s['path']}",
                "description": s.get("description"),
            }
            for s in reg.get("streaming", {}).get("streams", [])
        ],
        "public_read": reg.get("public_read", {}).get("endpoints", []),
        "filing": reg.get("filing", {}).get("endpoints", []),
        "targets": {
            tid: {
                "legal_name": t.get("legal_name"),
                "company_number": t.get("company_number"),
                "filing_register": t.get("filing_register"),
            }
            for tid, t in reg.get("targets", {}).items()
        },
    }
    if args.target:
        target = reg.get("targets", {}).get(args.target)
        if not target:
            raise SystemExit(f"Unknown target '{args.target}'")
        cn = target["company_number"]
        out["target_urls"] = {
            "public_profile": f"{public_api_base(reg)}/company/{cn}",
            "registered_office": f"{public_api_base(reg)}/company/{cn}/registered-office-address",
            "filing_history": f"{public_api_base(reg)}/company/{cn}/filing-history",
        }
    print(json.dumps(out, indent=2))


def cmd_verify_key(args: argparse.Namespace) -> None:
    reg = load_endpoints()
    api_key = env("COMPANIES_HOUSE_STREAMING_API_KEY")
    if not api_key:
        raise SystemExit(
            "Missing COMPANIES_HOUSE_STREAMING_API_KEY — register Streaming API app in Developer Hub"
        )
    base = streaming_base(reg)
    url = f"{base}/companies"
    if args.timepoint:
        url = f"{url}?timepoint={urllib.parse.quote(args.timepoint)}"
    try:
        req = urllib.request.Request(url)
        req.add_header("Authorization", basic_auth_header(api_key))
        with urllib.request.urlopen(req, timeout=15) as resp:
            first = resp.readline().decode(errors="replace").strip()
            print(json.dumps(
                {
                    "status": "ok",
                    "http_status": resp.status,
                    "streaming_base": base,
                    "first_line_preview": first[:200] if first else "(heartbeat/empty)",
                    "env": api_env_name(),
                },
                indent=2,
            ))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")[:300]
        raise SystemExit(f"Streaming verify failed HTTP {exc.code}: {body}")


def cmd_stream(args: argparse.Namespace) -> None:
    reg = load_endpoints()
    api_key = env("COMPANIES_HOUSE_STREAMING_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_STREAMING_API_KEY in Fort Knox")

    streams = reg.get("streaming", {}).get("streams", [])
    stream_def = next((s for s in streams if s["id"] == args.stream), None)
    if not stream_def:
        raise SystemExit(f"Unknown stream '{args.stream}'. Valid: {', '.join(s['id'] for s in streams)}")

    watch = set(args.company_numbers or reg.get("watch_company_numbers", []))
    base = streaming_base(reg)
    path = stream_def["path"]
    query: dict[str, str] = {}
    if args.timepoint:
        query["timepoint"] = args.timepoint
    url = f"{base}{path}"
    if query:
        url = f"{url}?{urllib.parse.urlencode(query)}"

    print(f"stream={args.stream} url={url} watch={sorted(watch)} max_events={args.max_events}")
    matched = 0
    total = 0
    for line in iter_stream_lines(url, api_key, timeout=args.timeout):
        if not line:
            continue
        total += 1
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            print(f"skip_non_json line={line[:120]}")
            continue
        cn = company_number_from_event(payload)
        if watch and cn and cn not in watch:
            continue
        if watch and not cn:
            continue
        matched += 1
        event = payload.get("event", {})
        print(json.dumps(
            {
                "company_number": cn,
                "resource_kind": payload.get("resource_kind"),
                "type": event.get("type"),
                "published_at": event.get("published_at"),
                "timepoint": event.get("timepoint"),
                "resource_uri": payload.get("resource_uri"),
            },
            indent=2,
        ))
        if args.verbose:
            print(json.dumps(payload, indent=2))
        if matched >= args.max_events:
            break
    print(f"done matched={matched} lines_read={total}")


def cmd_poll_transaction(args: argparse.Namespace) -> None:
    cfg = load_config()
    reg = load_endpoints()
    access = env("COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN")
    if not access:
        raise SystemExit("Missing COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN")
    base = filing_api_base(cfg)
    url = f"{base}/transactions/{args.transaction_id}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {access}")
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode())
    print(json.dumps(data, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Companies House Streaming API — BRMSTE live lane")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("list-endpoints", help="List all live streaming + read + filing endpoints")
    p_list.add_argument("--target", help="Filing target id for URL expansion (e.g. brmste)")

    p_verify = sub.add_parser("verify-key", help="Verify streaming API key (opens companies stream)")
    p_verify.add_argument("--timepoint", default="")

    p_stream = sub.add_parser("stream", help="Read events from a streaming endpoint")
    p_stream.add_argument(
        "--stream",
        default="filings",
        help="Stream id: companies, filings, officers, persons-with-significant-control, ...",
    )
    p_stream.add_argument("--timepoint", default="", help="Resume from timepoint")
    p_stream.add_argument("--max-events", type=int, default=5, help="Max matching events before exit")
    p_stream.add_argument("--timeout", type=float, default=120.0, help="Connection read timeout seconds")
    p_stream.add_argument(
        "--company-numbers",
        nargs="*",
        help="Filter to company numbers (default: BRMSTE lane watch list)",
    )
    p_stream.add_argument("--verbose", action="store_true", help="Print full event JSON")

    p_poll = sub.add_parser("poll-transaction", help="GET filing transaction status")
    p_poll.add_argument("transaction_id", help="Transaction id from POST /transactions")

    args = parser.parse_args()
    {
        "list-endpoints": cmd_list_endpoints,
        "verify-key": cmd_verify_key,
        "stream": cmd_stream,
        "poll-transaction": cmd_poll_transaction,
    }[args.cmd](args)


if __name__ == "__main__":
    main()
