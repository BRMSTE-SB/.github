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


def today_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def psc_address_dto(canonical: dict[str, Any]) -> dict[str, str]:
    dto: dict[str, str] = {
        "premises": canonical.get("premises", ""),
        "address_line_1": canonical.get("address_line_1", ""),
        "locality": canonical.get("locality", ""),
        "postalCode": canonical.get("postal_code", ""),
        "country": canonical.get("country", "United Kingdom"),
    }
    if canonical.get("address_line_2"):
        dto["address_line_2"] = canonical["address_line_2"]
    if canonical.get("region"):
        dto["region"] = canonical["region"]
    return {k: v for k, v in dto.items() if v}


def officer_service_address(canonical: dict[str, Any]) -> dict[str, str]:
    return psc_address_dto(canonical)


def extract_resource_id(payload: dict[str, Any]) -> str | None:
    if payload.get("id"):
        return str(payload["id"])
    links = payload.get("links") or {}
    self_link = links.get("self") or ""
    if self_link:
        return self_link.rstrip("/").split("/")[-1]
    return None


def get_officers_list(cfg: dict[str, Any], company_number: str) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}/officers"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"Officers list failed HTTP {status}: {data}")
    return data


def get_officer_appointment(
    cfg: dict[str, Any], company_number: str, appointment_id: str
) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}/appointments/{appointment_id}"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"Officer appointment failed HTTP {status}: {data}")
    return data


def get_psc_individual(cfg: dict[str, Any], company_number: str, psc_id: str) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    if not api_key:
        raise SystemExit("Missing COMPANIES_HOUSE_API_KEY in Fort Knox (.env.fort-knox)")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}/persons-with-significant-control/individual/{psc_id}"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"PSC individual failed HTTP {status}: {data}")
    return data


def parse_appointment_id(officer_item: dict[str, Any]) -> str:
    self_link = (officer_item.get("links") or {}).get("self", "")
    if not self_link:
        raise SystemExit("Officer item missing links.self")
    return self_link.rstrip("/").split("/")[-1]


def parse_psc_id(psc_item: dict[str, Any]) -> str:
    self_link = (psc_item.get("links") or {}).get("self", "")
    if not self_link:
        raise SystemExit("PSC item missing links.self")
    return self_link.rstrip("/").split("/")[-1]


def filing_resource_post(
    cfg: dict[str, Any], access_token: str, transaction_id: str, path_suffix: str, body: dict[str, Any] | None = None
) -> tuple[int, dict[str, Any]]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}/{path_suffix}"
    status, data = http_request(
        "POST",
        url,
        headers=bearer_headers(access_token),
        body=body if body is not None else {},
    )
    if not isinstance(data, dict):
        return status, {"error": data}
    return status, data


def filing_resource_patch(
    cfg: dict[str, Any],
    access_token: str,
    transaction_id: str,
    path_suffix: str,
    body: dict[str, Any],
) -> tuple[int, dict[str, Any]]:
    hosts = api_hosts(cfg)
    url = f"{hosts['filing_api']}/transactions/{transaction_id}/{path_suffix}"
    status, data = http_request(
        "PATCH",
        url,
        headers=bearer_headers(access_token),
        body=body,
    )
    if not isinstance(data, dict):
        return status, {"error": data}
    return status, data


def find_director_officer(officers_payload: dict[str, Any]) -> dict[str, Any]:
    for item in officers_payload.get("items") or []:
        if item.get("officer_role") == "director" and not item.get("resigned_on"):
            return item
    raise SystemExit("No active director found in officers list")


def find_individual_psc(cfg: dict[str, Any], company_number: str) -> dict[str, Any]:
    api_key = env("COMPANIES_HOUSE_API_KEY")
    hosts = api_hosts(cfg)
    url = f"{hosts['public_api']}/company/{company_number}/persons-with-significant-control"
    status, data = http_request("GET", url, basic_user=api_key, basic_pass="")
    if status != 200:
        raise SystemExit(f"PSC list failed HTTP {status}: {data}")
    for item in data.get("items") or []:
        if item.get("kind") == "individual-person-with-significant-control" and not item.get("ceased_on"):
            return item
    raise SystemExit("No active individual PSC found")


def build_ch01_patch_body(
    director_item: dict[str, Any],
    appointment: dict[str, Any],
    canonical: dict[str, Any],
) -> dict[str, Any]:
    appointment_id = parse_appointment_id(director_item)
    return {
        "referenceAppointmentId": appointment_id,
        "referenceEtag": appointment.get("etag") or director_item.get("etag", ""),
        "referenceOfficerListEtag": director_item.get("etag", ""),
        "serviceAddress": officer_service_address(canonical),
        "residentialAddressSameAsServiceAddress": True,
    }


