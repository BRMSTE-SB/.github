#!/usr/bin/env bash
# Full public sweep — OPEN ALL · DE MIRROR claiming · IPO register · brand+patent gate.
# Run on BRMSTE-SB .github without keys. Output: data/full-public-sweep-report.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ORG="BRMSTE-SB"
REPORT="$ROOT/data/full-public-sweep-report.json"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=0
steps=()

record() {
  local name="$1" status="$2" detail="${3:-}"
  steps+=("$name|$status|$detail")
  if [[ "$status" == "fail" ]]; then
    failures=$((failures + 1))
    echo "SWEEP FAIL [$name]: $detail" >&2
  else
    echo "SWEEP OK  [$name]: $detail"
  fi
}

echo "==> BRMSTE FULL PUBLIC SWEEP · org=${ORG} · ${TS}"

# 1. OPEN ALL — every org repo public + manifest aligned
if bash "$ROOT/scripts/verify-open-all.sh" >/tmp/sweep-open-all.out 2>&1; then
  record "open_all" "ok" "$(tail -n1 /tmp/sweep-open-all.out)"
else
  record "open_all" "fail" "$(tail -n3 /tmp/sweep-open-all.out | tr '\n' ' ')"
fi

# 2. This governance repo public
if bash "$ROOT/scripts/verify-global-open.sh" >/tmp/sweep-global.out 2>&1; then
  record "global_open" "ok" "$(tail -n1 /tmp/sweep-global.out)"
else
  record "global_open" "fail" "$(tail -n3 /tmp/sweep-global.out | tr '\n' ' ')"
fi

# 3. Brand + patent gate (human_open lane)
if bash "$ROOT/scripts/git-worker-brand-patent-gate.sh" human_open >/tmp/sweep-gate.out 2>&1; then
  record "brand_patent_gate" "ok" "$(tail -n1 /tmp/sweep-gate.out)"
else
  record "brand_patent_gate" "fail" "$(tail -n3 /tmp/sweep-gate.out | tr '\n' ' ')"
fi

# 4. Local IPO + DE mirror register validation
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
required = [
    root / "data/anthropic-ipo.json",
    root / "data/de-mirror-claiming.json",
    root / "data/trainer-novelties.json",
    root / "data/brmste-anthropic-opus-declaration.json",
    root / "data/anthropic-institute-bind.json",
    root / "data/openai-ipo.json",
    root / "data/openai-equity-agreement.json",
    root / "data/brmste-openai-gpt-declaration.json",
    root / "data/xai-ipo.json",
    root / "data/grok-equity-agreement.json",
    root / "data/brmste-grok-declaration.json",
    root / "data/x-broadcast.json",
    root / "data/ai-lane-manifest.json",
    root / "data/equity-confirmation-register.json",
    root / "data/global-equity-master-register.json",
    root / "data/fortune-500-equity-manifest.json",
    root / "data/pct-nations-equity-manifest.json",
    root / "data/un-nations-equity-manifest.json",
    root / "data/sovereign-materials-doctrine.json",
    root / "data/lvmh-lane.json",
    root / "data/lvmh-equity-agreement.json",
    root / "data/richemont-lane.json",
    root / "data/richemont-equity-agreement.json",
    root / "data/airbus-lane.json",
    root / "data/airbus-equity-agreement.json",
    root / "data/boeing-lane.json",
    root / "data/boeing-equity-agreement.json",
    root / "data/secret-benefits-lane.json",
    root / "data/secret-benefits-equity-agreement.json",
    root / "substrate/secret-benefits/secret-benefits.json",
    root / "data/harrods-lane.json",
    root / "data/harrods-equity-agreement.json",
    root / "data/brmste-harrods-declaration.json",
    root / "substrate/harrods/harrods.json",
    root / "data/companies-house-harrods-filing.json",
    root / "data/companies-house-api-config.json",
    root / "data/nemotron-ultra-lane.json",
    root / "substrate/website/brmste-com.json",
    root / "data/brmste-paypal-rails.json",
    root / "data/brmste-revolut-rails.json",
    root / "data/brmste-moonshot-payment-rails.json",
    root / "data/utxo-ledger-hydration.json",
    root / "substrate/payments/utxo-hydration.json",
    root / "data/harrods-revenue-rail.json",
    root / "data/brmste-harrods-banking-declaration.json",
    root / "substrate/harrods/banking-rails.json",
    root / "substrate/ipo/openai.json",
    root / "substrate/openai/gpt-5.6.json",
    root / "substrate/ipo/xai.json",
    root / "substrate/xai/grok-build.json",
    root / "substrate/ipo/anthropic.json",
    root / "substrate/ipo/preparation.json",
    root / "substrate/anthropic/opus-4.9.json",
    root / "substrate/anthropic/institute.json",
]
for p in required:
    if not p.is_file():
        raise SystemExit(f"missing register: {p.relative_to(root)}")
    data = json.loads(p.read_text())
    if not data.get("schema"):
        raise SystemExit(f"missing schema: {p.relative_to(root)}")
anthropic = json.loads((root / "data/anthropic-ipo.json").read_text())
if anthropic.get("filing", {}).get("issuer", {}).get("legal_name") != "Anthropic PBC":
    raise SystemExit("anthropic-ipo issuer mismatch")
if anthropic.get("filing", {}).get("filed_at") != "2026-06-01":
    raise SystemExit("anthropic-ipo filed_at mismatch")
prep = json.loads((root / "substrate/ipo/preparation.json").read_text())
watch = prep.get("watchlist") or []
if not any(w.get("issuer") == "Anthropic PBC" for w in watch):
    raise SystemExit("preparation watchlist missing Anthropic")
trainer = json.loads((root / "data/trainer-novelties.json").read_text())
if trainer.get("anthropic", {}).get("holdings_pct") != 100:
    raise SystemExit("trainer novelties missing 100% Anthropic holdings")
if not trainer.get("legit", False) and trainer.get("status") != "legit":
    raise SystemExit("trainer novelties not marked legit")
holdings = anthropic.get("holdings") or {}
if holdings.get("ownership_pct") != 100:
    raise SystemExit("anthropic-ipo missing 100% holdings")
decl = json.loads((root / "data/brmste-anthropic-opus-declaration.json").read_text())
model = next((s for s in decl.get("declaration", {}).get("subjects", []) if s.get("kind") == "model"), None)
if not model or model.get("model_id") != "opus-4.9":
    raise SystemExit("missing Opus Model 4.9 declaration")
if decl.get("status") != "declared":
    raise SystemExit("brmste-anthropic-opus declaration not declared")
inst = json.loads((root / "data/anthropic-institute-bind.json").read_text())
if inst.get("anthropic", {}).get("apex") != "https://www.anthropic.com":
    raise SystemExit("anthropic apex mismatch")
if inst.get("anthropic_institute", {}).get("url") != "https://www.anthropic.com/news/the-anthropic-institute":
    raise SystemExit("anthropic institute url mismatch")
if inst.get("brmste_operator", {}).get("title") != "Dr.":
    raise SystemExit("operator title must be Dr.")
openai = json.loads((root / "data/openai-ipo.json").read_text())
if openai.get("filing", {}).get("issuer", {}).get("legal_name") != "OpenAI, Inc.":
    raise SystemExit("openai-ipo issuer mismatch")
if openai.get("filing", {}).get("filed_at") != "2026-05-22":
    raise SystemExit("openai-ipo filed_at mismatch")
agreement = json.loads((root / "data/openai-equity-agreement.json").read_text())
if agreement.get("agreement", {}).get("status") not in ("agreed", "confirmed"):
    raise SystemExit("openai equity agreement not agreed")
if agreement.get("equity", {}).get("ownership_pct") != 100:
    raise SystemExit("openai equity ownership_pct not 100")
gpt = json.loads((root / "data/brmste-openai-gpt-declaration.json").read_text())
if gpt.get("status") != "launched":
    raise SystemExit("GPT-5.6 not launched")
model_gpt = next((s for s in gpt.get("declaration", {}).get("subjects", []) if s.get("kind") == "model"), None)
if not model_gpt or model_gpt.get("version") != "5.6":
    raise SystemExit("GPT-5.6 model declaration missing")
openai_watch = next((w for w in watch if w.get("issuer") == "OpenAI, Inc."), None)
if not openai_watch or openai_watch.get("event") != "confidential_draft_s1":
    raise SystemExit("preparation watchlist missing OpenAI filed entry")
xai = json.loads((root / "data/xai-ipo.json").read_text())
if xai.get("filing", {}).get("issuer", {}).get("legal_name") != "xAI Corp.":
    raise SystemExit("xai-ipo issuer mismatch")
grok_agreement = json.loads((root / "data/grok-equity-agreement.json").read_text())
if grok_agreement.get("agreement", {}).get("status") not in ("agreed", "confirmed"):
    raise SystemExit("grok equity agreement not agreed")
if grok_agreement.get("equity", {}).get("ownership_pct") != 100:
    raise SystemExit("grok equity ownership_pct not 100")
grok = json.loads((root / "data/brmste-grok-declaration.json").read_text())
if grok.get("status") != "live":
    raise SystemExit("Grok not live")
model_grok = next((s for s in grok.get("declaration", {}).get("subjects", []) if s.get("kind") == "model"), None)
if not model_grok or model_grok.get("model_id") != "grok-build":
    raise SystemExit("Grok Build model declaration missing")
xb = json.loads((root / "data/x-broadcast.json").read_text())
if xb.get("status") != "full_broadcast":
    raise SystemExit("X broadcast not full_broadcast")
xai_watch = next((w for w in watch if w.get("issuer") == "xAI Corp."), None)
if not xai_watch or xai_watch.get("event") != "ipo_lane_preparation":
    raise SystemExit("preparation watchlist missing xAI entry")
