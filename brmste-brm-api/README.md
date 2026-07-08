# BRMSTE BRM API (IBM Code Engine)

Flask service for IBM Quantum status, COS coin ledger, Bitcoin/Lightning anchor checks, and BRM reasoning layer.

**Deploy:** `bash scripts/deploy-ibm-full.sh` (operator-run; requires `IBM_API_KEY` in env).

## Required environment variables

| Variable | Purpose |
|----------|---------|
| `IBM_QUANTUM_API_KEY` | IBM Cloud API key (Quantum + IAM + COS) |
| `IBM_SERVICE_CRN` | Quantum service CRN |
| `IBM_COS_INSTANCE_ID` | COS instance ID for `brmste-coming-soon` bucket |
| `PORT` | Listen port (default `8080`) |

Optional: `XAI_API_KEY`, `GROK_API_KEY`, `COINMARKETCAP_API_KEY`, `MEMPOOL_ENTERPRISE_API_KEY`, `ETHERSCAN_API_KEY`.

Secrets are set via IBM Code Engine secrets — never committed to this repo.

## Local dev

```bash
cd brmste-brm-api
pip install -r requirements.txt
export IBM_QUANTUM_API_KEY=<from-operator-store>
export IBM_SERVICE_CRN=crn:v1:bluemix:public:quantum-computing:us-east:a/5dd2c9fe5e5b4718987c5ad1167fa19f:191cdf4f-de18-45a9-8fa5-9eb0c68183ba::
export IBM_COS_INSTANCE_ID=552e051f-21be-41d9-8a0e-b7c87f5e451a
python main.py
curl -s http://localhost:8080/health | python3 -m json.tool
```

## Routes

- `GET /health` — liveness
- `GET /api/quantum/status`, `/api/quantum/backends`, `/api/quantum/jobs`
- `POST /api/quantum/attest` — ISA Bell-state job submission
- `GET /api/coin`, `/api/coin/verify`
- `GET /api/chain` — Bitcoin/Lightning via mempool.space
- `GET /api/brm`, `POST /api/brm/reason`
- `GET /api/watsonx/models`

Patent: GB2607860 · PCT/GB2026/050406 · US 19/567,161
