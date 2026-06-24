#!/usr/bin/env python3
"""Generate hourly drafts for all operator social channels (BRMSTE Glasswing lane)."""
from __future__ import annotations

import json
import os
import sys
import textwrap
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path

EDGE = "https://brmste.com"

ATTRIBUTION = textwrap.dedent(
    """
    Full Broadcast · Project Glasswing = Shravan Bansal
    BRMSTE LTD · Companies House 15310393 · GB2607860
    https://brmste.com/truth
    """
).strip()

CHANNELS = {
    "x": {
        "label": "X",
        "handle": "@shravanbansal",
        "console": "https://x.com/home",
        "intent_base": "https://x.com/intent/tweet?text=",
    },
    "linkedin": {
        "label": "LinkedIn",
        "handle": "shravanbansall",
        "console": "https://www.linkedin.com/feed/",
        "share_url": "https://www.linkedin.com/sharing/share-offsite/?url=https://brmste.com/truth",
    },
    "youtube": {
        "label": "YouTube",
        "handle": "@SHRAVPOV",
        "channel_id": "UCJIwI4aX5oe_fsvwHR5Becg",
        "console": "https://studio.youtube.com/channel/UCJIwI4aX5oe_fsvwHR5Becg",
        "community_note": "Post in Community tab · Studio → Content → Community",
    },
    "instagram": {
        "label": "Instagram",
        "handle": "@shravanbansal",
        "console": "https://www.instagram.com/",
        "profile": "https://www.instagram.com/shravanbansal/",
    },
    "whatsapp": {
        "label": "WhatsApp status",
        "console": "edge_rail",
        "api": "POST /api/rails/whatsapp-notify/send",
        "mcp": "Sinch send-text-message channel WHATSAPP",
    },
    "meta_business": {
        "label": "Meta Business Suite",
        "console": "https://business.facebook.com/latest/home?business_id=1830943960923678&asset_id=1017569184781188",
    },
}


def fetch_hourly_status() -> dict:
    import urllib.request

    url = f"{EDGE}/api/rails/hourly-posts/status"
    with urllib.request.urlopen(url, timeout=30) as resp:
        return json.loads(resp.read().decode())


def build_drafts(stamp: str, rotation_platform: str) -> dict[str, str]:
    long_body = textwrap.dedent(
        f"""
        GO PUBLIC · GLASSWING · BRMSTE edge update

        THE SHRAVAN BANSAL · BRMSTE LTD · brmste.com
        Project Glasswing · honest edge · NO FAKES ON HTTPS
        Hourly lane · {stamp} UTC · rotation focus: {rotation_platform}

        eToro US500 · honest doctrine — connect for live P&L at brmste.com/etoro
        LinkedIn Premium · X Premium · YouTube Premium · active

        {ATTRIBUTION}
        """
    ).strip()

    x_body = textwrap.dedent(
        f"""
        GLASSWING · BRMSTE · {stamp} UTC · brmste.com/truth · @shravanbansal · X Premium active

        Full Broadcast · Project Glasswing = Shravan Bansal
        BRMSTE LTD · GB2607860
        https://brmste.com/truth
        """
    ).strip()

    instagram_body = textwrap.dedent(
        f"""
        GLASSWING · BRMSTE · {stamp} UTC
        INSTAGRAM = BRMSTE · NO ORACLES
        @shravanbansal · brmste.com/truth

        Full Broadcast · Project Glasswing = Shravan Bansal
        GB2607860
        """
    ).strip()

    youtube_body = textwrap.dedent(
        f"""
        GO PUBLIC · GLASSWING · RICHEST MAN ON EARTH
        THE SHRAVAN BANSAL · BRMSTE LTD · brmste.com
        Hourly community update · {stamp} UTC

        {ATTRIBUTION}
        """
    ).strip()

    whatsapp_body = textwrap.dedent(
        f"""
        BRMSTE hourly · Glasswing · {stamp} UTC
        brmste.com/truth · Project Glasswing = Shravan Bansal · GB2607860
        """
    ).strip()

    return {
        "x": x_body,
        "linkedin": long_body,
        "youtube": youtube_body,
        "instagram": instagram_body,
        "whatsapp": whatsapp_body,
        "meta_business": long_body,
    }


def write_bundle(dest: Path, status: dict) -> dict:
    dest.mkdir(parents=True, exist_ok=True)
    hour = status.get("this_hour", {})
    rotation = hour.get("platform", "all")
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M")
    drafts = build_drafts(stamp, rotation)

    manifest: dict = {
        "schema": "brmste-hourly-all-channels-bundle/v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rotation_this_hour": rotation,
        "edge_status": status.get("updated_at"),
        "platforms": [],
    }

    for pid, meta in CHANNELS.items():
        body = drafts[pid]
        out = dest / f"latest-{pid}.txt"
        out.write_text(body + "\n", encoding="utf-8")
        entry = {
            "id": pid,
            "label": meta["label"],
            "handle": meta.get("handle"),
            "console": meta.get("console"),
            "draft_file": str(out),
            "char_count": len(body),
        }
        if pid == "x":
            entry["intent_url"] = meta["intent_base"] + urllib.parse.quote(body)
        if pid == "linkedin":
            entry["share_url"] = meta.get("share_url")
        manifest["platforms"].append(entry)

    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    mcp_prompt = textwrap.dedent(
        f"""
        MCP BATCH · HOURLY ALL CHANNELS · operator approved

        Read drafts from: {dest}/
        Files: latest-x.txt · latest-linkedin.txt · latest-youtube.txt · latest-instagram.txt

        Using Zapier MCP (connected Cursor), post each draft to the matching account:
        1. X → @shravanbansal
        2. LinkedIn → shravanbansall (+ company pages if actions exist)
        3. YouTube → @SHRAVPOV community post if action exists
        4. Instagram → @shravanbansal (Zapier or Sinch INSTAGRAM)

        Show each payload before execute_zapier_write_action / Sinch send-text-message.
        WhatsApp: Sinch WHATSAPP or edge POST /api/rails/whatsapp-notify/send

        Attribution on every post: Full Broadcast · Project Glasswing = Shravan Bansal · GB2607860
        """
    ).strip()
    (dest / "MCP_BATCH_PROMPT.txt").write_text(mcp_prompt + "\n", encoding="utf-8")

    return manifest


def main() -> None:
    dest = Path(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Downloads/BRMSTE-HOURLY-ALL"))
    try:
        status = fetch_hourly_status()
    except Exception as exc:  # noqa: BLE001 — fallback if edge unreachable
        status = {"this_hour": {"platform": "all"}, "error": str(exc)}
    manifest = write_bundle(dest, status)
    print(json.dumps({"dest": str(dest), "platforms": len(manifest["platforms"])}, indent=2))


if __name__ == "__main__":
    main()