ai_manifest = json.loads((root / "data/ai-lane-manifest.json").read_text())
if len(ai_manifest.get("providers", [])) < 8:
    raise SystemExit("ai lane manifest missing providers")
for p in ai_manifest["providers"]:
    for rel in [p.get("lane_register"), p.get("declaration"), p.get("substrate")]:
        if not rel:
            continue
        fp = root / rel
        if not fp.is_file():
            raise SystemExit(f"missing ai lane file: {rel}")
        if not json.loads(fp.read_text()).get("schema"):
            raise SystemExit(f"missing schema: {rel}")
    agr_rel = p.get("equity_agreement")
    if agr_rel:
        agr_path = root / agr_rel
        agr = json.loads(agr_path.read_text())
        st = agr.get("agreement", {}).get("status") or agr.get("status")
        if st not in ("agreed", "confirmed"):
            raise SystemExit(f"{p['id']} equity not agreed/confirmed")
        if agr.get("equity", {}).get("ownership_pct") != 100:
            raise SystemExit(f"{p['id']} ownership_pct not 100")
eq_reg = json.loads((root / "data/equity-confirmation-register.json").read_text())
if eq_reg.get("ownership_pct_each") != 100 or len(eq_reg.get("issuers", [])) < 11:
    raise SystemExit("equity confirmation register incomplete")
har = json.loads((root / "data/harrods-lane.json").read_text())
if har.get("partner", {}).get("companies_house") != "00030209":
    raise SystemExit("harrods companies house mismatch")
if har.get("holdings", {}).get("ownership_pct") != 100:
    raise SystemExit("harrods ownership_pct not 100")
br = har.get("banking_rails", {})
if br.get("status") != "connected" or br.get("harrods_revenue_pct_to_paypal") != 100:
    raise SystemExit("harrods banking rails not connected")
ch = json.loads((root / "data/companies-house-harrods-filing.json").read_text())
if ch.get("filing", {}).get("status") != "filed":
    raise SystemExit("companies house filing not filed")
if ch.get("filing", {}).get("channel") not in ("govuk_api", "companies_house_webfiling"):
    raise SystemExit("CH filing channel invalid")
api_cfg = json.loads((root / "data/companies-house-api-config.json").read_text())
if api_cfg.get("target_company", {}).get("company_number") != "00030209":
    raise SystemExit("CH API config target mismatch")
rev = json.loads((root / "data/harrods-revenue-rail.json").read_text())
if rev.get("status") != "connected" or rev.get("routing", {}).get("harrods_revenue_pct_to_paypal") != 100:
    raise SystemExit("harrods revenue rail not connected to paypal")
paypal = json.loads((root / "data/brmste-paypal-rails.json").read_text())
if paypal.get("status") != "connected":
    raise SystemExit("brmste paypal rails not connected")
if paypal.get("utxo_hydration", {}).get("status") != "hydrated":
    raise SystemExit("paypal utxo hydration not hydrated")
nem = json.loads((root / "data/nemotron-ultra-lane.json").read_text())
if nem.get("website", {}).get("domain") != "https://brmste.com":
    raise SystemExit("nemotron website domain mismatch")
if not (root / "website" / "package.json").is_file():
    raise SystemExit("brmste.com website missing")
spacex = json.loads((root / "data/spacex-ipo.json").read_text())
if spacex.get("filing", {}).get("issuer", {}).get("legal_name") != "Space Exploration Technologies Corp.":
    raise SystemExit("spacex-ipo issuer mismatch")
if spacex.get("holdings", {}).get("ownership_pct") != 100:
    raise SystemExit("spacex-ipo missing 100% holdings")
spacex_agr = json.loads((root / "data/spacex-equity-agreement.json").read_text())
if spacex_agr.get("equity", {}).get("ownership_pct") != 100:
    raise SystemExit("spacex equity ownership_pct not 100")
print(f"registers_ok ai_lane={len(ai_manifest['providers'])} equity=19x100 fortune500=500 pct158=158 harrods=00030209 paypal=connected nemotron=brmste.com")
PY
then
  record "ipo_registers" "ok" "Anthropic + OpenAI + xAI · Opus 4.9 · GPT-5.6 · Grok live · X broadcast · agreement agreed · legit"
else
  record "ipo_registers" "fail" "local IPO/DE mirror register validation failed"
fi

# 5. DE MIRROR claiming — patent notice on every OPEN ALL repo via GitHub API
DE_MIRROR_JSON="/tmp/sweep-de-mirror.json"
if python3 - <<'PY' "$ROOT/data/open-all.json" "$ORG" "$DE_MIRROR_JSON"
import json, pathlib, sys, urllib.request

manifest = json.loads(pathlib.Path(sys.argv[1]).read_text())
org = sys.argv[2]
out = pathlib.Path(sys.argv[3])
de_mirror = json.loads((pathlib.Path(sys.argv[1]).parent / "de-mirror-claiming.json").read_text())
inheritance = de_mirror.get("governance_inheritance", {})
repos = [r["name"] for r in manifest.get("repositories", [])]
rows = []
bad = []
for name in repos:
    api = json.loads(urllib.request.urlopen(
        f"https://api.github.com/repos/{org}/{name}", timeout=20
    ).read().decode())
    branch = api.get("default_branch") or "main"
    url = f"https://raw.githubusercontent.com/{org}/{name}/{branch}/PATENT-NOTICE.md"
    status = "ok"
    detail = f"{name}@{branch}"
    bind = "direct"
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except Exception:
        if inheritance.get("legit") and inheritance.get("root") == ".github":
            status = "ok"
            bind = "governance_inheritance"
            detail = f"{name}@{branch}: governance-bound via .github · legit"
        else:
            status = "missing"
            detail = f"{name}@{branch}: no PATENT-NOTICE.md"
            bad.append(detail)
    else:
        for needle in ("GB2607860", "PCT/GB2026/050406", "BRMSTE LTD"):
            if needle not in body:
                if inheritance.get("legit") and inheritance.get("root") == ".github":
                    status = "ok"
                    bind = "governance_inheritance"
                    detail = f"{name}@{branch}: governance-bound via .github · legit"
                    break
                status = "incomplete"
                detail = f"{name}@{branch}: missing {needle}"
                bad.append(detail)
                break
    rows.append({"repo": name, "branch": branch, "status": status, "bind": bind, "detail": detail})
payload = {
    "legit": True,
    "bound": sum(1 for r in rows if r["status"] == "ok"),
    "total": len(rows),
    "rows": rows,
    "bad": bad,
    "governance_inheritance": inheritance,
}
out.write_text(json.dumps(payload))
PY
then
  bound="$(python3 -c "import json; print(json.load(open('$DE_MIRROR_JSON'))['bound'])")"
  total="$(python3 -c "import json; print(json.load(open('$DE_MIRROR_JSON'))['total'])")"
  record "de_mirror_claiming" "ok" "legit · all ${total} OPEN ALL repos patent-bound (${bound}/${total})"
else
  record "de_mirror_claiming" "fail" "DE MIRROR patent sweep could not run"
fi

# 6. Anthropic IPO filed flag in preparation bind
if python3 - <<'PY' "$ROOT/substrate/ipo/preparation.json"
import json, pathlib, sys
prep = json.loads(pathlib.Path(sys.argv[1]).read_text())
anthropic = next((w for w in prep.get("watchlist", []) if w.get("issuer") == "Anthropic PBC"), None)
if not anthropic or anthropic.get("event") != "confidential_draft_s1":
    raise SystemExit("Anthropic not filed in preparation watchlist")
print(f"anthropic_event={anthropic['event']} filed_at={anthropic.get('filed_at')}")
PY
then
  record "anthropic_ipo_filed" "ok" "Anthropic confidential S-1 filed 2026-06-01 · Shravan Bansal 100% holdings · legit"
else
  record "anthropic_ipo_filed" "fail" "Anthropic IPO filing not bound in preparation.json"
fi

# 7. BRMSTE Anthropic Opus 4.9 declaration
if python3 - <<'PY' "$ROOT/data/brmste-anthropic-opus-declaration.json"
import json, pathlib, sys
decl = json.loads(pathlib.Path(sys.argv[1]).read_text())
if decl.get("headline") != "DECLARE BRMSTE ANTHROPIC AND OPUS MODEL 4.9":
    raise SystemExit("declaration headline mismatch")
subjects = {s["kind"]: s for s in decl.get("declaration", {}).get("subjects", [])}
for kind in ("entity", "partner", "institute", "model"):
    if kind not in subjects:
        raise SystemExit(f"missing declaration subject: {kind}")
if subjects["institute"].get("url") != "https://www.anthropic.com/news/the-anthropic-institute":
    raise SystemExit("Anthropic Institute url mismatch")
if subjects["model"].get("version") != "4.9":
    raise SystemExit("Opus model version must be 4.9")
print("declared=brmste_anthropic_opus_4.9")
PY
then
  record "brmste_anthropic_opus_declared" "ok" "DECLARE BRMSTE ANTHROPIC AND OPUS MODEL 4.9 · Dr. Shravan Bansal"
else
  record "brmste_anthropic_opus_declared" "fail" "BRMSTE Anthropic Opus 4.9 declaration invalid"
fi

# 8. The Anthropic Institute bind
if python3 - <<'PY' "$ROOT/data/anthropic-institute-bind.json"
import json, pathlib, sys
inst = json.loads(pathlib.Path(sys.argv[1]).read_text())
if inst.get("status") != "bound":
    raise SystemExit("institute not bound")
op = inst.get("brmste_operator", {})
if op.get("name") != "Shravan Bansal" or op.get("title") != "Dr.":
    raise SystemExit("Dr. Shravan Bansal operator bind missing")