def build_psc04_patch_body(psc_live: dict[str, Any], psc_id: str, canonical: dict[str, Any]) -> dict[str, Any]:
    name_elements = psc_live.get("name_elements") or {}
    dob = psc_live.get("date_of_birth") or {}
    body: dict[str, Any] = {
        "referencePscId": psc_id,
        "referenceEtag": psc_live.get("etag", ""),
        "registerEntryDate": today_iso(),
        "address": psc_address_dto(canonical),
        "residentialAddressSameAsCorrespondenceAddress": True,
        "nationality": psc_live.get("nationality", ""),
        "countryOfResidence": psc_live.get("country_of_residence", "United Kingdom"),
        "nameElements": {
            "title": name_elements.get("title", ""),
            "forename": name_elements.get("forename", ""),
            "surname": name_elements.get("surname", ""),
        },
        "dateOfBirth": {
            "month": dob.get("month"),
            "year": dob.get("year"),
        },
        "naturesOfControl": psc_live.get("natures_of_control") or [],
    }
    return body


def try_file_officer_ch01(
    cfg: dict[str, Any],
    access_token: str,
    transaction_id: str,
    company_number: str,
    canonical: dict[str, Any],
) -> tuple[str, dict[str, Any]]:
    officers = get_officers_list(cfg, company_number)
    director = find_director_officer(officers)
    appointment_id = parse_appointment_id(director)
    appointment = get_officer_appointment(cfg, company_number, appointment_id)
    create_status, create_body = filing_resource_post(
        cfg, access_token, transaction_id, "officers", {}
    )
    if create_status not in (200, 201):
        return "skip", {"step": "create_officer_resource", "status": create_status, "body": create_body}
    filing_id = extract_resource_id(create_body)
    if not filing_id:
        return "skip", {"step": "create_officer_resource", "status": create_status, "body": create_body}
    patch_body = build_ch01_patch_body(director, appointment, canonical)
    patch_status, patch_body_resp = filing_resource_patch(
        cfg,
        access_token,
        transaction_id,
        f"officers/{filing_id}",
        patch_body,
    )
    ok = patch_status in (200, 201, 204)
    return (
        "ok" if ok else "skip",
        {
            "step": "patch_officer_ch01",
            "filing_resource_id": filing_id,
            "status": patch_status,
            "body": patch_body_resp,
        },
    )


def try_file_psc04(
    cfg: dict[str, Any],
    access_token: str,
    transaction_id: str,
    company_number: str,
    canonical: dict[str, Any],
) -> tuple[str, dict[str, Any]]:
    psc_item = find_individual_psc(cfg, company_number)
    psc_id = parse_psc_id(psc_item)
    psc_live = get_psc_individual(cfg, company_number, psc_id)
    create_status, create_body = filing_resource_post(
        cfg,
        access_token,
        transaction_id,
        "persons-with-significant-control/individual",
        {},
    )
    if create_status not in (200, 201):
        return "skip", {"step": "create_psc_resource", "status": create_status, "body": create_body}
    filing_id = extract_resource_id(create_body)
    if not filing_id:
        return "skip", {"step": "create_psc_resource", "status": create_status, "body": create_body}
    patch_body = build_psc04_patch_body(psc_live, psc_id, canonical)
    patch_status, patch_body_resp = filing_resource_patch(
        cfg,
        access_token,
        transaction_id,
        f"persons-with-significant-control/individual/{filing_id}",
        patch_body,
    )
    ok = patch_status in (200, 201, 204)
    return (
        "ok" if ok else "skip",
        {
            "step": "patch_psc04",
            "filing_resource_id": filing_id,
            "status": patch_status,
            "body": patch_body_resp,
        },
    )


def load_brmste_address_register() -> dict[str, Any]:
    if not BRMSTE_ADDRESS_REGISTER.is_file():
        raise SystemExit(f"Missing {BRMSTE_ADDRESS_REGISTER.relative_to(ROOT)}")
    return json.loads(BRMSTE_ADDRESS_REGISTER.read_text())


