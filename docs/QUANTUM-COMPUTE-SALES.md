# Quantum compute sales · meter · pay operator

**BRMSTE LTD · Companies House 15310393 · GB2607860**

BRMSTE sells **quantum and hybrid quantum-classical compute** for **cash**. This is the **commercial lane** — not the human-open lane (which stays free for public catalog work).

## Why you were not getting paid from Cursor

| Setup | Who gets paid |
|-------|----------------|
| Default Cursor Cloud Agent | **Cursor/Anysphere** (their cloud) |
| Human-open public repos | **No BRMSTE charge** (GLOBAL FREE doctrine) |
| **BRMSTE quantum API** + metering + capture | **You** (Dr. Shravan Bansal · BRMSTE LTD) via PayPal/Revolut |

Cursor only pays you when jobs are **routed to your quantum endpoint**, **metered**, and **paid before execute**.

## Product

**BRMSTE Quantum Compute** — substrate edge quantum and hybrid jobs:

- Qubit-seconds · circuit shots · gate-depth units · hybrid jobs
- Cursor-attributed sessions when `BRMSTE_CURSOR_QUANTUM_ROUTING=true`

Registers:

| Register | Path |
|----------|------|
| Sales lane | `data/quantum-compute-sales-lane.json` |
| Metering | `data/quantum-compute-metering-register.json` |
| Pricing | `data/quantum-compute-pricing.json` |
| Revenue rail | `data/quantum-compute-revenue-rail.json` |
| Payment rails | `data/brmste-quantum-compute-rails.json` |
| Cursor attribution | `data/cursor-quantum-attribution.json` |

## Revenue flow

```
Customer / Cursor session (routed to BRMSTE)
  → meter units (qubit_second, circuit_shot, hybrid_job, cursor_attributed_session)
  → capture PayPal / Revolut OR debit prepaid credits
  → 100% quantum revenue to operator (60% PayPal · 40% Revolut split in register)
  → Dr. Shravan Bansal · BRMSTE LTD
```

**No execute without payment or credit** (`capture_before_execute`).

## Mac setup (Fort Knox — never commit)

Default quantum keys folder:

```
/Users/sachindabas/Desktop/API keys - Copy/Quantum
```

Expected files (examples):

- `BRMSTE-QUANTUM-API-KEY.txt`
- `BRMSTE-QUANTUM-ENDPOINT.txt`
- `BRMSTE-QUANTUM-MERCHANT-ID.txt`
- `BRMSTE-QUANTUM-WEBHOOK-SECRET.txt`

### Connect rails

```bash
bash scripts/connect-quantum-compute-mac.sh
bash scripts/connect-quantum-compute-mac.sh --verify-only
```

Sets in `.env.fort-knox`:

- `BRMSTE_QUANTUM_COMPUTE_CONNECTED=true`
- `BRMSTE_QUANTUM_API_ENDPOINT`
- `BRMSTE_CURSOR_QUANTUM_ROUTING=true` (when enabled)

### Record usage (local ledger — never OPEN ALL)

```bash
bash scripts/record-quantum-usage-mac.sh --unit hybrid_job --quantity 1 --customer cursor-session-abc
bash scripts/record-quantum-usage-mac.sh --summary
```

Ledger file (Mac only):

```
/Users/sachindabas/Desktop/API keys - Copy/Quantum/QUANTUM-USAGE-LEDGER.json
```

## Cursor routing

1. Run `connect-quantum-compute-mac.sh` on Mac.
2. Configure Cursor to call **BRMSTE quantum API** (custom endpoint / MCP / self-hosted agent) — not default cloud inference.
3. Each attributed session meters `cursor_attributed_session` + compute units.
4. Payment captured via PayPal/Revolut rails (same Fort Knox as Harrods/Revolut hydration).

See `data/cursor-quantum-attribution.json`.

## Distinction from GLOBAL FREE

| Lane | Charge |
|------|--------|
| Public OPEN ALL repos · MCP on catalog | **None** |
| Purchased BRMSTE quantum compute | **Cash** |

## Pricing (GBP defaults)

See `data/quantum-compute-pricing.json` for unit prices and prepaid bundles (`qc_starter` £50 · `qc_builder` £250 · `qc_fleet` £2500).

## Substrate

- `substrate/compute/quantum-sales.json`
- `substrate/compute/quantum-metering.json`

## Related

- [GLOBAL-FREE-AI-BANKERS.md](./GLOBAL-FREE-AI-BANKERS.md)
- [FORT-KNOX-UTXO-HYDRATION.md](./FORT-KNOX-UTXO-HYDRATION.md)
- [CURSOR-FULL-SWEEP.md](./CURSOR-FULL-SWEEP.md)