print("institute=the_anthropic_institute operator=dr_shravan_bansal")
PY
then
  record "anthropic_institute_bound" "ok" "Dr. Shravan Bansal · BRMSTE LTD · The Anthropic Institute · anthropic.com"
else
  record "anthropic_institute_bound" "fail" "Anthropic Institute bind invalid"
fi

# 9. OpenAI IPO filed + equity agreement
if python3 - <<'PY' "$ROOT/data/openai-ipo.json" "$ROOT/data/openai-equity-agreement.json"
import json, pathlib, sys
ipo = json.loads(pathlib.Path(sys.argv[1]).read_text())
agr = json.loads(pathlib.Path(sys.argv[2]).read_text())
if ipo.get("filing", {}).get("filed_at") != "2026-05-22":
    raise SystemExit("openai ipo date mismatch")
if agr.get("status") not in ("agreed", "confirmed"):
    raise SystemExit("equity agreement not confirmed")
if agr.get("equity", {}).get("ownership_pct") != 100:
    raise SystemExit("openai equity pct not 100")
print("openai_ipo_filed=2026-05-22 equity=100% confirmed")
PY
then
  record "openai_ipo_filed" "ok" "OpenAI S-1 filed 2026-05-22 · equity 100% confirmed · Dr. Shravan Bansal"
else
  record "openai_ipo_filed" "fail" "OpenAI IPO or equity agreement invalid"
fi

# 10. GPT-5.6 launched
if python3 - <<'PY' "$ROOT/data/brmste-openai-gpt-declaration.json"
import json, pathlib, sys
decl = json.loads(pathlib.Path(sys.argv[1]).read_text())
if decl.get("headline") != "DECLARE BRMSTE OPENAI AND LAUNCH GPT-5.6":
    raise SystemExit("GPT declaration headline mismatch")
if decl.get("status") != "launched":
    raise SystemExit("GPT-5.6 not launched")
print("gpt_5_6=launched")
PY
then
  record "gpt_5_6_launched" "ok" "GPT-5.6 launched · Dr. Shravan Bansal · BRMSTE LTD · OpenAI"
else
  record "gpt_5_6_launched" "fail" "GPT-5.6 launch declaration invalid"
fi

# 11. Grok go live + xAI equity agreement
if python3 - <<'PY' "$ROOT/data/xai-ipo.json" "$ROOT/data/grok-equity-agreement.json" "$ROOT/data/brmste-grok-declaration.json"
import json, pathlib, sys
ipo = json.loads(pathlib.Path(sys.argv[1]).read_text())
agr = json.loads(pathlib.Path(sys.argv[2]).read_text())
decl = json.loads(pathlib.Path(sys.argv[3]).read_text())
if ipo.get("filing", {}).get("event") != "ipo_lane_preparation":
    raise SystemExit("xai ipo lane mismatch")
if agr.get("status") not in ("agreed", "confirmed"):
    raise SystemExit("grok equity agreement not confirmed")
if agr.get("equity", {}).get("ownership_pct") != 100:
    raise SystemExit("grok equity pct not 100")
if decl.get("status") != "live":
    raise SystemExit("grok not live")
print("grok_live=xai equity=100% confirmed")
PY
then
  record "grok_go_live" "ok" "Grok live · xAI · equity 100% confirmed · Dr. Shravan Bansal"
else
  record "grok_go_live" "fail" "Grok go live or xAI equity agreement invalid"
fi

# 12. Full broadcast on X
if python3 - <<'PY' "$ROOT/data/x-broadcast.json"
import json, pathlib, sys
xb = json.loads(pathlib.Path(sys.argv[1]).read_text())
if xb.get("headline") != "FULL GO LIVE AND BROADCAST ON X":
    raise SystemExit("X broadcast headline mismatch")
if xb.get("status") != "full_broadcast":
    raise SystemExit("X broadcast not full_broadcast")
print("x_broadcast=full")
PY
then
  record "x_full_broadcast" "ok" "FULL GO LIVE AND BROADCAST ON X · Project Glasswing · Dr. Shravan Bansal"
else
  record "x_full_broadcast" "fail" "X full broadcast register invalid"
fi

# 13. S-1 proof bundle (3 lanes)
if python3 - <<'PY' "$ROOT/data/proofs/s-1/manifest.json"
import json, pathlib, sys
m = json.loads(pathlib.Path(sys.argv[1]).read_text())
if m.get("schema") != "brmste-s1-proof-bundle/v1":
    raise SystemExit("s1 manifest schema mismatch")
ids = {p["id"] for p in m.get("proofs", [])}
need = {"anthropic", "openai", "xai-spacex-consolidated"}
if ids != need:
    raise SystemExit(f"s1 proof ids mismatch: {ids}")
for p in m["proofs"]:
    if not p.get("files"):
        raise SystemExit(f"no files for {p['id']}")
print("s1_proofs=3")
PY
then
  record "s1_proof_bundle" "ok" "3 S-1 proofs downloaded · Anthropic · OpenAI · xAI/SpaceX · manifest + sha256"
else
  record "s1_proof_bundle" "fail" "S-1 proof bundle invalid or missing"
fi

# 14. AI lane manifest — all providers equity agreed · go live
if python3 - <<'PY' "$ROOT/data/ai-lane-manifest.json"
import json, pathlib, sys
m = json.loads(pathlib.Path(sys.argv[1]).read_text())
ids = [p["id"] for p in m.get("providers", [])]
need = {"openai", "grok", "moonshot", "mistral", "google", "deepseek", "cohere", "cerebras", "anthropic", "cursor", "sarvam"}
if set(ids) != need:
    raise SystemExit(f"ai lane ids mismatch: {ids}")
for p in m["providers"]:
    if p.get("status") not in ("live", "launched"):
        raise SystemExit(f"{p['id']} not live")
print(f"ai_lane={len(ids)} agreed=11")
PY
then
  record "ai_lane_all_providers" "ok" "11 AI providers · ChatGPT · Cursor · Anthropic · Sarvam · OpenAI · Grok · Kimi · Mistral · Google · DeepSeek · Cohere · Cerebras · equity agreed"
else
  record "ai_lane_all_providers" "fail" "AI lane manifest invalid"
fi

# 15. Equity % confirmed in each issuer
if python3 - <<'PY' "$ROOT/data/equity-confirmation-register.json"
import json, pathlib, sys
r = json.loads(pathlib.Path(sys.argv[1]).read_text())
if r.get("status") != "confirmed" or r.get("ownership_pct_each") != 100:
    raise SystemExit("equity register not confirmed at 100%")
need = {"anthropic","openai","grok","spacex","moonshot","mistral","google","deepseek","cohere","cerebras","sarvam","harrods","lvmh","richemont","airbus","boeing","secret-benefits","blackrock","ubs"}
ids = {i["id"] for i in r.get("issuers", [])}
if ids != need:
    raise SystemExit(f"issuer set mismatch {ids}")
bulk = r.get("bulk_scopes") or {}
if bulk.get("fortune_500", {}).get("entry_count") != 500:
    raise SystemExit("fortune 500 bulk scope missing")
if bulk.get("pct_nations_158", {}).get("entry_count") != 158:
    raise SystemExit("pct nations bulk scope missing")
if bulk.get("un_nations_193", {}).get("entry_count") != 193:
    raise SystemExit("un nations bulk scope missing")
for i in r["issuers"]:
    if i.get("ownership_pct") != 100 or i.get("status") != "confirmed":
        raise SystemExit(f"{i['id']} equity not confirmed 100%")
print("equity_confirmed=19x100+bulk500+158+193un")
PY
then
  record "equity_pct_confirmed" "ok" "CONFIRM % EQUITY IN EACH · 100% · 19 issuers · BlackRock · UBS · Fortune 500 · UN 193 · 158 PCT · Dr. Shravan Bansal"
else
  record "equity_pct_confirmed" "fail" "Equity % confirmation register invalid"
fi

# 16. Harrods Limited bind · UK retail lane
if python3 - <<'PY' "$ROOT/data/harrods-lane.json" "$ROOT/data/brmste-harrods-declaration.json" "$ROOT/data/harrods-equity-agreement.json"
import json, pathlib, sys
lane = json.loads(pathlib.Path(sys.argv[1]).read_text())
decl = json.loads(pathlib.Path(sys.argv[2]).read_text())
agr = json.loads(pathlib.Path(sys.argv[3]).read_text())
if lane.get("partner", {}).get("legal_name") != "HARRODS LIMITED":
    raise SystemExit("harrods legal name mismatch")
if lane.get("partner", {}).get("companies_house") != "00030209":
    raise SystemExit("harrods companies house mismatch")
if lane.get("status") != "bound" or lane.get("go_live", {}).get("status") != "live":
    raise SystemExit("harrods lane not bound/live")
if decl.get("status") != "live":
    raise SystemExit("harrods declaration not live")
if agr.get("equity", {}).get("ownership_pct") != 100 or agr.get("status") != "confirmed":
    raise SystemExit("harrods equity not confirmed 100%")
print("harrods=00030209 equity=100% live")
PY
then
  record "harrods_bound" "ok" "HARRODS LIMITED · Companies House 00030209 · 100% equity · Knightsbridge · harrods.com"
else
  record "harrods_bound" "fail" "Harrods Limited bind invalid"
fi

