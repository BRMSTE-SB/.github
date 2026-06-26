#!/usr/bin/env python3
"""GOV.UK Companies House API — public data + OAuth filing for BRMSTE partner companies."""
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
BRMSTE_ADDRESS_REGISTER = ROOT / "data" / "brmste-ltd-companies-house-register.json"
DEFAULT_TARGET = "harrods"


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text())


def get_target(cfg: dict[str, Any], target_id: str) -> dict[str, Any]:
    targets = cfg.get("targets") or {}
    if target_id not in targets:
        raise SystemExit(f"Unknown target '{target_id}'. Valid: {', '.join(sorted(targets))}")
    return targets[target_id]


def filing_register_path(target: dict[str, Any]) -> Path:
    rel = target.get("filing_register")
    if not rel:
        raise SystemExit(f"Target {target['id']} missing filing_register")
    return ROOT / rel


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


def get_company_profile(cfg: dict[str, Any], company_number: str) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"Company profile failed HTTP {status}: {data}")
    return data


def build_oauth_url(cfg: dict[str, Any], target: dict[str, Any], state: str | None = None) -> str:
    client_id = env("COMPANIES_HOUSE_OAUTH_CLIENT_ID")
    redirect_uri = env(
        "COMPANIES_HOUSE_OAUTH_REDIRECT_URI",
        cfg["oauth"]["redirect_uri_default"],
    )
    if not client_id:
        raise SystemExit("Missing COMPANIES_HOUSE_OAUTH_CLIENT_ID in Fort Knox")
    hosts = api_hosts(cfg)
    scope_key = target.get("oauth_scopes_key", "scopes_for_harrods")
    scope = " ".join(cfg["oauth"].get(scope_key, cfg["oauth"]["scopes_for_harrods"]))
    oauth_state = state or f"brmste-{target['id']}"
    params = {
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": scope,
        "state": oauth_state,
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


def create_transaction(cfg: dict[str, Any], access_token: str, company_number: str) -> dict[str, Any]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions"
    status, data = http_request(
        "POST",
        url,
        headers=bearer_headers(access_token),
        body={"company_number": company_number},
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


def get_access_token(cfg: dict[str, Any]) -> str:
    access_token = env("COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN")
    if not access_token and env("COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN"):
        tokens = refresh_access_token(cfg)
        access_token = tokens.get("access_token", "")
        print("access_token=refreshed")
    if not access_token:
        raise SystemExit("No OAuth access token. Run oauth-url flow first.")
    return access_token


def load_brmste_address_register() -> dict[str, Any]:
    if not BRMSTE_ADDRESS_REGISTER.is_file():
        raise SystemExit(f"Missing {BRMSTE_ADDRESS_REGISTER.relative_to(ROOT)}")
    return json.loads(BRMSTE_ADDRESS_REGISTER.read_text())


def roa_compare_key(addr: dict[str, Any]) -> str:
    parts = [
        str(addr.get("premises", "")).strip().lower(),
        str(addr.get("address_line_1", "")).strip().lower(),
        str(addr.get("address_line_2", "")).strip().lower(),
        str(addr.get("locality", "")).strip().lower(),
        str(addr.get("region", "")).strip().lower(),
        str(addr.get("postal_code", "")).strip().lower().replace(" ", ""),
        str(addr.get("country", "")).strip().lower(),
    ]
    return "|".join(parts)


def get_registered_office_address(cfg: dict[str, Any], company_number: str) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}/registered-office-address"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"Registered office address failed HTTP {status}: {data}")
    return data


def try_create_registered_office_change(
    cfg: dict[str, Any],
    access_token: str,
    transaction_id: str,
    canonical: dict[str, Any],
    reference_etag: str,
) -> tuple[str, dict[str, Any]]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}/registered-office-address"
    body = {
        "accept_appropriate_office_address_statement": canonical.get(
            "accept_appropriate_office_address_statement", True
        ),
        "premises": canonical.get("premises", ""),
        "address_line_1": canonical.get("address_line_1", ""),
        "address_line_2": canonical.get("address_line_2", ""),
        "locality": canonical.get("locality", ""),
        "region": canonical.get("region", ""),
        "postal_code": canonical.get("postal_code", ""),
        "country": canonical.get("country", "United Kingdom"),
        "reference_etag": reference_etag,
    }
    body = {k: v for k, v in body.items() if v is not None and v != ""}
    status, data = http_request(
        "POST",
        url,
        headers=bearer_headers(access_token),
        body=body,
    )
    return ("ok" if status in (200, 201) else "skip"), {"status": status, "body": data}


