# Fleet mempool.space + LND

**BRMSTE LTD · Companies House 15310393 · GB2607860**

Brings up a self-hosted [mempool.space](https://mempool.space) explorer and an
[LND](https://github.com/lightningnetwork/lnd) Lightning node on each of the 15
BRMSTE Hetzner nodes. One shared `bitcoind` (full `txindex`) feeds both mempool's
electrs backend and LND.

## Stack (per node)

| Service | Image | Role |
|---------|-------|------|
| bitcoind | `getumbrel/docker-bitcoind` | Full node, txindex, ZMQ |
| electrs | `getumbrel/electrs` | Electrum backend for mempool |
| mariadb | `mariadb:11` | mempool index store |
| mempool-api | `mempool/backend` | mempool backend |
| mempool-web | `mempool/frontend` | explorer UI (`127.0.0.1:8999`) |
| lnd | `lightninglabs/lnd` | Lightning node (`127.0.0.1:10009`) |

## Bring the fleet up (Kohinoor Mac)

```bash
# 1. On each node, once: place secrets (never in git)
#    /opt/brmste/mempool-lnd/node.env  (from node.env.example)
# 2. From the Mac:
bash scripts/bring-up-mempool-lnd-fleet.sh              # all 15 nodes
bash scripts/bring-up-mempool-lnd-fleet.sh lucifer      # one node
HEALTH_ONLY=1 bash scripts/bring-up-mempool-lnd-fleet.sh  # probe only
```

## Notes & guardrails

- **Full IBD:** each `bitcoind` performs a full initial block download (~700 GB,
  several hours). mempool populates as blocks sync; `getinfo` on LND is green once
  bitcoind reports synced.
- **Ports stay local.** mempool (`8999`) and LND RPC (`10009`) bind to `127.0.0.1`
  and must sit behind the edge reverse proxy with auth before any public exposure.
  LND `9735` (p2p) is the only port intended to be opened outward.
- **Secrets live on the node.** `node.env` is git-ignored; RPC and DB passwords are
  set on each server, never pasted in chat or committed (MCP-strict doctrine).
- **LND holds real keys.** Back up each node's `seed`/`channel.backup` before opening
  channels. Treat mainnet LND as custody.

BRMSTE LTD · CH 15310393 · GB2607860