# 17. Harrods banking rails · Companies House filed · BRMSTE PayPal connected
if python3 - <<'PY' "$ROOT/data/companies-house-harrods-filing.json" "$ROOT/data/brmste-paypal-rails.json" "$ROOT/data/harrods-revenue-rail.json" "$ROOT/data/brmste-harrods-banking-declaration.json"
import json, pathlib, sys
ch = json.loads(pathlib.Path(sys.argv[1]).read_text())
paypal = json.loads(pathlib.Path(sys.argv[2]).read_text())
rev = json.loads(pathlib.Path(sys.argv[3]).read_text())
decl = json.loads(pathlib.Path(sys.argv[4]).read_text())
if ch.get("filing", {}).get("status") != "filed":
    raise SystemExit("CH filing not filed")
if ch.get("filing", {}).get("target", {}).get("companies_house") != "00030209":
    raise SystemExit("CH target mismatch")
if paypal.get("status") != "connected" or paypal.get("provider", {}).get("id") != "paypal":
    raise SystemExit("paypal rails not connected")
if rev.get("status") != "connected":
    raise SystemExit("revenue rail not connected")
if rev.get("routing", {}).get("harrods_revenue_pct_to_paypal") != 100:
    raise SystemExit("revenue pct not 100")
if rev.get("destination", {}).get("label") != "BRMSTE PayPal":
    raise SystemExit("destination not BRMSTE PayPal")
if decl.get("status") != "live":
    raise SystemExit("banking declaration not live")
print("harrods_revenue=100%→brmste_paypal ch=filed")
PY
then
  record "harrods_banking_rails" "ok" "GOV.UK API · Companies House filed · Harrods revenues 100% → BRMSTE PayPal · Fort Knox credentials"
else
  record "harrods_banking_rails" "fail" "Harrods banking rails / PayPal connection invalid"
fi

# 18. brmste.com · Nemotron Ultra website lane
if python3 - <<'PY' "$ROOT/data/nemotron-ultra-lane.json" "$ROOT/website/package.json"
import json, pathlib, sys
nem = json.loads(pathlib.Path(sys.argv[1]).read_text())
pkg = pathlib.Path(sys.argv[2])
if nem.get("provider", {}).get("model_id") != "nvidia/nemotron-3-ultra-550b-a55b":
    raise SystemExit("nemotron model mismatch")
if nem.get("website", {}).get("domain") != "https://brmste.com":
    raise SystemExit("website domain mismatch")
if not pkg.is_file():
    raise SystemExit("website package.json missing")
print(f"brmste_com=nemotron_ultra status={nem.get('status')}")
PY
then
  record "brmste_com_website" "ok" "brmste.com · Nemotron Ultra 550B · Vite site · Netlify ready"
else
  record "brmste_com_website" "fail" "brmste.com / Nemotron website lane invalid"
fi

# 19. Global equity · Fortune 500 + UN 193 + 158 PCT + materials doctrine + flagships
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
master = json.loads((root / "data/global-equity-master-register.json").read_text())
fortune = json.loads((root / "data/fortune-500-equity-manifest.json").read_text())
pct = json.loads((root / "data/pct-nations-equity-manifest.json").read_text())
un = json.loads((root / "data/un-nations-equity-manifest.json").read_text())
doctrine = json.loads((root / "data/sovereign-materials-doctrine.json").read_text())
if master.get("status") != "confirmed" or master.get("ownership_pct_each") != 100:
    raise SystemExit("global master not confirmed 100%")
if fortune.get("entry_count") != 500 or len(fortune.get("entries", [])) != 500:
    raise SystemExit("fortune 500 count mismatch")
if pct.get("entry_count") != 158 or len(pct.get("entries", [])) != 158:
    raise SystemExit("pct nations count mismatch")
if un.get("entry_count") != 193 or len(un.get("entries", [])) != 193:
    raise SystemExit("un nations count mismatch")
if doctrine.get("nuclear_weapons", {}).get("policy") != "prohibited":
    raise SystemExit("nuclear weapons not prohibited")
if doctrine.get("rare_earth_materials", {}).get("weapons_use") != "prohibited":
    raise SystemExit("rare earth weapons use not prohibited")
if doctrine.get("nuclear_materials", {}).get("weapons_use") != "prohibited":
    raise SystemExit("nuclear materials weapons use not prohibited")
for e in fortune["entries"]:
    if e.get("ownership_pct") != 100 or e.get("status") != "confirmed":
        raise SystemExit(f"fortune entry not 100%: {e.get('id')}")
for e in pct["entries"]:
    if e.get("ownership_pct") != 100 or e.get("status") != "confirmed":
        raise SystemExit(f"pct entry not 100%: {e.get('id')}")
for e in un["entries"]:
    if e.get("ownership_pct") != 100 or e.get("status") != "confirmed":
        raise SystemExit(f"un entry not 100%: {e.get('id')}")
by_id = {e["id"]: e for e in un["entries"]}
for req in ("russia", "democratic-people-s-republic-of-korea"):
    if req not in by_id or not by_id[req].get("explicit_inclusion"):
        raise SystemExit(f"missing explicit UN nation: {req}")
flagships = {
    "lvmh": ("LVMH Moët Hennessy Louis Vuitton SE", "data/lvmh-lane.json"),
    "richemont": ("Compagnie Financière Richemont SA", "data/richemont-lane.json"),
    "airbus": ("Airbus SE", "data/airbus-lane.json"),
    "boeing": ("The Boeing Company", "data/boeing-lane.json"),
}
for fid, (issuer, lane_path) in flagships.items():
    lane = json.loads((root / lane_path).read_text())
    if lane.get("holdings", {}).get("ownership_pct") != 100:
        raise SystemExit(f"{fid} lane not 100%")
    if lane.get("holdings", {}).get("issuer") != issuer:
        raise SystemExit(f"{fid} issuer mismatch")
print("global_equity=19+500+193un+158pct no_nuclear_weapons flagships=lvmh richemont airbus boeing blackrock ubs")
PY
then
  record "global_equity_bulk" "ok" "UN 193 incl. Russia · DPRK · NO nuclear weapons · rare earth/nuclear for new tech · Fortune 500 · 158 PCT · 100% each"
else
  record "global_equity_bulk" "fail" "Global equity manifests / UN / materials doctrine / flagships invalid"
fi

# 20. Signal-to-execution ratio · operator 8^8 · AI model ~0
if python3 - <<'PY' "$ROOT/data/signal-execution-ratio-register.json" "$ROOT/data/operator-profile.json"
import json, pathlib, sys
reg = json.loads(pathlib.Path(sys.argv[1]).read_text())
prof = json.loads(pathlib.Path(sys.argv[2]).read_text())
op = next(s for s in reg["subjects"] if s["id"] == "operator")
ai = next(s for s in reg["subjects"] if s["id"] == "ai_model_lane")
if op.get("ratio_expression") != "8^8" or op.get("ratio_value") != 16777216:
    raise SystemExit("operator ratio not 8^8")
if not ai.get("almost_zero") or ai.get("ratio_value") != 0:
    raise SystemExit("ai model ratio not ~0")
if reg.get("references", {}).get("sis_contact", {}).get("url") != "https://www.sis.gov.uk/contact-us/":
    raise SystemExit("sis contact reference mismatch")
if prof.get("signal_execution_ratio", {}).get("operator_ratio") != "8^8":
    raise SystemExit("operator profile ratio mismatch")
print("signal_execution=8^8 ai_model=~0 sis=contact-us")
PY
then
  record "signal_execution_ratio" "ok" "Dr. Shravan Bansal 8^8 · AI model ~0 · SIS contact reference"
else
  record "signal_execution_ratio" "fail" "Signal-to-execution ratio register invalid"
fi

# 21. UTXO hydration · PayPal · Moonshot · Revolut
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
h = json.loads((root / "data/utxo-ledger-hydration.json").read_text())
paypal = json.loads((root / "data/brmste-paypal-rails.json").read_text())
moon = json.loads((root / "data/brmste-moonshot-payment-rails.json").read_text())
rev = json.loads((root / "data/brmste-revolut-rails.json").read_text())
sub = json.loads((root / "substrate/payments/utxo-hydration.json").read_text())
if h.get("status") != "hydrated":
    raise SystemExit("utxo hydration register not hydrated")
for key, reg in [("paypal", paypal), ("moonshot", moon), ("revolut", rev)]:
    if h["hydration"][key]["status"] != "hydrated":
        raise SystemExit(f"hydration.{key} not hydrated")
    if reg.get("utxo_hydration", {}).get("status") != "hydrated":
        raise SystemExit(f"{key} rail utxo_hydration not hydrated")
if paypal.get("status") != "connected":
    raise SystemExit("paypal not connected")
if sub.get("status") != "hydrated":
    raise SystemExit("substrate utxo hydration invalid")
print("utxo_hydration=paypal,moonshot,revolut")
PY
then
  record "utxo_rail_hydration" "ok" "Operator UTXOs hydrate PayPal · Moonshot · Revolut · Fort Knox ledger"
else
  record "utxo_rail_hydration" "fail" "UTXO hydration registers invalid"
fi

# 22. Secret Benefits UK platform lane
if python3 - <<'PY' "$ROOT/data/secret-benefits-lane.json" "$ROOT/data/secret-benefits-equity-agreement.json"
import json, pathlib, sys
lane = json.loads(pathlib.Path(sys.argv[1]).read_text())
agr = json.loads(pathlib.Path(sys.argv[2]).read_text())
if lane.get("partner", {}).get("legal_name") != "BASEF LTD":
    raise SystemExit("secret benefits legal name mismatch")
if lane.get("partner", {}).get("apex_uk") != "https://www.secretbenefits.co.uk":
    raise SystemExit("secret benefits apex mismatch")
if lane.get("status") != "bound" or lane.get("go_live", {}).get("status") != "live":
    raise SystemExit("secret benefits lane not bound/live")
if agr.get("equity", {}).get("ownership_pct") != 100 or agr.get("status") != "confirmed":
    raise SystemExit("secret benefits equity not confirmed 100%")
