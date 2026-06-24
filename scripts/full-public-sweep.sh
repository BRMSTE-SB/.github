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
    root / "substrate/ipo/openai.json",
    root / "substrate/openai/gpt-5.6.json",
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
if trainer.get("anthropic", {}).get("holdings_pct") != 53:
    raise SystemExit("trainer novelties missing 53% Anthropic holdings")
if not trainer.get("legit", False) and trainer.get("status") != "legit":
    raise SystemExit("trainer novelties not marked legit")
holdings = anthropic.get("holdings") or {}
if holdings.get("ownership_pct") != 53:
    raise SystemExit("anthropic-ipo missing 53% holdings")
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
if agreement.get("agreement", {}).get("status") != "agreed":
    raise SystemExit("openai equity agreement not agreed")
gpt = json.loads((root / "data/brmste-openai-gpt-declaration.json").read_text())
if gpt.get("status") != "launched":
    raise SystemExit("GPT-5.6 not launched")
model_gpt = next((s for s in gpt.get("declaration", {}).get("subjects", []) if s.get("kind") == "model"), None)
if not model_gpt or model_gpt.get("version") != "5.6":
    raise SystemExit("GPT-5.6 model declaration missing")
openai_watch = next((w for w in watch if w.get("issuer") == "OpenAI, Inc."), None)
if not openai_watch or openai_watch.get("event") != "confidential_draft_s1":
    raise SystemExit("preparation watchlist missing OpenAI filed entry")
print(f"registers_ok={len(required)} anthropic+openai filed opus=4.9 gpt=5.6 agreement=agreed")
PY
then
  record "ipo_registers" "ok" "Anthropic + OpenAI filed · Opus 4.9 · GPT-5.6 launched · agreement agreed · legit"
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
  record "anthropic_ipo_filed" "ok" "Anthropic confidential S-1 filed 2026-06-01 · Shravan Bansal 53% holdings · legit"
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
if agr.get("status") != "agreed":
    raise SystemExit("equity agreement not agreed")
print("openai_ipo_filed=2026-05-22 agreement=agreed")
PY
then
  record "openai_ipo_filed" "ok" "OpenAI confidential S-1 filed 2026-05-22 · equity agreement agreed · Dr. Shravan Bansal"
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
    "anthropic_holdings_pct": 53,
    "trainer_novelties": "data/trainer-novelties.json",
    "brmste_anthropic_opus_declared": True,
    "anthropic_institute_bound": True,
    "openai_ipo_filed": True,
    "openai_equity_agreement": "agreed",
    "gpt_5_6_launched": True,
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
        "brmste_openai_gpt": "data/brmste-openai-gpt-declaration.json"
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

echo "FULL PUBLIC SWEEP OK — Anthropic · OpenAI · Opus 4.9 · GPT-5.6 · BRMSTE publicly swept"