def update_brmste_address_register(
    *,
    roa_status: str,
    roa_filed_at: str | None = None,
    transaction_id: str | None = None,
    psc_status: str | None = None,
) -> None:
    reg = load_brmste_address_register()
    if roa_status == "filed":
        reg["registered_office"]["status"] = "filed"
        reg["registered_office"]["matches_canonical"] = True
        if roa_filed_at:
            reg["registered_office"]["filed_at"] = roa_filed_at
    elif roa_status == "aligned":
        reg["registered_office"]["matches_canonical"] = True
    reg["filing"]["registered_office_api"]["status"] = roa_status
    if transaction_id:
        reg["filing"]["api"] = {
            "transaction_id": transaction_id,
            "company_number": "15310393",
            "filed_via": "companies_house_api",
            "filed_at": datetime.now(timezone.utc).isoformat(),
            "target_id": "brmste",
            "kind": "registered_office_address",
        }
    if psc_status:
        reg["psc"]["correspondence_address"]["status"] = psc_status
        reg["filing"]["psc_correspondence"]["status"] = psc_status
        if psc_status == "filed":
            reg["status"] = "address_sync_complete"
            reg["director"]["correspondence_address"]["status"] = "filed"
            reg["filing"]["director_correspondence"]["status"] = "filed"
        elif psc_status == "pending":
            reg["status"] = "psc_and_director_address_update_pending"
    BRMSTE_ADDRESS_REGISTER.write_text(json.dumps(reg, indent=2) + "\n")


def update_filing_register(
    target: dict[str, Any],
    transaction_id: str,
    channel: str = "govuk_api",
) -> None:
    filing_path = filing_register_path(target)
    reg = json.loads(filing_path.read_text())
    reg["filing"]["channel"] = channel
    reg["filing"]["status"] = "filed"
    reg["filing"]["filed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    reg["filing"]["api"] = {
        "transaction_id": transaction_id,
        "company_number": target["company_number"],
        "filed_via": "companies_house_api",
        "filed_at": datetime.now(timezone.utc).isoformat(),
        "target_id": target["id"],
    }
    reg["status"] = "filed"
    filing_path.write_text(json.dumps(reg, indent=2) + "\n")