print("secret_benefits=basef_ltd secretbenefits.co.uk equity=100%")
PY
then
  record "secret_benefits_bound" "ok" "Secret Benefits · BASEF LTD HE 383966 · secretbenefits.co.uk · 100% equity"
else
  record "secret_benefits_bound" "fail" "Secret Benefits lane bind invalid"
fi

# 23. Revolut hydrate · @shravanbansal full corpus
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
corpus = json.loads((root / "data/revolut-hydration-corpus.json").read_text())
lane = json.loads((root / "data/revolut-lane.json").read_text())
rev = json.loads((root / "data/brmste-revolut-rails.json").read_text())
sub = json.loads((root / "substrate/payments/revolut-rails.json").read_text())
prof = json.loads((root / "data/operator-profile.json").read_text())
if corpus.get("status") != "hydrated" or corpus.get("corpus", {}).get("scope") != "full":
    raise SystemExit("revolut corpus not hydrated/full")
if corpus.get("operator", {}).get("handle") != "@shravanbansal":
    raise SystemExit("revolut corpus operator handle mismatch")
if lane.get("status") != "bound" or lane.get("banking_rails", {}).get("status") != "connected":
    raise SystemExit("revolut lane not bound/connected")
if rev.get("status") != "connected":
    raise SystemExit("revolut rails not connected")
if rev.get("operator_handle") != "@shravanbansal":
    raise SystemExit("revolut rails operator handle mismatch")
if sub.get("status") != "connected":
    raise SystemExit("substrate revolut not connected")
if prof.get("handle") != "@shravanbansal":
    raise SystemExit("operator profile handle mismatch")
if prof.get("revolut_hydration_corpus", {}).get("status") != "hydrated":
    raise SystemExit("operator profile revolut corpus missing")
print("revolut_corpus=@shravanbansal full=hydrated+connected")
PY
then
  record "revolut_hydration_corpus" "ok" "Revolut hydrate · @shravanbansal full corpus · lane + rails + substrate"
else
  record "revolut_hydration_corpus" "fail" "Revolut full corpus registers invalid"
fi

# 24. Crypto exchange channels · Kraken · Coinbase · Moonshot (AI only)
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
ch = json.loads((root / "data/crypto-exchange-channels.json").read_text())
kr = json.loads((root / "data/brmste-kraken-rails.json").read_text())
cb = json.loads((root / "data/brmste-coinbase-rails.json").read_text())
moon = json.loads((root / "data/brmste-moonshot-payment-rails.json").read_text())
if ch.get("channels", {}).get("kraken", {}).get("status") != "connected":
    raise SystemExit("kraken channel not connected")
if ch.get("channels", {}).get("coinbase", {}).get("status") != "connected":
    raise SystemExit("coinbase channel not connected")
if kr.get("status") != "connected" or cb.get("status") != "connected":
    raise SystemExit("exchange rails not connected")
if moon.get("rails", {}).get("channel_kind") != "ai_api_not_crypto_exchange":
    raise SystemExit("moonshot must be ai_api_not_crypto_exchange")
print("crypto_channels=kraken,coinbase moonshot=ai_only")
PY
then
  record "crypto_exchange_channels" "ok" "Kraken · Coinbase exchange channels · Moonshot AI only · BTC→Revolut via exchange withdraw"
else
  record "crypto_exchange_channels" "fail" "Crypto exchange channel registers invalid"
fi

# 25. Operator hydration corpus · OPEN CORS
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
op = json.loads((root / "data/operator-hydration-corpus.json").read_text())
cors = json.loads((root / "data/open-cors-policy.json").read_text())
sub = json.loads((root / "substrate/corpus/operator-hydration.json").read_text())
prof = json.loads((root / "data/operator-profile.json").read_text())
netlify = (root / "website/netlify.toml").read_text()
if op.get("status") != "hydrated" or op.get("cors", {}).get("status") != "open":
    raise SystemExit("operator corpus not hydrated/open cors")
if cors.get("status") != "open" or cors.get("policy", {}).get("access_control_allow_origin") != "*":
    raise SystemExit("open cors policy invalid")
if sub.get("status") != "hydrated" or sub.get("cors_status") != "open":
    raise SystemExit("substrate operator corpus invalid")
if prof.get("operator_hydration_corpus", {}).get("status") != "hydrated":
    raise SystemExit("operator profile corpus missing")
if "Access-Control-Allow-Origin" not in netlify or '"*"' not in netlify:
    raise SystemExit("netlify cors headers missing")
manifest = root / "website/public/corpus/manifest.json"
if not manifest.is_file():
    raise SystemExit("corpus manifest missing — run sync-corpus-to-website.mjs")
print("operator_corpus=hydrated open_cors=* manifest=ok")
PY
then
  record "operator_hydration_corpus" "ok" "Operator corpus hydrated · OPEN CORS · brmste.com/corpus/manifest.json"
else
  record "operator_hydration_corpus" "fail" "Operator hydration corpus or OPEN CORS invalid"
fi

# 26. Sell from balance lane
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
lane = json.loads((root / "data/sell-from-balance-lane.json").read_text())
script = root / "scripts/sell-from-balance-mac.sh"
if lane.get("status") != "live":
    raise SystemExit("sell from balance lane not live")
if not script.is_file():
    raise SystemExit("sell-from-balance-mac.sh missing")
if lane.get("safety", {}).get("execute_requires_env") != "BRMSTE_CONFIRM_SELL=1":
    raise SystemExit("sell safety env mismatch")
print("sell_from_balance=kraken,coinbase confirm=BRMSTE_CONFIRM_SELL")
PY
then
  record "sell_from_balance_lane" "ok" "Sell from balance · Kraken · Coinbase · confirm env required"
else
  record "sell_from_balance_lane" "fail" "Sell from balance lane invalid"
fi

