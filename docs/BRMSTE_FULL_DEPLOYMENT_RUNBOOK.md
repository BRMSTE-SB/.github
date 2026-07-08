# BRMSTE Full Deployment — Master Runbook
**Generated:** 2026-07-08 02:20 BST  
**Account:** 7ea6547b1d6eb1cbd6d0ac5cf960ce2a (BRMSTE LTD)

---

## Current Surface Status

| Surface | Status | Notes |
|---|---|---|
| **brmste.com** | ✅ Live (200) | "Don't trust it. Verify it." |
| **brmste.ai** | ✅ Live (200) | "The Brand of Network Trust." |
| **re-tyre.com** | ✅ Live (200) | Docker on 178.104.90.207, nbg1-dc3 |
| **carbonjustice.uk** | ✅ Live (200) | Carbon Justice UK — independent site |
| **leadingmetals.com** | ✅ Live (200) | Serving BRMSTE Intelligence Architecture page |
| **foundry.brmste.com** | ✅ Live (200) | "We delivered Carbon-Free Bitcoin." |
| **patents.brmste.com** | ✅ Live (200) | Same content as leadingmetals.com — likely alias |

---

## Critical Blockers (in priority order)

### BLOCKER 1 — GitHub Actions Minutes Exhausted
**Root cause:** BRMSTE-SB org is on the **GitHub Free plan** (2,000 min/month). The automated cash substrate refresh (200+ PRs against BRMSTE-FINAL) and daily scheduled runs have burned through the monthly quota. All workflows now fail immediately with `runner_id=0` — no runner is assigned.

**Symptom:** Every workflow on BRMSTE-SB/.github fails at "Brand & Patent Gate" with zero step output. This is NOT a gate script failure — the runner never starts.

