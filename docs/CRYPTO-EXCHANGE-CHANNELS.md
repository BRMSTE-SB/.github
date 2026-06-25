# Kraken · Coinbase · Moonshot channels

**Kraken** and **Coinbase** are BRMSTE **crypto exchange channels** (Fort Knox API keys). **Moonshot** is the **Kimi AI API** — not a BTC exchange.

## Channel map

| Channel | Kind | Use for BTC → Revolut? |
|---------|------|------------------------|
| **Kraken** | Crypto exchange | **Yes** — deposit/sell BTC, withdraw fiat |
| **Coinbase** | Crypto exchange | **Yes** — deposit/sell BTC, withdraw fiat |
| **Moonshot** | Kimi AI API | **No** — API billing + UTXO hydration lane only |

## Mac key folders

```
/Users/sachindabas/Desktop/API keys - Copy/
├── Kraken/
│   ├── KRAKEN-API-KEY.txt
│   └── KRAKEN-API-SECRET.txt
├── Coinbase/
│   ├── COINBASE-API-KEY.txt
│   ├── COINBASE-API-SECRET.txt
│   └── COINBASE-PASSPHRASE.txt   (Exchange API)
└── AI keys/
    └── KIMI 2.6 Moonshot AI.txt  (Moonshot — not exchange)
```

## Connect on Mac

```bash
# All exchange + Moonshot AI keys
bash scripts/connect-crypto-exchanges-mac.sh
bash scripts/connect-crypto-exchanges-mac.sh --verify-only

# Or individually
bash scripts/connect-kraken-mac.sh
bash scripts/connect-coinbase-mac.sh
bash scripts/import-ai-keys-mac.sh
```

Expect: `kraken_api=ok` / `coinbase_api=ok` after valid keys.

## Sell from balance (Mac · Fort Knox)

Read balances (default — no trade):

```bash
bash scripts/sell-from-balance-mac.sh --balance
```

Dry-run market sell:

```bash
bash scripts/sell-from-balance-mac.sh --exchange kraken --pair XBTGBP --amount all --dry-run
bash scripts/sell-from-balance-mac.sh --exchange coinbase --pair BTC-GBP --amount all --dry-run
```

Live sell (requires explicit confirm):

```bash
BRMSTE_CONFIRM_SELL=1 bash scripts/sell-from-balance-mac.sh --exchange kraken --pair XBTGBP --amount all --execute
```

Register: `data/sell-from-balance-lane.json`

## BTC → Revolut (100 BTC or any amount)

This repo **does not auto-trade**. On your Mac after connect:

1. **Kraken or Coinbase app/UI** — deposit BTC (or sell from balance).
2. **Withdraw fiat** (GBP/EUR) to **Revolut Business** account details from the Revolut app.
3. Verify Revolut: `bash scripts/connect-revolut-mac.sh --verify-only`

Large amounts (e.g. 100 BTC) require exchange limits, OTC, and compliance — use Kraken/Coinbase support or OTC desks.

## Registers

| File | Role |
|------|------|
| `data/crypto-exchange-channels.json` | Master channel manifest |
| `data/brmste-kraken-rails.json` | Kraken rail |
| `data/brmste-coinbase-rails.json` | Coinbase rail |
| `data/brmste-moonshot-payment-rails.json` | Moonshot AI (not exchange) |

BRMSTE LTD · Companies House 15310393
