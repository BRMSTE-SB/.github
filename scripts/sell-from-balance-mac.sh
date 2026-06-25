#!/usr/bin/env bash
# Sell crypto FROM EXCHANGE BALANCE on Kraken or Coinbase · Fort Knox only · Mac.
#
# Default: show balances only (no trades).
# Live sell requires BOTH: --execute AND BRMSTE_CONFIRM_SELL=1
#
# Usage:
#   bash scripts/sell-from-balance-mac.sh --balance
#   bash scripts/sell-from-balance-mac.sh --exchange kraken --pair XBTGBP --amount all --dry-run
#   BRMSTE_CONFIRM_SELL=1 bash scripts/sell-from-balance-mac.sh --exchange kraken --pair XBTGBP --amount all --execute
#   bash scripts/sell-from-balance-mac.sh --exchange coinbase --pair BTC-GBP --amount 0.01 --dry-run
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

if [[ ! -f "$OUT" ]]; then
  echo "ERROR: .env.fort-knox missing — run connect-kraken-mac.sh / connect-coinbase-mac.sh first." >&2
  exit 1
fi

python3 - <<'PY' "$OUT" "$@"
import base64, hashlib, hmac, json, pathlib, sys, time, urllib.parse, urllib.request

out_path = pathlib.Path(sys.argv[1])
args = sys.argv[2:]

