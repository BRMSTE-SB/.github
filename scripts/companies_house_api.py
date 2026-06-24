#!/usr/bin/env python3
"""GOV.UK Companies House API — public data + OAuth filing for HARRODS LIMITED (00030209)."""
from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "data" / "companies-house-api-config.json"
FILING_REGISTER = ROOT / "data" / "companies-house-harrods-filing.json"
HARRODS_NUMBER = "00030209"


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text())


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def api_hosts(cfg: dict[str, Any]) -> dict[str, str]:
    mode = env("COMPANIES_HOUSE_API_ENV", cfg["api"]["env_default"])
    return cfg["api"][mode if mode in ("live", "sandbox") else "live"]


def http_request(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    body: dict[str, Any] | None = None,
    basic_user: str = "",
    basic_pass: str = "",
) -> tuple[int, Any]:
    data = None
    req_headers = dict(headers or {})
    if body is not None:
        data = json.dumps(body).encode()
        req_headers.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    if basic_user or basic_pass:
        token = base64.b64encode(f"{basic_user}:{basic_pass}".encode()).decode()
        req.add_header("Authorization", f"Basic {token}")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode(errors="replace")
        try:
            payload: Any = json.loads(raw) if raw else {"error": raw}
        except json.JSONDecodeError:
            payload = {"error": raw}
        return exc.code, payload


def get_company_profile(cfg: dict[str, Any]) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{HARRODS_NUMBER}"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"Company profile failed HTTP {status}: {data}")
    return data


def build_oauth_url(cfg: dict[str, Any], state: str = "brmste-harrods") -> str:
    client_id = env("COMPANIES_HOUSE_OAUTH_CLIENT_ID")
    redirect_uri = env(
        "COMPANIES_HOUSE_OAUTH_REDIRECT_URI",
        cfg["oauth"]["redirect_uri_default"],
    )
    if not client_id:
        raise SystemExit("Missing COMPANIES_HOUSE_OAUTH_CLIENT_ID in Fort Knox")
    hosts = api_hosts(cfg)
    scope = " ".join(cfg["oauth"]["scopes_for_harrods"])
    params = {
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": scope,
        "state": state,
    }
    return f"{hosts['identity']}{cfg['oauth']['authorize_path']}?{urllib.parse.urlencode(params)}"


def exchange_code(cfg: dict[str, Any], code: str) -> dict[str, Any]:
    client_id = env("COMPANIES_HOUSE_OAUTH_CLIENT_ID")
    client_secret = env("COMPANIES_HOUSE_OAUTH_CLIENT_SECRET")
    redirect_uri = env(
        "COMPANIES_HOUSE_OAUTH_REDIRECT_URI",
        cfg["oauth"]["redirect_uri_default"],
    )
    if not client_id or not client_secret:
        raise SystemExit("Missing OAuth client ID/secret in Fort Knox")
    hosts = api_hosts(cfg)
    url = f"{hosts['identity']}{cfg['oauth']['token_path']}"
    form = urllib.parse.urlencode(
        {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "client_id": client_id,
            "client_secret": client_secret,
        }
    ).encode()
    req = urllib.request.Request(
        url,
        data=form,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def refresh_access_token(cfg: dict[str, Any]) -> dict[str, Any]:
    client_id = env("COMPANIES_HOUSE_OAUTH_CLIENT_ID")
    client_secret = env("COMPANIES_HOUSE_OAUTH_CLIENT_SECRET")
    refresh = env("COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN")
    if not all([client_id, client_secret, refresh]):
        raise SystemExit("Missing refresh token or OAuth client credentials")
    hosts = api_hosts(cfg)
    url = f"{hosts['identity']}{cfg['oauth']['token_path']}"
    form = urllib.parse.urlencode(
        {
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": client_id,
            "client_secret": client_secret,
        }
    ).encode()
    req = urllib.request.Request(
        url,
        data=form,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def bearer_headers(access_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {access_token}"}


def create_transaction(cfg: dict[str, Any], access_token: str) -> dict[str, Any]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions"
    status, data = http_request(
        "POST",
        url,
        headers=bearer_headers(access_token),
        body={"company_number": HARRODS_NUMBER},
    )
    if status not in (200, 201):
        raise SystemExit(f"Create transaction failed HTTP {status}: {data}")
    return data


def close_transaction(cfg: dict[str, Any], access_token: str, transaction_id: str) -> dict[str, Any]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}"
    status, data = http_request(
        "PUT",
        url,
        headers=bearer_headers(access_token),
        body={"status": "closed"},
    )
    if status not in (200, 202):
        raise SystemExit(f"Close transaction failed HTTP {status}: {data}")
    return data


def get_transaction(cfg: dict[str, Any], access_token: str, transaction_id: str) -> dict[str, Any]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}"
    status, data = http_request("GET", url, headers=bearer_headers(access_token))
    if status != 200:
        raise SystemExit(f"Get transaction failed HTTP {status}: {data}")
    return data


def try_create_confirmation_statement(
    cfg: dict[str, Any], access_token: str, transaction_id: str
) -> tuple[str, dict[str, Any]]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}/confirmation-statement"
    status, data = http_request("POST", url, headers=bearer_headers(access_token), body={})
    return ("ok" if status in (200, 201) else "skip"), {"status": status, "body": data}


