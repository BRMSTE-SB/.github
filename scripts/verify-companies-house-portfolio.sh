#!/usr/bin/env bash
# Verify the BRMSTE Companies House portfolio and its mini-account manifests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${COMPANIES_HOUSE_DIR:-$ROOT/data/companies-house}"
PORTFOLIO="${COMPANIES_HOUSE_PORTFOLIO:-$DIR/portfolio.json}"
ACCOUNTS_DIR="${COMPANIES_HOUSE_ACCOUNTS_DIR:-$DIR/accounts}"
ENTITIES_DIR="${COMPANIES_HOUSE_ENTITIES_DIR:-$DIR/entities}"

fail() { echo "COMPANIES HOUSE VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "COMPANIES HOUSE VERIFY OK: $*"; }

[[ -f "$PORTFOLIO" ]] || fail "portfolio manifest missing: $PORTFOLIO"
[[ -d "$ACCOUNTS_DIR" ]] || fail "accounts directory missing: $ACCOUNTS_DIR"

CH_NUMBER="15310393"
PARENT_ENTITY="BRMSTE LTD"

python3 - "$ROOT" "$PORTFOLIO" "$ACCOUNTS_DIR" "$ENTITIES_DIR" "$CH_NUMBER" "$PARENT_ENTITY" <<'PY'
import json, os, sys

root, portfolio_path, accounts_dir, entities_dir, ch_number, parent_entity = sys.argv[1:7]

def die(msg):
    raise SystemExit(f"{msg}")

portfolio = json.loads(open(portfolio_path).read())

if portfolio.get("schema") != "brmste-companies-house-portfolio/v1":
    die(f"{portfolio_path}: unexpected schema {portfolio.get('schema')!r}")

required_top = (
    "id", "headline", "entity", "companies_house", "operator",
    "mini_accounts", "count", "policy", "substrate",
)
for key in required_top:
    if key not in portfolio:
        die(f"{portfolio_path}: missing {key}")

if portfolio["companies_house"] != ch_number:
    die(f"{portfolio_path}: companies_house must be {ch_number}")
if portfolio["entity"] != parent_entity:
    die(f"{portfolio_path}: entity must be {parent_entity!r}")

mini = portfolio["mini_accounts"]
if not mini:
    die(f"{portfolio_path}: mini_accounts empty")
if portfolio["count"] != len(mini):
    die(f"{portfolio_path}: count {portfolio['count']} != {len(mini)} mini_accounts")

ids = [m.get("id", "") for m in mini]
if len(ids) != len(set(ids)):
    die(f"{portfolio_path}: duplicate mini_account ids")

required_summary = ("id", "name", "division", "role", "status", "manifest", "surface")
referenced = {}
for m in mini:
    for key in required_summary:
        if key not in m:
            die(f"{portfolio_path}: mini_account {m.get('id','?')} missing {key}")
    manifest_path = os.path.join(root, m["manifest"])
    if not os.path.isfile(manifest_path):
        die(f"{portfolio_path}: mini_account {m['id']} manifest not found: {m['manifest']}")
    referenced[m["id"]] = (m, manifest_path)

required_account = (
    "schema", "id", "account_type", "name", "division", "parent_entity",
    "companies_house", "patent", "operator", "role", "status", "settlement", "surface",
)

account_files = sorted(
    f for f in os.listdir(accounts_dir) if f.endswith(".json")
)
if not account_files:
    die(f"{accounts_dir}: no account manifests")

seen_ids = set()
for fname in account_files:
    apath = os.path.join(accounts_dir, fname)
    acct = json.loads(open(apath).read())
    if acct.get("schema") != "brmste-mini-account/v1":
        die(f"{apath}: unexpected schema {acct.get('schema')!r}")
    for key in required_account:
        if key not in acct:
            die(f"{apath}: missing {key}")
    if acct["account_type"] != "mini":
        die(f"{apath}: account_type must be 'mini'")
    if acct["companies_house"] != ch_number:
        die(f"{apath}: companies_house must be {ch_number}")
    if acct["parent_entity"] != parent_entity:
        die(f"{apath}: parent_entity must be {parent_entity!r}")
    if acct["patent"] != "GB2607860":
        die(f"{apath}: patent must be GB2607860")
    aid = acct["id"]
    seen_ids.add(aid)
    if aid not in referenced:
        die(f"{apath}: account id {aid!r} not referenced by portfolio")
    summary, _ = referenced[aid]
    if summary["name"] != acct["name"]:
        die(f"{apath}: name {acct['name']!r} != portfolio summary {summary['name']!r}")
    if summary["role"] != acct["role"]:
        die(f"{apath}: role {acct['role']!r} != portfolio summary {summary['role']!r}")
    print(f"account ok: {aid} ({acct['name']})")

missing = set(referenced) - seen_ids
if missing:
    die(f"{portfolio_path}: portfolio references accounts with no file: {sorted(missing)}")

related = portfolio.get("related_entities", [])
if related:
    if portfolio.get("related_entities_count") != len(related):
        die(
            f"{portfolio_path}: related_entities_count "
            f"{portfolio.get('related_entities_count')} != {len(related)} related_entities"
        )
    related_ids = [e.get("id", "") for e in related]
    if len(related_ids) != len(set(related_ids)):
        die(f"{portfolio_path}: duplicate related_entity ids")
    required_related = (
        "id", "name", "companies_house", "role", "status", "manifest", "companies_house_url",
    )
    for e in related:
        for key in required_related:
            if key not in e:
                die(f"{portfolio_path}: related_entity {e.get('id','?')} missing {key}")
        manifest_path = os.path.join(root, e["manifest"])
        if not os.path.isfile(manifest_path):
            die(f"{portfolio_path}: related_entity {e['id']} manifest not found: {e['manifest']}")
        entity = json.loads(open(manifest_path).read())
        allowed_schemas = ("brmste-companies-house-entity/v1", "brmste-us-entity/v1")
        if entity.get("schema") not in allowed_schemas:
            die(f"{manifest_path}: unexpected schema {entity.get('schema')!r}")
        if entity["id"] != e["id"]:
            die(f"{manifest_path}: id {entity['id']!r} != portfolio summary {e['id']!r}")
        if entity["name"] != e["name"]:
            die(f"{manifest_path}: name {entity['name']!r} != portfolio summary {e['name']!r}")
        if entity.get("companies_house") != e["companies_house"]:
            die(f"{manifest_path}: companies_house must match portfolio summary")
        print(f"related entity ok: {e['id']} ({e['name']})")

print(f"portfolio ok: {portfolio['headline']} — {len(mini)} mini account(s), {len(related)} related entity/entities")
PY

ok "Companies House portfolio and ${PORTFOLIO}"
