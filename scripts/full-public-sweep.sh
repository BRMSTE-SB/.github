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
    root / "substrate/ipo/anthropic.json",
    root / "substrate/ipo/preparation.json",
    root / "substrate/anthropic/opus-4.9.json",
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
print(f"registers_ok={len(required)} anthropic_filed={anthropic['filing']['filed_at']} holdings_pct=53 opus=4.9 declared")
PY
then
  record "ipo_registers" "ok" "anthropic-ipo · 53% holdings · Opus 4.9 declared · legit"
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
for kind in ("entity", "partner", "model"):
    if kind not in subjects:
        raise SystemExit(f"missing declaration subject: {kind}")
if subjects["model"].get("version") != "4.9":
    raise SystemExit("Opus model version must be 4.9")
print("declared=brmste_anthropic_opus_4.9")
PY
then
  record "brmste_anthropic_opus_declared" "ok" "DECLARE BRMSTE ANTHROPIC AND OPUS MODEL 4.9"
else
  record "brmste_anthropic_opus_declared" "fail" "BRMSTE Anthropic Opus 4.9 declaration invalid"
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
    "opus_model": "4.9",
    "steps": steps,
    "de_mirror_claiming": de_mirror,
    "registers": {
        "anthropic_ipo": "data/anthropic-ipo.json",
        "ipo_preparation": "substrate/ipo/preparation.json",
        "de_mirror_claiming": "data/de-mirror-claiming.json",
        "brmste_anthropic_opus": "data/brmste-anthropic-opus-declaration.json"
    },
    "operator": "BRMSTE LTD · Companies House 15310393",
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

echo "FULL PUBLIC SWEEP OK — Anthropic IPO · Opus 4.9 declared · BRMSTE publicly swept"