def update_filing_register(transaction_id: str, channel: str = "govuk_api") -> None:
    reg = json.loads(FILING_REGISTER.read_text())
    reg["filing"]["channel"] = channel
    reg["filing"]["status"] = "filed"
    reg["filing"]["filed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    reg["filing"]["api"] = {
        "transaction_id": transaction_id,
        "company_number": HARRODS_NUMBER,
        "filed_via": "companies_house_api",
        "filed_at": datetime.now(timezone.utc).isoformat(),
    }
    reg["status"] = "filed"
    FILING_REGISTER.write_text(json.dumps(reg, indent=2) + "\n")


def cmd_profile(_: argparse.Namespace) -> None:
    cfg = load_config()
    profile = get_company_profile(cfg)
    print(json.dumps(
        {
            "company_number": profile.get("company_number"),
            "company_name": profile.get("company_name"),
            "company_status": profile.get("company_status"),
            "registered_office": profile.get("registered_office_address"),
            "confirmation_statement": profile.get("confirmation_statement"),
            "can_file": profile.get("can_file"),
        },
        indent=2,
    ))


def cmd_oauth_url(_: argparse.Namespace) -> None:
    cfg = load_config()
    print(build_oauth_url(cfg))
    print("")
    print("Sign in with Companies House account + enter HARRODS auth code when prompted.")
    print("Then exchange the callback code:")
    print("  python3 scripts/companies_house_api.py exchange --code '<code>'")


def cmd_exchange(args: argparse.Namespace) -> None:
    cfg = load_config()
    tokens = exchange_code(cfg, args.code)
    print(json.dumps({k: tokens.get(k) for k in ("token_type", "expires_in", "scope")}, indent=2))
    print("")
    print("Add to .env.fort-knox (never commit):")
    print(f"COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN={tokens.get('access_token', '')}")
    if tokens.get("refresh_token"):
        print(f"COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN={tokens.get('refresh_token', '')}")


def cmd_file(args: argparse.Namespace) -> None:
    cfg = load_config()
    profile = get_company_profile(cfg)
    print(f"harrods={profile.get('company_name')} status={profile.get('company_status')}")

    access_token = env("COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN")
    if not access_token and env("COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN"):
        tokens = refresh_access_token(cfg)
        access_token = tokens.get("access_token", "")
        print("access_token=refreshed")
    if not access_token:
        print("ERROR: No OAuth access token. Run oauth-url flow first.", file=sys.stderr)
        print(build_oauth_url(cfg), file=sys.stderr)
        sys.exit(1)

    txn = create_transaction(cfg, access_token)
    transaction_id = txn.get("id") or txn.get("transaction_id")
    if not transaction_id:
        raise SystemExit(f"Transaction missing id: {txn}")

    cs_status, cs_body = try_create_confirmation_statement(cfg, access_token, transaction_id)
    print(f"confirmation_statement={cs_status} detail={json.dumps(cs_body)[:200]}")

    closed = close_transaction(cfg, access_token, transaction_id)
    print(f"transaction_closed id={transaction_id} status={closed.get('status', 'closed')}")

    final = get_transaction(cfg, access_token, transaction_id)
    filings = final.get("filings") or final.get("filing_status")
    print(f"filings={json.dumps(filings)[:300] if filings else 'pending'}")

    if args.mark_filed:
        update_filing_register(transaction_id)
        print(f"register_updated {FILING_REGISTER.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Companies House API — HARRODS LIMITED")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("profile", help="GET company profile via public API")
    sub.add_parser("oauth-url", help="Print OAuth authorize URL for Harrods filing")

    p_ex = sub.add_parser("exchange", help="Exchange OAuth code for tokens")
    p_ex.add_argument("--code", required=True)

    p_file = sub.add_parser("file", help="Create transaction, file, close — on behalf of Harrods")
    p_file.add_argument("--mark-filed", action="store_true")

    args = parser.parse_args()
    {
        "profile": cmd_profile,
        "oauth-url": cmd_oauth_url,
        "exchange": cmd_exchange,
        "file": cmd_file,
    }[args.cmd](args)


if __name__ == "__main__":
    main()