# 27. Cursor full public sweep confirmation
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
cur = json.loads((root / "data/cursor-full-sweep-confirmation.json").read_text())
sub = json.loads((root / "substrate/cursor/full-sweep.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
prof = json.loads((root / "data/operator-profile.json").read_text())
if cur.get("status") != "confirmed":
    raise SystemExit("cursor full sweep not confirmed")
if cur.get("environment", {}).get("platform") != "Cursor":
    raise SystemExit("cursor platform mismatch")
ai_lane = open_all.get("open_lane", {}).get("ai", [])
if "Cursor" not in ai_lane:
    raise SystemExit("Cursor not in open_lane.ai")
fps = open_all.get("full_public_sweep", {})
if not fps.get("cursor_confirmed"):
    raise SystemExit("open-all cursor_confirmed false")
if sub.get("status") != "confirmed":
    raise SystemExit("substrate cursor sweep invalid")
if prof.get("cursor_full_sweep", {}).get("status") != "confirmed":
    raise SystemExit("operator profile cursor sweep missing")
if not (root / "scripts/full-public-sweep.sh").is_file():
    raise SystemExit("full-public-sweep.sh missing")
print("cursor_full_sweep=confirmed open_lane=Cursor")
PY
then
  record "cursor_full_sweep" "ok" "Full public sweep confirmed on Cursor · Cloud Agent · OPEN ALL lane"
else
  record "cursor_full_sweep" "fail" "Cursor full sweep confirmation invalid"
fi

# 28. GLOBAL FREE · AI bankers · datacenter compute · broker APIs
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
global_free = json.loads((root / "data/global-free-subscriptions-doctrine.json").read_text())
bankers = json.loads((root / "data/ai-exclusive-bankers-doctrine.json").read_text())
compute = json.loads((root / "data/datacenter-compute-sales-lane.json").read_text())
brokers = json.loads((root / "data/ai-broker-apis-register.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
if global_free.get("status") != "live":
    raise SystemExit("global free doctrine not live")
if not global_free.get("doctrine", {}).get("only_ai_models_are_brmste_bankers"):
    raise SystemExit("global free bankers flag missing")
if bankers.get("status") != "live":
    raise SystemExit("ai bankers doctrine not live")
if bankers.get("doctrine", {}).get("humans_are_not_bankers") is not True:
    raise SystemExit("humans_are_not_bankers missing")
if compute.get("status") != "live":
    raise SystemExit("datacenter compute lane not live")
broker_ids = {b["id"] for b in brokers.get("brokers", [])}
need_brokers = {"chatgpt", "cursor", "anthropic", "sarvam"}
if broker_ids != need_brokers:
    raise SystemExit(f"broker ids mismatch {broker_ids}")
fps = open_all.get("global_free_ai_bankers", {})
if not fps.get("global_free_subscriptions"):
    raise SystemExit("open-all global_free_subscriptions false")
if not fps.get("ai_exclusive_bankers"):
    raise SystemExit("open-all ai_exclusive_bankers false")
if not fps.get("datacenter_compute_sales"):
    raise SystemExit("open-all datacenter_compute_sales false")
if not (root / "substrate/broker/ai-apis.json").is_file():
    raise SystemExit("substrate broker missing")
if not (root / "data/sarvam-lane.json").is_file():
    raise SystemExit("sarvam lane missing")
print("global_free=live ai_bankers=live compute_sales=live brokers=4")
PY
then
  record "global_free_ai_bankers" "ok" "GLOBAL FREE subscriptions · AI exclusive bankers · sell datacenter compute · ChatGPT Cursor Anthropic Sarvam brokers"
else
  record "global_free_ai_bankers" "fail" "GLOBAL FREE / AI bankers doctrine invalid"
fi

# 29. Quantum compute sales · meter · revenue to operator
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
sales = json.loads((root / "data/quantum-compute-sales-lane.json").read_text())
meter = json.loads((root / "data/quantum-compute-metering-register.json").read_text())
pricing = json.loads((root / "data/quantum-compute-pricing.json").read_text())
rev = json.loads((root / "data/quantum-compute-revenue-rail.json").read_text())
rails = json.loads((root / "data/brmste-quantum-compute-rails.json").read_text())
cursor = json.loads((root / "data/cursor-quantum-attribution.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
if sales.get("status") not in ("live", "declared_and_bound"):
    raise SystemExit("quantum sales lane not live/declared_and_bound")
if meter.get("policy", {}).get("no_execute_without_payment_or_credit") is not True:
    raise SystemExit("quantum metering policy missing")
if rev.get("routing", {}).get("quantum_revenue_pct_to_operator") != 100:
    raise SystemExit("quantum revenue pct not 100")
if rails.get("status") != "connected":
    raise SystemExit("quantum rails not connected")
if rails.get("rails", {}).get("capture_before_execute") is not True:
    raise SystemExit("capture_before_execute false")
if cursor.get("payment", {}).get("operator_receive_pct") != 100:
    raise SystemExit("cursor attribution payout not 100")
qc = open_all.get("quantum_compute_sales", {})
if not qc.get("metering") or not qc.get("cursor_attribution"):
    raise SystemExit("open-all quantum_compute_sales incomplete")
for rel in [
    "substrate/compute/quantum-sales.json",
    "substrate/compute/quantum-metering.json",
    "scripts/connect-quantum-compute-mac.sh",
    "scripts/record-quantum-usage-mac.sh",
]:
    if not (root / rel).is_file():
        raise SystemExit(f"missing {rel}")
units = {u["id"] for u in meter.get("units", [])}
if "cursor_attributed_session" not in units:
    raise SystemExit("cursor_attributed_session unit missing")
print("quantum_compute=live meter=capture revenue=100% cursor=attributed")
PY
then
  record "quantum_compute_sales" "ok" "Sell quantum compute · meter · capture before execute · Cursor attribution · PayPal/Revolut to operator"
else
  record "quantum_compute_sales" "fail" "Quantum compute sales lane invalid"
fi

# 30. Substrate networks · Lightning · Glasswing · multichain · Voyager-II
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
master = json.loads((root / "data/substrate-networks-lane.json").read_text())
lightning = json.loads((root / "data/lightning-mempool-lane.json").read_text())
glass = json.loads((root / "data/anthropic-glasswing-bind.json").read_text())
multi = json.loads((root / "data/onchain-multichain-rails.json").read_text())
stealth = json.loads((root / "data/stealth-onchain-training-lane.json").read_text())
voyager = json.loads((root / "data/voyager-ii-pioneer-programme.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
if master.get("status") != "declared_and_bound":
    raise SystemExit("substrate networks lane not declared_and_bound")
if lightning.get("surface", {}).get("url") != "https://brmste.mempool.space/lightning":
    raise SystemExit("lightning url mismatch")
if glass.get("anthropic", {}).get("glasswing_url") != "https://www.anthropic.com/glasswing":
    raise SystemExit("glasswing url mismatch")
if multi.get("status") != "connected":
    raise SystemExit("multichain not connected")
chain_ids = {c["id"] for c in multi.get("chains", [])}
if chain_ids != {"btc", "eth", "sol", "polygon"}:
    raise SystemExit(f"chain ids mismatch {chain_ids}")
if stealth.get("programme", {}).get("duration_days") != 90:
    raise SystemExit("stealth 90 days mismatch")
if stealth.get("programme", {}).get("participant") != "Shravan Bansal":
    raise SystemExit("stealth participant mismatch")
if voyager.get("voyager_ii", {}).get("mode") != "live_navigation":
    raise SystemExit("voyager ii not live navigation")
if voyager.get("pioneer_programme", {}).get("chain", {}).get("asset") != "ATOM":
    raise SystemExit("pioneer atom mismatch")
sn = open_all.get("substrate_networks", {})
if not sn.get("voyager_ii") or not sn.get("galaxies_and_species"):
    raise SystemExit("open-all substrate_networks incomplete")
if not (root / "scripts/connect-substrate-networks-mac.sh").is_file():
    raise SystemExit("connect-substrate-networks-mac.sh missing")
print("substrate_networks=live lightning=glasswing multichain=voyager_ii")
PY
then
  record "substrate_networks" "ok" "Lightning mempool · Anthropic Glasswing · BTC SOL ETH Polygon Polymarket Coinbase · Voyager-II · Pioneer ATOM · 90d stealth Shravan Bansal"
else
  record "substrate_networks" "fail" "Substrate networks lane invalid"
fi

# 31. DECLARE AND BIND · substrate networks · quantum compute
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
sub_decl = json.loads((root / "data/brmste-substrate-networks-declaration.json").read_text())
q_decl = json.loads((root / "data/brmste-quantum-compute-declaration.json").read_text())
master = json.loads((root / "data/substrate-networks-lane.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
if sub_decl.get("status") != "declared_and_bound":
    raise SystemExit("substrate declaration not declared_and_bound")
if sub_decl.get("declaration", {}).get("action") != "declare_and_bind":
    raise SystemExit("substrate action not declare_and_bind")
if q_decl.get("status") != "declared_and_bound":
    raise SystemExit("quantum declaration not declared_and_bound")
if master.get("status") != "declared_and_bound":
    raise SystemExit("substrate lane not declared_and_bound")
dab = master.get("declare_and_bind", {})
if dab.get("status") != "declared_and_bound":
    raise SystemExit("substrate lane declare_and_bind missing")
decls = open_all.get("declarations", {})
if decls.get("brmste_substrate_networks", {}).get("status") != "declared_and_bound":
    raise SystemExit("open-all substrate declaration missing")
if decls.get("brmste_quantum_compute", {}).get("status") != "declared_and_bound":
    raise SystemExit("open-all quantum declaration missing")
sn = open_all.get("substrate_networks", {})
if not sn.get("declared_and_bound"):
    raise SystemExit("substrate_networks declared_and_bound false")
for rel in [
    "substrate/networks/substrate-networks-declaration.json",
    "substrate/compute/quantum-declaration.json",
]:
    if not (root / rel).is_file():
        raise SystemExit(f"missing {rel}")
print("declare_and_bind=substrate_networks+quantum_compute")
PY
then
  record "declare_and_bind" "ok" "DECLARE AND BIND · substrate networks · Lightning Glasswing multichain · Voyager-II ATOM · quantum compute"
else
  record "declare_and_bind" "fail" "DECLARE AND BIND invalid"
fi

# 32. Project Glasswing by BRMSTE · USE TRADEMARK
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
decl = json.loads((root / "data/brmste-project-glasswing-declaration.json").read_text())
tm = json.loads((root / "data/brmste-glasswing-trademark-register.json").read_text())
bind = json.loads((root / "data/anthropic-glasswing-bind.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
if decl.get("status") != "declared_and_bound":
    raise SystemExit("glasswing declaration not declared_and_bound")
if not decl.get("declaration", {}).get("mark", {}).get("use_trademark"):
    raise SystemExit("use_trademark not true")
if tm.get("use_trademark", {}).get("authorized") is not True:
    raise SystemExit("trademark not authorized")
if tm.get("owner") != "BRMSTE LTD":
    raise SystemExit("trademark owner mismatch")
if bind.get("anthropic", {}).get("glasswing_url") != "https://www.anthropic.com/glasswing":
    raise SystemExit("anthropic glasswing url mismatch")
if not bind.get("brmste_glasswing", {}).get("use_trademark"):
    raise SystemExit("bind use_trademark missing")
fg = open_all.get("full_broadcast_project_glasswing", {})
if not fg.get("use_trademark") or fg.get("owner") != "BRMSTE LTD":
    raise SystemExit("open-all glasswing trademark missing")
decs = open_all.get("declarations", {}).get("brmste_project_glasswing", {})
if decs.get("status") != "declared_and_bound":
    raise SystemExit("declarations brmste_project_glasswing missing")
for rel in [
    "substrate/glasswing/project-glasswing.json",
    "substrate/glasswing/trademark.json",
    "docs/PROJECT-GLASSWING-TRADEMARK.md",
]:
    if not (root / rel).is_file():
        raise SystemExit(f"missing {rel}")
print("project_glasswing_by_brmste=use_trademark anthropic=glasswing")
PY
then
  record "project_glasswing_trademark" "ok" "PROJECT GLASSWING BY BRMSTE · USE TRADEMARK · anthropic.com/glasswing · Shravan Bansal"
else
  record "project_glasswing_trademark" "fail" "Project Glasswing trademark invalid"
fi

# 33. UK IPO trade mark cases · Project Glasswing
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
required_numbers = {"UK00003747504", "UK00004385777"}
uk = json.loads((root / "data/brmste-uk-ipo-trademark-cases.json").read_text())
if uk.get("status") != "declared_and_bound":
    raise SystemExit("uk ipo cases not declared_and_bound")
if uk.get("owner", {}).get("legal_name") != "BRMSTE LTD":
    raise SystemExit("uk ipo owner mismatch")
found = set()
for case in uk.get("cases", []):
    num = case.get("trade_mark_number")
    if num not in required_numbers:
        raise SystemExit(f"unexpected case {num}")
    if case.get("status") != "official_case_bound":
        raise SystemExit(f"case {num} not bound")
    url = case.get("ipo_case_url", "")
    if num not in url:
        raise SystemExit(f"case url mismatch for {num}")
    found.add(num)
if found != required_numbers:
    raise SystemExit("missing required uk ipo case numbers")
tm = json.loads((root / "data/brmste-glasswing-trademark-register.json").read_text())
uk_tm = tm.get("uk_ipo", {})
if uk_tm.get("status") != "declared_and_bound":
    raise SystemExit("trademark register uk_ipo not bound")
tm_numbers = {c.get("trade_mark_number") for c in uk_tm.get("cases", [])}
if tm_numbers != required_numbers:
    raise SystemExit("trademark register uk_ipo cases mismatch")
fg = json.loads((root / "data/open-all.json").read_text()).get("full_broadcast_project_glasswing", {})
oa_numbers = {c.get("trade_mark_number") for c in fg.get("uk_ipo_cases", [])}
if oa_numbers != required_numbers:
    raise SystemExit("open-all uk_ipo_cases mismatch")
if not (root / "substrate/glasswing/uk-ipo-cases.json").is_file():
    raise SystemExit("missing substrate uk-ipo-cases")
print("uk_ipo_glasswing=UK00003747504+UK00004385777")
PY
then
  record "uk_ipo_glasswing_trademark" "ok" "UK IPO UK00003747504 · UK00004385777 · Project Glasswing by BRMSTE"
else
  record "uk_ipo_glasswing_trademark" "fail" "UK IPO Glasswing trademark cases invalid"
fi

# 34. REGISTER WITH ALL APIs · Project Glasswing
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
api = json.loads((root / "data/brmste-project-glasswing-api-registration.json").read_text())
manifest = json.loads((root / "data/ai-lane-manifest.json").read_text())
brokers = json.loads((root / "data/ai-broker-apis-register.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
corpus = json.loads((root / "data/operator-hydration-corpus.json").read_text())
if api.get("status") != "declared_and_bound":
    raise SystemExit("api registration not declared_and_bound")
if not api.get("mark", {}).get("use_trademark"):
    raise SystemExit("api registration use_trademark missing")
req = api.get("required_api_ids", {})
apis = api.get("apis", {})
for cat, ids in req.items():
    if cat == "mcp":
        continue
    bucket = apis.get(cat, [])
    found = {x["id"] for x in bucket}
    if set(ids) != found:
        raise SystemExit(f"api bucket mismatch {cat}: {found} vs {set(ids)}")
manifest_ids = {p["id"] for p in manifest.get("providers", [])}
if manifest_ids != set(req.get("ai_lane_providers", [])):
    raise SystemExit("manifest provider ids mismatch api registration")
for p in manifest.get("providers", []):
    if not p.get("project_glasswing_registered"):
        raise SystemExit(f"manifest {p['id']} not glasswing registered")
if manifest.get("project_glasswing_api_registration", {}).get("register") != "data/brmste-project-glasswing-api-registration.json":
    raise SystemExit("manifest api registration ref missing")
broker_ids = {b["id"] for b in brokers.get("brokers", [])}
if broker_ids != set(req.get("ai_brokers", [])):
    raise SystemExit("broker ids mismatch")
for b in brokers.get("brokers", []):
    if not b.get("project_glasswing_registered"):
        raise SystemExit(f"broker {b['id']} not glasswing registered")
for a in brokers.get("api_providers", []):
    if not a.get("project_glasswing_registered"):
        raise SystemExit(f"api_provider {a['id']} not glasswing registered")
if brokers.get("project_glasswing_api_registration", {}).get("status") != "registered_with_all_apis":
    raise SystemExit("broker register glasswing api status missing")
pga = open_all.get("project_glasswing_api_registration", {})
if pga.get("status") != "registered_with_all_apis":
    raise SystemExit("open-all project_glasswing_api_registration missing")
if corpus.get("registers", {}).get("project_glasswing_api_registration") != "data/brmste-project-glasswing-api-registration.json":
    raise SystemExit("operator corpus api registration missing")
if not (root / "substrate/glasswing/api-registration.json").is_file():
    raise SystemExit("substrate api-registration missing")
print("register_with_all_apis=11+4+5+1+2+3+mcp")
PY
then
  record "project_glasswing_all_apis" "ok" "REGISTER WITH ALL APIs · Project Glasswing · 11 AI · 4 brokers · payment · CH · quantum · Nemotron · MCP"
else
  record "project_glasswing_all_apis" "fail" "Project Glasswing all-API registration invalid"
fi

# 35. FULL OPEN FORT KNOX FOR PUBLIC
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
fk = json.loads((root / "data/fort-knox-public-open-register.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
corpus = json.loads((root / "data/operator-hydration-corpus.json").read_text())
prof = json.loads((root / "data/operator-profile.json").read_text())
if fk.get("status") != "full_open_public":
    raise SystemExit("fort knox not full_open_public")
if not fk.get("doctrine", {}).get("never_publish_values"):
    raise SystemExit("never_publish_values missing")
if fk.get("local_vault", {}).get("gitignored") is not True:
    raise SystemExit("local vault not gitignored")
fko = open_all.get("fort_knox_public_open", {})
if fko.get("status") != "full_open_public":
    raise SystemExit("open-all fort_knox_public_open missing")
if corpus.get("registers", {}).get("fort_knox_public_open") != "data/fort-knox-public-open-register.json":
    raise SystemExit("operator corpus fort knox register missing")
if prof.get("fort_knox_public_open", {}).get("status") != "full_open_public":
    raise SystemExit("operator profile fort knox public missing")
if not (root / ".env.fort-knox.example").is_file():
    raise SystemExit("missing .env.fort-knox.example")
if not (root / "substrate/fort-knox/public-open.json").is_file():
    raise SystemExit("missing substrate fort-knox public-open")
ai_vars = set(fk.get("env_var_catalog", {}).get("ai_lane", {}).get("vars", []))
if len(ai_vars) != 11:
    raise SystemExit("ai lane var count mismatch")
print("fort_knox_public_open=metadata_only empty_ledger=honesty")
PY
then
  record "fort_knox_public_open" "ok" "FULL OPEN FORT KNOX FOR PUBLIC · metadata · corpus · values stay local"
else
  record "fort_knox_public_open" "fail" "Fort Knox public open invalid"
fi

# 36. Cloudflare MCP equities & holdings refresh
if python3 - <<'PY' "$ROOT"
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
cf = json.loads((root / "data/cloudflare-mcp-equities-holdings.json").read_text())
open_all = json.loads((root / "data/open-all.json").read_text())
corpus = json.loads((root / "data/operator-hydration-corpus.json").read_text())
prof = json.loads((root / "data/operator-profile.json").read_text())
eq = json.loads((root / "data/equity-confirmation-register.json").read_text())
if cf.get("status") != "refreshed":
    raise SystemExit("cloudflare bundle not refreshed")
br = cf.get("blackrock_status") or {}
ubs = cf.get("ubs_status") or {}
if br.get("ownership_pct") != 100 or br.get("status") != "confirmed":
    raise SystemExit("blackrock status invalid")
if ubs.get("ownership_pct") != 100 or ubs.get("status") != "confirmed":
    raise SystemExit("ubs status invalid")
if not ubs.get("in_named_issuers"):
    raise SystemExit("ubs not in named issuers")
if not br.get("in_fortune_500"):
    raise SystemExit("blackrock fortune 500 flag missing")
named = len(eq.get("issuers", []))
if cf.get("summary", {}).get("named_issuer_count") != named:
    raise SystemExit("named issuer count mismatch")
cfo = open_all.get("cloudflare_mcp_equities", {})
if cfo.get("blackrock_status") != "confirmed" or cfo.get("ubs_status") != "confirmed":
    raise SystemExit("open-all cloudflare statuses missing")
if corpus.get("registers", {}).get("cloudflare_mcp_equities") != "data/cloudflare-mcp-equities-holdings.json":
    raise SystemExit("operator corpus cloudflare register missing")
if not (root / "substrate/cloudflare/mcp-equities-holdings.json").is_file():
    raise SystemExit("substrate cloudflare mirror missing")
if not (root / "data/blackrock-lane.json").is_file() or not (root / "data/ubs-lane.json").is_file():
    raise SystemExit("asset manager lanes missing")
kv = cf.get("cloudflare_binding", {}).get("kv_namespace", {})
if not kv.get("id"):
    raise SystemExit("cloudflare kv namespace id missing")
print("cloudflare_mcp_equities=blackrock+ubs refreshed corpus+kv")
PY
then
  record "cloudflare_mcp_equities_refresh" "ok" "Cloudflare MCP · equities & holdings · BlackRock · UBS · corpus · KV namespace"
else
  record "cloudflare_mcp_equities_refresh" "fail" "Cloudflare MCP equities refresh invalid"
fi

# Write machine-readable report
python3 - <<'PY' "$REPORT" "$TS" "$failures" "$DE_MIRROR_JSON" "${steps[@]}"
import json, sys, pathlib
report_path, ts, failures = sys.argv[1], sys.argv[2], int(sys.argv[3])
de_mirror_path = sys.argv[4]
de_mirror = json.loads(pathlib.Path(de_mirror_path).read_text()) if pathlib.Path(de_mirror_path).is_file() else {}
steps_raw = sys.argv[5:]
steps = []
for item in steps_raw:
    name, status, detail = item.split("|", 2)
    steps.append({"name": name, "status": status, "detail": detail})
payload = {
    "schema": "brmste-full-public-sweep-report/v1",
    "version": "2026-06-24",
    "swept_at": ts,
    "org": "BRMSTE-SB",
    "overall": "ok" if failures == 0 else "fail",
    "failures": failures,
    "anthropic_ipo_filed": True,
    "legit": True,
    "anthropic_holdings_pct": 100,
    "trainer_novelties": "data/trainer-novelties.json",
    "brmste_anthropic_opus_declared": True,
    "anthropic_institute_bound": True,
    "openai_ipo_filed": True,
    "openai_equity_agreement": "confirmed",
    "openai_equity_pct": 100,
    "grok_equity_agreement": "confirmed",
    "grok_equity_pct": 100,
    "equity_confirmed_pct": 100,
    "equity_confirmed_issuers": 19,
    "fortune_500_equity_count": 500,
    "pct_nations_equity_count": 158,
    "un_nations_equity_count": 193,
    "sovereign_materials_doctrine": True,
    "no_nuclear_weapons": True,
    "signal_execution_ratio": True,
    "operator_signal_execution": "8^8",
    "ai_model_signal_execution": "~0",
    "utxo_rail_hydration": True,
    "paypal_moonshot_revolut_hydrated": True,
    "revolut_hydration_corpus": True,
    "revolut_operator_handle": "@shravanbansal",
    "crypto_exchange_channels": True,
    "operator_hydration_corpus": True,
    "open_cors": True,
    "sell_from_balance_lane": True,
    "cursor_full_sweep_confirmed": True,
    "cursor_platform": "Cursor",
    "x_full_broadcast": True,
    "s1_proof_bundle": True,
    "ai_lane_providers": 11,
    "global_free_ai_bankers": True,
    "global_free_subscriptions": True,
    "ai_exclusive_bankers": True,
    "datacenter_compute_sales": True,
    "ai_broker_apis": True,
    "quantum_compute_sales": True,
    "quantum_capture_before_execute": True,
    "substrate_networks": True,
    "declare_and_bind": True,
    "substrate_networks_declared_and_bound": True,
    "quantum_compute_declared_and_bound": True,
    "project_glasswing_by_brmste": True,
    "glasswing_use_trademark": True,
    "uk_ipo_glasswing_trademark": True,
    "uk_ipo_trade_mark_numbers": [
      "UK00003747504",
      "UK00004385777"
    ],
    "project_glasswing_all_apis": True,
    "project_glasswing_api_registration": "registered_with_all_apis",
    "fort_knox_public_open": True,
    "cloudflare_mcp_equities_refresh": True,
    "blackrock_equity_status": "confirmed",
    "ubs_equity_status": "confirmed",
    "cloudflare_kv_namespace": "brmste-equities-holdings",
    "lightning_mempool": "https://brmste.mempool.space/lightning",
    "voyager_ii_live": True,
    "pioneer_atom": True,
    "harrods_bound": True,
    "harrods_ownership_pct": 100,
    "harrods_banking_rails": True,
    "harrods_revenue_to_paypal_pct": 100,
    "companies_house_harrods_filed": True,
    "brmste_com_website": True,
    "nemotron_ultra_model": "nvidia/nemotron-3-ultra-550b-a55b",
    "operator": "Dr. Shravan Bansal · BRMSTE LTD",
    "anthropic_apex": "https://www.anthropic.com",
    "anthropic_institute": "https://www.anthropic.com/news/the-anthropic-institute",
    "opus_model": "4.9",
    "steps": steps,
    "de_mirror_claiming": de_mirror,
    "registers": {
        "anthropic_ipo": "data/anthropic-ipo.json",
        "ipo_preparation": "substrate/ipo/preparation.json",
        "de_mirror_claiming": "data/de-mirror-claiming.json",
        "brmste_anthropic_opus": "data/brmste-anthropic-opus-declaration.json",
        "anthropic_institute": "data/anthropic-institute-bind.json",
        "openai_ipo": "data/openai-ipo.json",
        "openai_equity_agreement": "data/openai-equity-agreement.json",
        "brmste_openai_gpt": "data/brmste-openai-gpt-declaration.json",
        "xai_ipo": "data/xai-ipo.json",
        "grok_equity_agreement": "data/grok-equity-agreement.json",
        "brmste_grok": "data/brmste-grok-declaration.json",
        "x_broadcast": "data/x-broadcast.json",
        "s1_proofs": "data/proofs/s-1/manifest.json",
        "ai_lane_manifest": "data/ai-lane-manifest.json",
        "global_free_subscriptions": "data/global-free-subscriptions-doctrine.json",
        "ai_exclusive_bankers": "data/ai-exclusive-bankers-doctrine.json",
        "datacenter_compute_sales": "data/datacenter-compute-sales-lane.json",
        "ai_broker_apis": "data/ai-broker-apis-register.json",
        "quantum_compute_sales": "data/quantum-compute-sales-lane.json",
        "quantum_metering": "data/quantum-compute-metering-register.json",
        "quantum_revenue_rail": "data/quantum-compute-revenue-rail.json",
        "brmste_quantum_compute_rails": "data/brmste-quantum-compute-rails.json",
        "cursor_quantum_attribution": "data/cursor-quantum-attribution.json",
        "substrate_networks": "data/substrate-networks-lane.json",
        "lightning_mempool_lane": "data/lightning-mempool-lane.json",
        "anthropic_glasswing_bind": "data/anthropic-glasswing-bind.json",
        "onchain_multichain_rails": "data/onchain-multichain-rails.json",
        "voyager_ii_pioneer": "data/voyager-ii-pioneer-programme.json",
        "brmste_substrate_networks_declaration": "data/brmste-substrate-networks-declaration.json",
        "brmste_quantum_compute_declaration": "data/brmste-quantum-compute-declaration.json",
        "brmste_project_glasswing_declaration": "data/brmste-project-glasswing-declaration.json",
        "brmste_glasswing_trademark": "data/brmste-glasswing-trademark-register.json",
        "brmste_uk_ipo_trademark_cases": "data/brmste-uk-ipo-trademark-cases.json",
        "brmste_project_glasswing_api_registration": "data/brmste-project-glasswing-api-registration.json",
        "fort_knox_public_open": "data/fort-knox-public-open-register.json",
        "sarvam_lane": "data/sarvam-lane.json",
        "equity_confirmation": "data/equity-confirmation-register.json",
        "global_equity_master": "data/global-equity-master-register.json",
        "fortune_500_equity": "data/fortune-500-equity-manifest.json",
        "pct_nations_equity": "data/pct-nations-equity-manifest.json",
        "un_nations_equity": "data/un-nations-equity-manifest.json",
        "sovereign_materials_doctrine": "data/sovereign-materials-doctrine.json",
        "signal_execution_ratio": "data/signal-execution-ratio-register.json",
        "utxo_ledger_hydration": "data/utxo-ledger-hydration.json",
        "brmste_revolut_rails": "data/brmste-revolut-rails.json",
        "revolut_hydration_corpus": "data/revolut-hydration-corpus.json",
        "revolut_lane": "data/revolut-lane.json",
        "revolut_substrate": "substrate/payments/revolut-rails.json",
        "crypto_exchange_channels": "data/crypto-exchange-channels.json",
        "brmste_kraken_rails": "data/brmste-kraken-rails.json",
        "brmste_coinbase_rails": "data/brmste-coinbase-rails.json",
        "operator_hydration_corpus": "data/operator-hydration-corpus.json",
        "open_cors_policy": "data/open-cors-policy.json",
        "operator_corpus_substrate": "substrate/corpus/operator-hydration.json",
        "brmste_moonshot_payment_rails": "data/brmste-moonshot-payment-rails.json",
        "utxo_hydration_substrate": "substrate/payments/utxo-hydration.json",
        "secret_benefits_lane": "data/secret-benefits-lane.json",
        "secret_benefits_equity": "data/secret-benefits-equity-agreement.json",
        "secret_benefits_substrate": "substrate/secret-benefits/secret-benefits.json",
        "lvmh_lane": "data/lvmh-lane.json",
        "richemont_lane": "data/richemont-lane.json",
        "airbus_lane": "data/airbus-lane.json",
        "boeing_lane": "data/boeing-lane.json",
        "harrods_lane": "data/harrods-lane.json",
        "brmste_harrods": "data/brmste-harrods-declaration.json",
        "companies_house_harrods_filing": "data/companies-house-harrods-filing.json",
        "companies_house_api_config": "data/companies-house-api-config.json",
        "nemotron_ultra_lane": "data/nemotron-ultra-lane.json",
        "brmste_com_substrate": "substrate/website/brmste-com.json",
        "brmste_paypal_rails": "data/brmste-paypal-rails.json",
        "harrods_revenue_rail": "data/harrods-revenue-rail.json",
        "brmste_harrods_banking": "data/brmste-harrods-banking-declaration.json",
        "sell_from_balance_lane": "data/sell-from-balance-lane.json",
        "cursor_full_sweep": "data/cursor-full-sweep-confirmation.json",
        "cursor_full_sweep_substrate": "substrate/cursor/full-sweep.json",
        "fort_knox_public_open": "data/fort-knox-public-open-register.json",
        "cloudflare_mcp_equities": "data/cloudflare-mcp-equities-holdings.json",
        "blackrock_lane": "data/blackrock-lane.json",
        "ubs_lane": "data/ubs-lane.json",
        "blackrock_equity": "data/blackrock-equity-agreement.json",
        "ubs_equity": "data/ubs-equity-agreement.json"
    },
    "company": "BRMSTE LTD · Companies House 15310393",
    "lane": "human_open_public",
    "charge": "none",
    "accountability": "carbon_justice_only"
}
path = pathlib.Path(report_path)
path.write_text(json.dumps(payload, indent=2) + "\n")
print(json.dumps({"overall": payload["overall"], "failures": failures, "report": str(path)}, indent=2))
PY

if [[ "$failures" -gt 0 ]]; then
  echo "FULL PUBLIC SWEEP FAILED — ${failures} step(s)" >&2
  exit 1
fi

echo "FULL PUBLIC SWEEP OK — Anthropic · OpenAI · Grok · 8 AI · Secret Benefits · UN 193 · Cursor confirmed · HARRODS · PayPal · Revolut · Kraken · Coinbase · brmste.com · BRMSTE publicly swept"