def roa_compare_key(addr: dict[str, Any]) -> str:
    line1 = str(addr.get("address_line_1", "")).strip().lower()
    premises = str(addr.get("premises", "")).strip().lower()
    if premises and premises not in line1:
        line1 = f"{premises} {line1}".strip()
    country_raw = str(addr.get("country", "")).strip().lower()
    if country_raw in ("england", "united kingdom", "uk", "great britain"):
        country_norm = "uk"
        region_norm = ""
    else:
        country_norm = country_raw
        region_norm = str(addr.get("region", "")).strip().lower()
    parts = [
        line1,
        str(addr.get("address_line_2", "")).strip().lower(),
        str(addr.get("locality", "")).strip().lower(),
        region_norm,
        str(addr.get("postal_code", "")).strip().lower().replace(" ", ""),
        country_norm,
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
            reg["filing"]["psc_correspondence"]["filed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            reg["filing"]["director_correspondence"]["filed_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        elif psc_status == "pending":
            reg["status"] = "psc_and_director_address_update_pending"
    if transaction_id and psc_status == "filed":
        reg["filing"]["correspondence_api"] = {
            "transaction_id": transaction_id,
            "company_number": "15310393",
            "filed_via": "companies_house_api",
            "filed_at": datetime.now(timezone.utc).isoformat(),
            "forms": ["PSC04", "CH01"],
        }
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
        print("next: bash scripts/file-companies-house-brmste-api.sh file-correspondence --mark-filed")
        print("  or:  bash scripts/file-companies-house-brmste-api.sh file-it --mark-filed")
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


def cmd_file_correspondence(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] != "brmste":
        raise SystemExit("file-correspondence is only for --target brmste")
    reg = load_brmste_address_register()
    horseferry = horseferry_from_register(reg)
    company_number = target["company_number"]

    if not correspondence_update_pending(reg):
        print(f"horseferry_correspondence=aligned display={horseferry.get('display')}")
        return

    access_token = get_access_token(cfg)
    txn = create_transaction(cfg, access_token, company_number)
    transaction_id = txn.get("id") or txn.get("transaction_id")
    if not transaction_id:
        raise SystemExit(f"Transaction missing id: {txn}")
    print(f"transaction_open id={transaction_id}")

    ch01_status, ch01_detail = try_file_officer_ch01(
        cfg, access_token, transaction_id, company_number, horseferry
    )
    print(f"director_ch01={ch01_status} detail={json.dumps(ch01_detail)[:400]}")

    psc_status, psc_detail = try_file_psc04(
        cfg, access_token, transaction_id, company_number, horseferry
    )
    print(f"psc04={psc_status} detail={json.dumps(psc_detail)[:400]}")

    if ch01_status != "ok" or psc_status != "ok":
        raise SystemExit(
            "Correspondence filing incomplete — check OAuth scopes include "
            "officers.update and persons-with-significant-control.update for 15310393"
        )

    closed = close_transaction(cfg, access_token, transaction_id)
    print(f"transaction_closed id={transaction_id} status={closed.get('status', 'closed')}")

    final = get_transaction(cfg, access_token, transaction_id)
    filings = final.get("filings") or final.get("filing_status")
    print(f"filings={json.dumps(filings)[:400] if filings else 'pending'}")

    if args.mark_filed:
        update_brmste_address_register(
            roa_status=reg["filing"]["registered_office_api"].get("status", "aligned"),
            transaction_id=transaction_id,
            psc_status="filed",
        )
        print(f"register_updated {BRMSTE_ADDRESS_REGISTER.relative_to(ROOT)}")


def cmd_file_it(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] != "brmste":
        raise SystemExit("file-it is only for --target brmste")
    reg = load_brmste_address_register()
    horseferry = horseferry_from_register(reg)
    print(f"target=brmste company={target['company_number']} correspondence={horseferry.get('display')}")

    try:
        access_token = get_access_token(cfg)
    except SystemExit as exc:
        print("")
        print("BLOCKED: OAuth required for live filing.")
        print(str(exc))
        if env("COMPANIES_HOUSE_OAUTH_CLIENT_ID"):
            print(build_oauth_url(cfg, target))
        else:
            print("Import OAuth client from Mac: bash scripts/import-companies-house-keys-mac.sh")
        print("")
        print("After exchange, re-run:")
        print("  bash scripts/file-companies-house-brmste-api.sh file-it --mark-filed")
        print("")
        print("WebFiling fallback (PSC04 + CH01): docs/BRMSTE-COMPANIES-HOUSE-ADDRESS.md")
        raise SystemExit(1) from exc

    _ = access_token
    cmd_update_address(args)
    reg = load_brmste_address_register()
    if correspondence_update_pending(reg):
        cmd_file_correspondence(args)
    else:
        print("horseferry_correspondence=already_aligned")


def cmd_verify_api_key(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    hub = cfg.get("api", {}).get("developer_hub", {})
    profile = get_company_profile(cfg, target["company_number"])
    print(json.dumps(
        {
            "status": "ok",
            "api_env": hub.get("api_key_env", "COMPANIES_HOUSE_API_KEY"),
            "api_env_set": bool(env("COMPANIES_HOUSE_API_KEY")),
            "developer_hub_application_id": hub.get("application_id"),
            "company_number": profile.get("company_number"),
            "company_name": profile.get("company_name"),
            "company_status": profile.get("company_status"),
            "registered_office": profile.get("registered_office_address"),
        },
        indent=2,
    ))


def cmd_file(args: argparse.Namespace) -> None:
    cfg = load_config()
    target = get_target(cfg, args.target)
    if target["id"] == "brmste":
        cmd_file_it(args)
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
    sub.add_parser("verify-api-key", help="Verify live API key against public company profile")
    p_addr = sub.add_parser("update-address", help="File ROA + register PSC04 pending (brmste)")
    p_addr.add_argument("--mark-filed", action="store_true")

    p_corr = sub.add_parser(
        "file-correspondence",
        help="File PSC04 + CH01 Horseferry correspondence (brmste, OAuth)",
    )
    p_corr.add_argument("--mark-filed", action="store_true")

    p_it = sub.add_parser("file-it", help="File ROA if needed + PSC04 + CH01 (brmste)")
    p_it.add_argument("--mark-filed", action="store_true")

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
        "file-correspondence": cmd_file_correspondence,
        "file-it": cmd_file_it,
        "verify-api-key": cmd_verify_api_key,
    }[args.cmd](args)


if __name__ == "__main__":
    main()