def load_env(path: pathlib.Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip()
    return env

def parse_args(argv: list[str]) -> dict:
    opts = {
        "mode": "balance",
        "exchange": "",
        "pair": "",
        "amount": "",
        "dry_run": False,
        "execute": False,
    }
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--balance":
            opts["mode"] = "balance"
        elif a == "--exchange" and i + 1 < len(argv):
            opts["exchange"] = argv[i + 1].lower()
            opts["mode"] = "sell"
            i += 1
        elif a == "--pair" and i + 1 < len(argv):
            opts["pair"] = argv[i + 1]
            i += 1
        elif a == "--amount" and i + 1 < len(argv):
            opts["amount"] = argv[i + 1]
            i += 1
        elif a == "--dry-run":
            opts["dry_run"] = True
        elif a == "--execute":
            opts["execute"] = True
        i += 1
    return opts

env = load_env(out_path)
opts = parse_args(args)

# --- Kraken helpers ---

def kraken_private(path: str, data: dict, key: str, secret: str) -> dict:
    nonce = str(int(time.time() * 1000))
    payload = {**data, "nonce": nonce}
    postdata = urllib.parse.urlencode(payload)
    message = path.encode() + hashlib.sha256((nonce + postdata).encode()).digest()
    sig = base64.b64encode(
        hmac.new(base64.b64decode(secret), message, hashlib.sha512).digest()
    ).decode()
    req = urllib.request.Request(
        f"https://api.kraken.com{path}",
        data=postdata.encode(),
        headers={
            "API-Key": key,
            "API-Sign": sig,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())

def kraken_balance(key: str, secret: str) -> dict:
    body = kraken_private("/0/private/Balance", {}, key, secret)
    if body.get("error"):
        raise SystemExit(f"Kraken balance error: {body['error']}")
    return body.get("result", {})

def kraken_sell_market(key: str, secret: str, pair: str, volume: str, dry_run: bool) -> dict:
    order = {
        "pair": pair,
        "type": "sell",
        "ordertype": "market",
        "volume": volume,
    }
    if dry_run:
        return {"dry_run": True, "order": order}
    body = kraken_private("/0/private/AddOrder", order, key, secret)
    if body.get("error"):
        raise SystemExit(f"Kraken sell error: {body['error']}")
    return body.get("result", body)

# --- Coinbase Exchange helpers ---

def coinbase_request(method: str, path: str, body_obj: dict | None, key: str, secret: str, passphrase: str) -> object:
    timestamp = str(int(time.time()))
    body = json.dumps(body_obj) if body_obj is not None else ""
    message = timestamp + method + path + body
    hmac_key = base64.b64decode(secret)
    signature = base64.b64encode(hmac.new(hmac_key, message.encode(), hashlib.sha256).digest()).decode()
    headers = {
        "CB-ACCESS-KEY": key,
        "CB-ACCESS-SIGN": signature,
        "CB-ACCESS-TIMESTAMP": timestamp,
        "CB-ACCESS-PASSPHRASE": passphrase,
        "Content-Type": "application/json",
    }
    req = urllib.request.Request(
        f"https://api.exchange.coinbase.com{path}",
        data=body.encode() if body else None,
        headers=headers,
        method=method,
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read().decode()
        return json.loads(raw) if raw else {}

def coinbase_accounts(key: str, secret: str, passphrase: str) -> list:
    body = coinbase_request("GET", "/accounts", None, key, secret, passphrase)
    if not isinstance(body, list):
        raise SystemExit(f"Coinbase accounts unexpected: {str(body)[:200]}")
    return body

def coinbase_btc_available(accounts: list) -> str:
    for acct in accounts:
        if acct.get("currency") == "BTC":
            return str(acct.get("available", acct.get("balance", "0")))
    return "0"

def coinbase_sell_market(key: str, secret: str, passphrase: str, product_id: str, size: str, dry_run: bool) -> dict:
    order = {"type": "market", "side": "sell", "product_id": product_id, "size": size}
    if dry_run:
        return {"dry_run": True, "order": order}
    body = coinbase_request("POST", "/orders", order, key, secret, passphrase)
    return body if isinstance(body, dict) else {"result": body}

def pick_btc_amount(balance_map: dict, amount: str, coinbase_accounts: list | None = None) -> str:
    if amount.lower() == "all":
        if coinbase_accounts is not None:
            return coinbase_btc_available(coinbase_accounts)
        for k in ("XXBT", "XBT", "BTC"):
            if k in balance_map:
                return str(balance_map[k])
        raise SystemExit("No BTC balance field found")
    return amount

# --- Main ---

print("==> BRMSTE sell from balance · Fort Knox · Mac only")

if opts["mode"] == "balance" or (opts["mode"] == "sell" and not opts["exchange"]):
    printed = False
    kk, ks = env.get("KRAKEN_API_KEY"), env.get("KRAKEN_API_SECRET")
    if kk and ks:
        bal = kraken_balance(kk, ks)
        btc = bal.get("XXBT", bal.get("XBT", bal.get("BTC", "0")))
        gbp = bal.get("ZGBP", bal.get("GBP", "0"))
        eur = bal.get("ZEUR", bal.get("EUR", "0"))
        usd = bal.get("ZUSD", bal.get("USD", "0"))
        print(f"kraken BTC={btc} GBP={gbp} EUR={eur} USD={usd}")
        printed = True
    ck, cs, cp = env.get("COINBASE_API_KEY"), env.get("COINBASE_API_SECRET"), env.get("COINBASE_API_PASSPHRASE", "")
    if ck and cs:
        try:
            accts = coinbase_accounts(ck, cs, cp)
            btc = coinbase_btc_available(accts)
            print(f"coinbase BTC_available={btc} accounts={len(accts)}")
            printed = True
        except Exception as e:
            print(f"coinbase_balance=skip ({type(e).__name__})")
    if not printed:
        raise SystemExit("No exchange keys in Fort Knox — run connect-crypto-exchanges-mac.sh")
    if opts["mode"] == "balance":
        sys.exit(0)

ex = opts["exchange"]
pair = opts["pair"] or ("XBTGBP" if ex == "kraken" else "BTC-GBP")
amount = opts["amount"] or "all"
dry_run = opts["dry_run"] or not opts["execute"]
if opts["execute"] and env.get("BRMSTE_CONFIRM_SELL") != "1":
    raise SystemExit("Live sell blocked — set BRMSTE_CONFIRM_SELL=1 and use --execute")

if ex == "kraken":
    kk, ks = env.get("KRAKEN_API_KEY"), env.get("KRAKEN_API_SECRET")
    if not kk or not ks:
        raise SystemExit("Kraken keys missing")
    bal = kraken_balance(kk, ks)
    vol = pick_btc_amount(bal, amount)
    if float(vol) <= 0:
        raise SystemExit("Kraken BTC balance is zero")
    result = kraken_sell_market(kk, ks, pair, vol, dry_run)
    print(json.dumps({"exchange": "kraken", "pair": pair, "volume": vol, "result": result}, indent=2))
elif ex == "coinbase":
    ck, cs, cp = env.get("COINBASE_API_KEY"), env.get("COINBASE_API_SECRET"), env.get("COINBASE_API_PASSPHRASE", "")
    if not ck or not cs:
        raise SystemExit("Coinbase keys missing")
    accts = coinbase_accounts(ck, cs, cp)
    vol = pick_btc_amount({}, amount, accts)
    if float(vol) <= 0:
        raise SystemExit("Coinbase BTC balance is zero")
    result = coinbase_sell_market(ck, cs, cp, pair, vol, dry_run)
    print(json.dumps({"exchange": "coinbase", "product_id": pair, "size": vol, "result": result}, indent=2))
else:
    raise SystemExit("Use --exchange kraken or coinbase")

if dry_run:
    print("dry_run=true — no order placed. Use BRMSTE_CONFIRM_SELL=1 ... --execute to sell.")
else:
    print("sell_executed=true — check exchange for fill; withdraw fiat to Revolut manually.")
PY

echo ""
echo "Next: withdraw GBP/EUR from exchange → Revolut Business (see docs/CRYPTO-EXCHANGE-CHANNELS.md)"