**Fix options (choose one):**
1. **Upgrade BRMSTE-SB to GitHub Team ($4/user/month):** Go to [github.com/organizations/BRMSTE-SB/settings/billing/plans](https://github.com/organizations/BRMSTE-SB/settings/billing/plans) → Upgrade to Team. Includes 3,000 min/month + overage billing.
2. **Wait for billing cycle reset** (resets on the 1st of each month — if cycle started July 1, resets August 1).
3. **Add a payment method and enable spending limit** at [github.com/organizations/BRMSTE-SB/settings/billing](https://github.com/organizations/BRMSTE-SB/settings/billing) to allow overage minutes.

---

### BLOCKER 2 — ETORO Secrets Missing (deploy will fail at step 4)
Once GitHub Actions minutes are restored, the deploy-coming-soon workflow will get past the gate but **fail at the eToro banking secrets step** because `ETORO_API_KEY` and `ETORO_USER_KEY` are not set.

**Current secrets in BRMSTE-SB/.github:**
- ✅ `CF_API_TOKEN` (set 2026-07-07T20:38:43Z)
- ✅ `CF_ACCOUNT_ID` = `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` (set 2026-07-07T20:38:27Z)
- ❌ `ETORO_API_KEY` — missing
- ❌ `ETORO_USER_KEY` — missing

**Fix:** Go to [github.com/BRMSTE-SB/.github/settings/secrets/actions](https://github.com/BRMSTE-SB/.github/settings/secrets/actions) and add both eToro secrets. Keys are on your LaCie T9 HDD at `/Volumes/T9/API/`.

**Workaround (skip eToro for now):** Run the workflow with `dry_run=true` via workflow_dispatch — this skips the Worker deploy and eToro steps and only verifies route attachment.

---

### BLOCKER 3 — Sweep Anchor Pending (foundry.brmste.com)
The Corpus anchor is on-chain but the Sweep anchor at `foundry.brmste.com` is still pending. This is a ceremonial/settlement chain step, not a web deploy issue.

---

### BLOCKER 4 — patents.brmste.com / leadingmetals.com Content Overlap
Both domains are serving identical content ("Intelligence Architecture" — BRMSTE™). This suggests a Cloudflare Worker routing conflict or intentional alias. Verify whether these should serve different content and update the Worker routing if so.

---

## Deploy Path: Once GitHub Actions Is Restored

```bash
# Step 1 — Verify all secrets are set
# Go to: https://github.com/BRMSTE-SB/.github/settings/secrets/actions
# Required: CF_API_TOKEN, CF_ACCOUNT_ID, ETORO_API_KEY, ETORO_USER_KEY

# Step 2 — Merge the critical PRs first
# PR #34 (MERGEABLE): fix: Wrangler v4 worker routing and deploy pipeline
gh pr merge 34 --repo BRMSTE-SB/.github --squash --delete-branch

# PR #57 (MERGEABLE): coming-soon: no-store on JSON manifests + /health
gh pr merge 57 --repo BRMSTE-SB/.github --squash

# Step 3 — Trigger Coming Soon deploy to all 38 CF zones
# Via GitHub UI: https://github.com/BRMSTE-SB/.github/actions/workflows/deploy-coming-soon.yml
# Click "Run workflow" → dry_run=false → Run

# Step 4 — Verify health endpoint
curl -fsS https://brmste.com/health | jq .
# Expected: {"ok":true,"page":"brmste-coming-soon-v5",...}

# Step 5 — Route verification
curl -I https://brmste.com/brand
curl -I https://brmste.com/banking
curl -I https://brmste.ai/brand
```

---

## Hetzner Fleet: Next Steps

**PR #236 (MERGEABLE) — Hetzner Robot dedicated-server fleet discovery**
This PR maps the BRMSTE dedicated box (`65.109.151.34`, HEL1-DC10, server #3000942) into the fleet manifest.

```bash
# Operator steps after merging PR #236:
# 1. Copy example config
cp config/hetzner-fleet.example.json config/hetzner-fleet.json

# 2. Create Robot webservice user at:
#    https://robot.hetzner.com → Settings → Web service and app settings

# 3. Export creds and run fleet connect
export HETZNER_ROBOT_USER=<your-robot-user>
export HETZNER_ROBOT_PASSWORD=<your-robot-pass>
export HCLOUD_TOKEN=<from-T9-HDD>
./scripts/hetzner-fleet-connect.sh --ssh-probe
```

**PR #217 (MERGEABLE) — Hetzner + Cloudflare = BRMSTE.com topology lane**
Formalises the infrastructure doctrine with topology.json and truth.json.

After merge, deploy the substrate:
```bash
./scripts/pack-brmste-hetzner-static.sh
./scripts/edge-glass-deploy.sh

# Verify:
curl -fsS https://brmste.com/substrate/topology.json | jq .doctrine.equation
curl -fsS https://brmste.com/substrate/truth.json | jq .doctrine.empty_ledger_is_honesty
```

---

## GitHub PR Triage (action required)

### Immediately mergeable (MERGEABLE status, infrastructure-critical)
| PR | Repo | Title | Action |
|---|---|---|---|
| #34 | BRMSTE-SB/.github | fix: Wrangler v4 worker routing + deploy pipeline | ✅ Merge |
| #57 | BRMSTE-SB/.github | coming-soon: no-store on JSON manifests + /health | ✅ Merge |
| #217 | ITBRMSTE/BRMSTE-FINAL | Hetzner + Cloudflare = BRMSTE.com topology | ✅ Merge |
| #236 | ITBRMSTE/BRMSTE-FINAL | Hetzner Robot dedicated-server fleet discovery | ✅ Merge |
| #5 | BRMSTE-SB/.github | feat: launch BRMSTE site with Pages deploy | Review |
| #9 | BRMSTE-SB/.github | npm install on edge & CF Workers: reproducible CI | Review |

### Conflict resolution needed (CONFLICTING)
| PR | Title | Block |
|---|---|---|
| #60 | feat: HSBC UK fiat banking rail | CONFLICTING — needs rebase |
| #61 | feat: Okta OIDC auth for banking surfaces | CONFLICTING — needs rebase |
| #52 | Consolidate all cryptos to RE-TYRE, BRMSTE, Leading | CONFLICTING |
| #43 | brand BRMSTE Lightning node + HSTS sweep | CONFLICTING |

### Cash substrate PRs — close duplicates
PRs #186–235 in ITBRMSTE/BRMSTE-FINAL are mostly automated cash substrate refresh runs. The scheduled cron is generating duplicates every hour. **Disable the scheduled cash-refresh cron** to stop PR accumulation, or set it to commit directly to a branch rather than opening new PRs each run.

---

## Cloudflare: Zones & Workers Status

- **Account ID:** `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`
- **Worker:** `brmste-com-coming-soon` — deployed but **routes NOT attached** to all 38 zones (CF_API_TOKEN was set but Actions minutes ran out before deploy could run)
- **CF_API_TOKEN:** ✅ Set in GitHub secrets as of 2026-07-07T20:38:43Z

Once GitHub Actions is unblocked, the single `deploy-coming-soon.yml` run will:
1. Deploy the Worker (Wrangler v4, `brmste-coming-soon-v5`)
2. Sync zone manifest from CF API (all 38 zones)
3. Attach routes `*zone/*` → `brmste-com-coming-soon` across all zones
4. Set eToro banking Worker secrets
5. Verify `/health` and `/brand` on brmste.com, brmste.ai, businessscience.ai, re-tyre.com

---

## IBM Quantum / IBM Cloud

- **CRN:** `crn:v1:bluemix:public:quantum-computing:us-east:a/5dd2c9fe5e5b4718987c5ad1167fa19f:191cdf4f-de18-45a9-8fa5-9eb0c68183ba::`
- **Plan:** Pay-As-You-Go (10 free minutes/job — no upgrade needed)
- **Last submitted job:** ISA attestation to `ibm_marrakesh` (from session 81c08c84)
- **Flask BRM API:** Built with KV bindings + cron triggers + `/watsonx/models` endpoint

No IBM blockers — account is on Pay-As-You-Go, jobs can run.

---

## xAI Key

The xAI API key that was shared in chat (`xai-gEvtW7...`) needs to be stored securely via the Credentials vault rather than used directly. Use the secure credential form to register it against host `api.x.ai` before using it in any Grok API calls.

---

## Summary of Actions Required (Operator)

| Priority | Action | Where |
|---|---|---|
| 🔴 CRITICAL | Fix GitHub Actions minutes (upgrade or wait or enable overage) | github.com/organizations/BRMSTE-SB/settings/billing/plans |
| 🔴 CRITICAL | Add `ETORO_API_KEY` + `ETORO_USER_KEY` secrets | github.com/BRMSTE-SB/.github/settings/secrets/actions |
| 🟠 HIGH | Merge PR #34 + #57 in BRMSTE-SB/.github | github.com/BRMSTE-SB/.github/pulls |
| 🟠 HIGH | Merge PR #217 + #236 in BRMSTE-FINAL | github.com/ITBRMSTE/BRMSTE-FINAL-f312f0bf/pulls |
| 🟡 MEDIUM | Create Hetzner Robot webservice user + run fleet-connect.sh | robot.hetzner.com |
| 🟡 MEDIUM | Disable duplicate cash-substrate cron or fix it to not open new PRs | BRMSTE-FINAL scheduled workflows |
| 🟡 MEDIUM | Clarify patents.brmste.com vs leadingmetals.com — are they meant to be identical? | Cloudflare Worker routing |
| 🟢 LOW | Resolve Sweep anchor at foundry.brmste.com | Ceremony/settlement flow |