def cmd_profile(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    profile = get_company_profile(cfg, target["company_number"])
    print(json.dumps(
        {
            "target": target["id"],
            "company_number": profile.get("company_number"),
            "company_name": profile.get("company_name"),
            "company_status": profile.get("company_status"),
            "registered_office": profile.get("registered_office_address"),
            "confirmation_statement": profile.get("confirmation_statement"),
            "can_file": profile.get("can_file"),
        },
        indent=2,
    ))


def cmd_oauth_url(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    print(build_oauth_url(cfg, target))
    print("")
    auth_env = target.get("auth_code_env", "COMPANIES_HOUSE_AUTH_CODE")
    print(f"Sign in with Companies House account + enter {target['legal_name']} auth code when prompted.")
    print(f"Auth code env: {auth_env}")
    print("Then exchange the callback code:")
    print(f"  python3 scripts/companies_house_api.py --target {args.target} exchange --code '<code>'")


def cmd_exchange(args: argparse.Namespace) -> None:
    cfg = load_config()
    tokens = exchange_code(cfg, args.code)
    print(json.dumps({k: tokens.get(k) for k in ("token_type", "expires_in", "scope")}, indent=2))
    print("")
    print("Add to .env.fort-knox (never commit):")
    print(f"COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN={tokens.get('access_token', '')}")
    if tokens.get("refresh_token"):
        print(f"COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN={tokens.get('refresh_token', '')}")


def roa_canonical_from_register(reg: dict[str, Any]) -> dict[str, Any]:
    ro = reg.get("registered_office", {}).get("address")
    if ro:
        return ro
    return reg.get("canonical_address", {})


def horseferry_from_register(reg: dict[str, Any]) -> dict[str, Any]:
    hf = reg.get("horseferry_correspondence", {}).get("address")
    if hf:
        return hf
    return reg.get("psc", {}).get("correspondence_address", {}).get("canonical", {})


def correspondence_update_pending(reg: dict[str, Any]) -> bool:
    hf_postal = horseferry_from_register(reg).get("postal_code", "")
    psc_prev = reg.get("psc", {}).get("correspondence_address", {}).get("previous_public_register", {})
    return psc_prev.get("postal_code") != hf_postal


def cmd_compare_address(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] != "brmste":
        raise SystemExit("compare-address is only for --target brmste")
    reg = load_brmste_address_register()
    canonical = roa_canonical_from_register(reg)
    horseferry = horseferry_from_register(reg)
    live_roa = get_registered_office_address(cfg, target["company_number"])
    live_key = roa_compare_key(live_roa)
    canon_key = roa_compare_key(canonical)
    psc_prev = reg["psc"]["correspondence_address"]["previous_public_register"]
    print(json.dumps(
        {
            "company_number": target["company_number"],
            "addresses_policy": reg.get("addresses_policy", {}).get("allowed_only"),
            "registered_office": {
                "live": live_roa,
                "canonical_display": canonical.get("display"),
                "matches_canonical": live_key == canon_key,
            },
            "horseferry_correspondence": {
                "canonical_display": horseferry.get("display"),
                "previous_public_display": psc_prev.get("display"),
                "update_required": correspondence_update_pending(reg),
            },
            "psc_url": reg["company_profile"]["psc_url"],
            "officers_url": reg["company_profile"].get("officers_url"),
        },
        indent=2,
    ))


def cmd_update_address(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] != "brmste":
        raise SystemExit("update-address is only for --target brmste")
    reg = load_brmste_address_register()
    canonical = roa_canonical_from_register(reg)
    horseferry = horseferry_from_register(reg)
    company_number = target["company_number"]
    profile = get_company_profile(cfg, company_number)
    print(f"target=brmste name={profile.get('company_name')} status={profile.get('company_status')}")

    live_roa = get_registered_office_address(cfg, company_number)
    needs_roa = roa_compare_key(live_roa) != roa_compare_key(canonical)
    reference_etag = live_roa.get("etag", "")
    if not reference_etag:
        raise SystemExit("Live registered office missing etag — cannot file ROA change")

    access_token = get_access_token(cfg)
    transaction_id: str | None = None
    roa_status = "aligned"

    if needs_roa:
        txn = create_transaction(cfg, access_token, company_number)
        transaction_id = txn.get("id") or txn.get("transaction_id")
        if not transaction_id:
            raise SystemExit(f"Transaction missing id: {txn}")
        roa_result, roa_body = try_create_registered_office_change(
            cfg, access_token, transaction_id, canonical, reference_etag
        )
        print(f"registered_office={roa_result} detail={json.dumps(roa_body)[:300]}")
        if roa_result != "ok":
            raise SystemExit(f"Registered office filing failed: {roa_body}")
        closed = close_transaction(cfg, access_token, transaction_id)
        print(f"transaction_closed id={transaction_id} status={closed.get('status', 'closed')}")
        roa_status = "filed"
    else:
        print("registered_office=aligned skip AD01 — live matches canonical Basingstoke")

    psc_pending = correspondence_update_pending(reg)
    if psc_pending:
        print(f"horseferry_correspondence=pending PSC04+CH01 → {horseferry.get('display')}")
        print("psc_correspondence=pending file PSC04 via WebFiling — docs/BRMSTE-COMPANIES-HOUSE-ADDRESS.md")
        print(f"psc_url={reg['company_profile']['psc_url']}")
        print(f"officers_url={reg['company_profile'].get('officers_url')}")

    if args.mark_filed:
        update_brmste_address_register(
            roa_status=roa_status,
            roa_filed_at=datetime.now(timezone.utc).strftime("%Y-%m-%d") if roa_status == "filed" else None,
            transaction_id=transaction_id,
            psc_status="pending" if psc_pending else "filed",
        )
        print(f"register_updated {BRMSTE_ADDRESS_REGISTER.relative_to(ROOT)}")


def cmd_file(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] == "brmste":
        cmd_update_address(args)
        return
    company_number = target["company_number"]
    profile = get_company_profile(cfg, company_number)
    print(f"target={target['id']} name={profile.get('company_name')} status={profile.get('company_status')}")

    access_token = env("COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN")
    if not access_token and env("COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN"):
        tokens = refresh_access_token(cfg)
        access_token = tokens.get("access_token", "")
        print("access_token=refreshed")
    if not access_token:
        print("ERROR: No OAuth access token. Run oauth-url flow first.", file=sys.stderr)
        print(build_oauth_url(cfg, target), file=sys.stderr)
        sys.exit(1)

    txn = create_transaction(cfg, access_token, company_number)
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
        update_filing_register(target, transaction_id)
        print(f"register_updated {filing_register_path(target).relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Companies House API — BRMSTE partner filings")
    parser.add_argument(
        "--target",
        default=DEFAULT_TARGET,
        help="Filing target id (brmste, harrods, ubs, american-express, ...)",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("profile", help="GET company profile via public API")
    sub.add_parser("oauth-url", help="Print OAuth authorize URL for filing")
    sub.add_parser("compare-address", help="Compare live ROA vs canonical (brmste)")
    p_addr = sub.add_parser("update-address", help="File ROA + register PSC04 pending (brmste)")
    p_addr.add_argument("--mark-filed", action="store_true")

    p_ex = sub.add_parser("exchange", help="Exchange OAuth code for tokens")
    p_ex.add_argument("--code", required=True)

    p_file = sub.add_parser("file", help="Create transaction, file, close")
    p_file.add_argument("--mark-filed", action="store_true")

    args = parser.parse_args()
    {
        "profile": cmd_profile,
        "oauth-url": cmd_oauth_url,
        "exchange": cmd_exchange,
        "file": cmd_file,
        "compare-address": cmd_compare_address,
        "update-address": cmd_update_address,
    }[args.cmd](args)


if __name__ == "__main__":
    main()
