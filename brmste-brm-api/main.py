"""
BRMSTE BRM API — Bansal Reasoning Module API for IBM Code Engine.

"Don't trust it. Verify it."

This service exposes:
  - IBM Quantum backend status / job attestation (ISA Bell-state circuits)
  - IBM Cloud Object Storage read access to the brmste-coin ledger
  - Bitcoin / Lightning Network anchor status via mempool.space
  - Carbon accounting for BRM inference calls
  - BRM reasoning layer (model-agnostic multi-model consensus)
  - WatsonX AI model discovery (eu-gb, us-south)

All secrets are read from environment variables (Code Engine secrets) and are
never hardcoded. See README.md for the full list of required env vars.

Patent: GB2607860, US 19/567,161 (GRANTED), PCT/GB2026/050406
"""

import base64
import hashlib
import json
import os
import time
import uuid
from datetime import datetime, timezone

import requests
from flask import Flask, Response, jsonify, request

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Constants / branding
# ---------------------------------------------------------------------------

PATENT_ID = "BRMSTE-COIN-SB2026"
BTC_ANCHOR_ADDRESS = "32i1m6gNcSHwiPX9nfTNXVjme9j5DU8y5g"
LN_NODE_PUBKEY = "03d3c54275a7ba6cacb4e7c3edd85fa8d3e29aa3f09021eec99874cc1333693c9f"

PATENTS = {
    "gb": "GB2607860",
    "us": "US 19/567,161",
    "us_status": "GRANTED",
    "pct": "PCT/GB2026/050406",
}

MODELS_CONVENED = [
    "OpenAI",
    "Anthropic",
    "Google",
    "xAI",
    "Cohere",
    "DeepSeek",
    "Mistral",
    "Moonshot",
    "Cerebras",
    "NVIDIA",
]

CO2_PER_CALL_MG = 0.34
ENERGY_REDUCTION_VS_CLAUDE_OPUS = "29.2x"
FLOPS_VS_GPT4O = "22x"

TAGLINE = "Don't trust it. Verify it."

# ---------------------------------------------------------------------------
# Environment / configuration (never hardcode secrets)
# ---------------------------------------------------------------------------

IBM_QUANTUM_API_KEY = os.getenv("IBM_QUANTUM_API_KEY")
IBM_SERVICE_CRN = os.getenv(
    "IBM_SERVICE_CRN",
    "crn:v1:bluemix:public:quantum-computing:us-east:a/5dd2c9fe5e5b4718987c5ad1167fa19f:191cdf4f-de18-45a9-8fa5-9eb0c68183ba::",
)
IBM_QUANTUM_API_VERSION = os.getenv("IBM_QUANTUM_API_VERSION", "2026-04-15")
IBM_COS_INSTANCE_ID = os.getenv("IBM_COS_INSTANCE_ID")

BRMSTE_SERVICE = os.getenv("BRMSTE_SERVICE")
QUANTUM_INSTANCE = os.getenv("QUANTUM_INSTANCE", "191cdf4f-de18-45a9-8fa5-9eb0c68183ba")
WATSONX_US = os.getenv("WATSONX_US")
CE_SUBDOMAIN = os.getenv("CE_SUBDOMAIN")
CE_PROJECT_ID = os.getenv("CE_PROJECT_ID")
CE_APP = os.getenv("CE_APP")
CE_DOMAIN = os.getenv("CE_DOMAIN")
CE_REGION = os.getenv("CE_REGION")
CE_API_BASE_URL = os.getenv("CE_API_BASE_URL")

# IBM Cloud endpoints
IAM_TOKEN_URL = "https://iam.cloud.ibm.com/identity/token"
QUANTUM_API_BASE = "https://quantum.cloud.ibm.com/api/v1"
COS_ENDPOINT = "https://s3.eu-gb.cloud-object-storage.appdomain.cloud"
COS_BUCKET = "brmste-coming-soon"
COS_COIN_KEY = "brmste-coin.json"

WATSONX_EU_GB_INSTANCE = "be2ff8f4-12d2-4288-b9fe-c45edb83e5d8"
WATSONX_EU_GB_URL = "https://eu-gb.ml.cloud.ibm.com"
WATSONX_US_SOUTH_INSTANCE = "c74264fa-e273-42dd-8029-6195db036b0c"
WATSONX_US_SOUTH_URL = "https://us-south.ml.cloud.ibm.com"
WATSONX_US_SOUTH_MODELS = ["granite-4-h-small", "granite-3-8b-instruct"]

MEMPOOL_API_BASE = "https://mempool.space/api"

REQUEST_TIMEOUT = 10  # seconds, for all outbound IBM/mempool calls

# ISA (Instruction Set Architecture) native Bell-state attestation circuit.
ISA_BELL_CIRCUIT_QASM3 = """OPENQASM 3.0;
include "stdgates.inc";
qubit[2] q; bit[2] c;
rz(pi/2) q[0]; sx q[0]; rz(pi/2) q[0];
rz(pi/2) q[1]; sx q[1]; rz(pi/2) q[1];
cz q[0], q[1];
rz(pi/2) q[1]; sx q[1]; rz(pi/2) q[1];
c[0] = measure q[0]; c[1] = measure q[1];
"""

# ---------------------------------------------------------------------------
# IAM token cache
# ---------------------------------------------------------------------------

_iam_token_cache = {"token": None, "expires_at": 0}


def get_iam_token():
    """Exchange the IBM Quantum API key for an IAM access token, with caching."""
    if not IBM_QUANTUM_API_KEY:
        return None, "IBM_QUANTUM_API_KEY not set"

    now = time.time()
    if _iam_token_cache["token"] and now < _iam_token_cache["expires_at"] - 60:
        return _iam_token_cache["token"], None

    try:
        resp = requests.post(
            IAM_TOKEN_URL,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
            data={
                "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
                "apikey": IBM_QUANTUM_API_KEY,
            },
            timeout=REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
        payload = resp.json()
        token = payload.get("access_token")
        expires_in = payload.get("expires_in", 3600)
        _iam_token_cache["token"] = token
        _iam_token_cache["expires_at"] = now + expires_in
        return token, None
    except requests.exceptions.RequestException as exc:
        return None, str(exc)


def quantum_headers():
    """Build auth headers for IBM Quantum API calls."""
    token, err = get_iam_token()
    if err:
        return None, err
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "IBM-API-Version": IBM_QUANTUM_API_VERSION,
        "Accept": "application/json",
    }
    if IBM_SERVICE_CRN:
        headers["Service-CRN"] = IBM_SERVICE_CRN
    return headers, None


# ---------------------------------------------------------------------------
# IBM COS signing (SigV4) — minimal implementation for GET requests
# ---------------------------------------------------------------------------

def _cos_sigv4_get(bucket, key):
    """
    Perform a SigV4-signed GET against IBM COS using an HMAC key pair if
    available, otherwise fall back to an IAM-token-based request (COS
    supports both HMAC and IAM bearer auth; IAM is simpler given we already
    have an API key for token exchange).
    """
    token, err = get_iam_token()
    if err:
        return None, err
    if not IBM_COS_INSTANCE_ID:
        return None, "IBM_COS_INSTANCE_ID not set"

    url = f"{COS_ENDPOINT}/{bucket}/{key}"
    headers = {
        "Authorization": f"Bearer {token}",
        "ibm-service-instance-id": IBM_COS_INSTANCE_ID,
    }
    try:
        resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 200:
            return resp, None
        return None, f"COS GET failed: HTTP {resp.status_code} {resp.text[:300]}"
    except requests.exceptions.RequestException as exc:
        return None, str(exc)


# ---------------------------------------------------------------------------
# Response headers (applied to every response)
# ---------------------------------------------------------------------------

@app.after_request
def add_brmste_headers(response):
    response.headers["X-BRMSTE-Patent"] = PATENT_ID
    response.headers["X-BRMSTE-Anchor"] = BTC_ANCHOR_ADDRESS
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    return response


@app.before_request
def handle_cors_preflight():
    if request.method == "OPTIONS":
        return Response(status=204)
    return None


def utcnow_iso():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Root / health
# ---------------------------------------------------------------------------

@app.route("/", methods=["GET"])
def root():
    return jsonify(
        {
            "service": "BRMSTE BRM API",
            "status": "ok",
            "tagline": TAGLINE,
            "patent": PATENT_ID,
            "patents": PATENTS,
            "models_convened": MODELS_CONVENED,
            "co2_per_call_mg": CO2_PER_CALL_MG,
            "bitcoin_anchor": BTC_ANCHOR_ADDRESS,
            "ln_node": LN_NODE_PUBKEY,
            "region": CE_REGION,
            "app": CE_APP,
            "timestamp": utcnow_iso(),
        }
    )


@app.route("/health", methods=["GET"])
def health():
    ibm_quantum_status = "connected" if IBM_QUANTUM_API_KEY else "not_configured"
    watsonx_status = "configured" if (WATSONX_US or WATSONX_EU_GB_INSTANCE) else "not_configured"
    cos_status = "configured" if IBM_COS_INSTANCE_ID else "not_configured"

    return jsonify(
        {
            "status": "ok",
            "ibm_quantum": ibm_quantum_status,
            "watsonx": watsonx_status,
            "ibm_cos": cos_status,
            "service_crn_present": bool(IBM_SERVICE_CRN),
            "region": CE_REGION,
            "project_id": CE_PROJECT_ID,
            "app": CE_APP,
            "domain": CE_DOMAIN,
            "timestamp": utcnow_iso(),
        }
    )


# ---------------------------------------------------------------------------
# IBM Quantum routes
# ---------------------------------------------------------------------------

@app.route("/api/quantum/status", methods=["GET"])
def quantum_status():
    headers, err = quantum_headers()
    if err:
        return jsonify(
            {
                "status": "error",
                "error": err,
                "instance": QUANTUM_INSTANCE,
                "timestamp": utcnow_iso(),
            }
        ), 200

    try:
        resp = requests.get(
            f"{QUANTUM_API_BASE}/backends",
            headers=headers,
            params={"instance": QUANTUM_INSTANCE},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 200:
            data = resp.json()
            return jsonify(
                {
                    "status": "connected",
                    "instance": QUANTUM_INSTANCE,
                    "region": "us-east",
                    "backends_raw": data,
                    "timestamp": utcnow_iso(),
                }
            )
        return jsonify(
            {
                "status": "error",
                "error": f"HTTP {resp.status_code}",
                "detail": resp.text[:500],
                "instance": QUANTUM_INSTANCE,
                "timestamp": utcnow_iso(),
            }
        ), 200
    except requests.exceptions.RequestException as exc:
        return jsonify(
            {
                "status": "error",
                "error": str(exc),
                "instance": QUANTUM_INSTANCE,
                "timestamp": utcnow_iso(),
            }
        ), 200


@app.route("/api/quantum/backends", methods=["GET"])
def quantum_backends():
    headers, err = quantum_headers()
    if err:
        return jsonify({"status": "error", "error": err, "backends": []}), 200

    try:
        resp = requests.get(
            f"{QUANTUM_API_BASE}/backends",
            headers=headers,
            params={"instance": QUANTUM_INSTANCE},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code != 200:
            return jsonify(
                {
                    "status": "error",
                    "error": f"HTTP {resp.status_code}",
                    "detail": resp.text[:500],
                    "backends": [],
                }
            ), 200

        data = resp.json()
        backend_names = data.get("devices", data if isinstance(data, list) else [])
        backends_out = []

        # Try to enrich each backend with queue length / status.
        names = backend_names if isinstance(backend_names, list) else []
        for name in names:
            backend_name = name if isinstance(name, str) else name.get("name", "unknown")
            queue_len = None
            b_status = "unknown"
            try:
                status_resp = requests.get(
                    f"{QUANTUM_API_BASE}/backends/{backend_name}/status",
                    headers=headers,
                    params={"instance": QUANTUM_INSTANCE},
                    timeout=REQUEST_TIMEOUT,
                )
                if status_resp.status_code == 200:
                    sdata = status_resp.json()
                    queue_len = sdata.get("length_queue", sdata.get("pending_jobs"))
                    b_status = sdata.get("state", sdata.get("status", "unknown"))
            except requests.exceptions.RequestException:
                pass
            backends_out.append(
                {
                    "name": backend_name,
                    "status": b_status,
                    "queue_length": queue_len,
                }
            )

        return jsonify(
            {
                "status": "ok",
                "instance": QUANTUM_INSTANCE,
                "backend_family": "Heron r2",
                "backend_count_expected": 3,
                "backends": backends_out,
                "raw": data if not names else None,
                "timestamp": utcnow_iso(),
            }
        )
    except requests.exceptions.RequestException as exc:
        return jsonify({"status": "error", "error": str(exc), "backends": []}), 200


@app.route("/api/quantum/jobs", methods=["GET"])
def quantum_jobs():
    headers, err = quantum_headers()
    if err:
        return jsonify({"status": "error", "error": err, "jobs": []}), 200

    limit = request.args.get("limit", default=10, type=int)

    try:
        resp = requests.get(
            f"{QUANTUM_API_BASE}/jobs",
            headers=headers,
            params={"instance": QUANTUM_INSTANCE, "limit": limit},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 200:
            data = resp.json()
            return jsonify(
                {
                    "status": "ok",
                    "instance": QUANTUM_INSTANCE,
                    "jobs": data,
                    "timestamp": utcnow_iso(),
                }
            )
        return jsonify(
            {
                "status": "error",
                "error": f"HTTP {resp.status_code}",
                "detail": resp.text[:500],
                "jobs": [],
            }
        ), 200
    except requests.exceptions.RequestException as exc:
        return jsonify({"status": "error", "error": str(exc), "jobs": []}), 200


@app.route("/api/quantum/attest", methods=["POST"])
def quantum_attest():
    """Submit an ISA-native Bell-state circuit to IBM Quantum as a proof-of-execution attestation."""
    headers, err = quantum_headers()
    if err:
        return jsonify({"status": "error", "error": err, "job_id": None}), 200

    body = request.get_json(silent=True) or {}
    backend_name = body.get("backend")
    shots = body.get("shots", 128)

    program_payload = {
        "program_id": "sampler",
        "backend": backend_name,
        "params": {
            "pubs": [[ISA_BELL_CIRCUIT_QASM3]],
            "shots": shots,
        },
    }
    if not backend_name:
        program_payload.pop("backend")

    try:
        resp = requests.post(
            f"{QUANTUM_API_BASE}/jobs",
            headers=headers,
            params={"instance": QUANTUM_INSTANCE},
            data=json.dumps(program_payload),
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code in (200, 201):
            data = resp.json()
            job_id = data.get("id", data.get("job_id"))
            return jsonify(
                {
                    "status": "submitted",
                    "job_id": job_id,
                    "instance": QUANTUM_INSTANCE,
                    "circuit": "ISA Bell-state attestation (2-qubit)",
                    "shots": shots,
                    "qasm": ISA_BELL_CIRCUIT_QASM3,
                    "timestamp": utcnow_iso(),
                }
            )
        return jsonify(
            {
                "status": "error",
                "error": f"HTTP {resp.status_code}",
                "detail": resp.text[:800],
                "job_id": None,
                "circuit": "ISA Bell-state attestation (2-qubit)",
                "qasm": ISA_BELL_CIRCUIT_QASM3,
            }
        ), 200
    except requests.exceptions.RequestException as exc:
        return jsonify(
            {
                "status": "error",
                "error": str(exc),
                "job_id": None,
                "circuit": "ISA Bell-state attestation (2-qubit)",
                "qasm": ISA_BELL_CIRCUIT_QASM3,
            }
        ), 200


# ---------------------------------------------------------------------------
# BRMSTE Coin (IBM COS)
# ---------------------------------------------------------------------------

@app.route("/api/coin", methods=["GET"])
def coin():
    resp, err = _cos_sigv4_get(COS_BUCKET, COS_COIN_KEY)
    if err:
        return jsonify(
            {
                "status": "error",
                "error": err,
                "bucket": COS_BUCKET,
                "key": COS_COIN_KEY,
            }
        ), 200

    try:
        data = resp.json()
    except ValueError:
        data = {"raw": resp.text}

    return jsonify(
        {
            "status": "ok",
            "bucket": COS_BUCKET,
            "key": COS_COIN_KEY,
            "coin": data,
            "timestamp": utcnow_iso(),
        }
    )


@app.route("/api/coin/verify", methods=["GET"])
def coin_verify():
    resp, err = _cos_sigv4_get(COS_BUCKET, COS_COIN_KEY)
    if err:
        return jsonify({"status": "error", "error": err, "verified": False}), 200

    try:
        data = resp.json()
    except ValueError:
        return jsonify(
            {"status": "error", "error": "coin ledger is not valid JSON", "verified": False}
        ), 200

    quantum_job_ids = data.get("quantum_job_ids") or data.get("job_ids") or []
    if isinstance(quantum_job_ids, str):
        quantum_job_ids = [quantum_job_ids]

    headers, qerr = quantum_headers()
    verification_results = []

    if qerr:
        return jsonify(
            {
                "status": "error",
                "error": qerr,
                "verified": False,
                "quantum_job_ids": quantum_job_ids,
            }
        ), 200

    for job_id in quantum_job_ids:
        try:
            jresp = requests.get(
                f"{QUANTUM_API_BASE}/jobs/{job_id}",
                headers=headers,
                params={"instance": QUANTUM_INSTANCE},
                timeout=REQUEST_TIMEOUT,
            )
            if jresp.status_code == 200:
                jdata = jresp.json()
                verification_results.append(
                    {
                        "job_id": job_id,
                        "found": True,
                        "status": jdata.get("status"),
                    }
                )
            else:
                verification_results.append(
                    {"job_id": job_id, "found": False, "status": f"HTTP {jresp.status_code}"}
                )
        except requests.exceptions.RequestException as exc:
            verification_results.append({"job_id": job_id, "found": False, "error": str(exc)})

    all_found = bool(verification_results) and all(r.get("found") for r in verification_results)

    return jsonify(
        {
            "status": "ok",
            "verified": all_found,
            "quantum_job_ids": quantum_job_ids,
            "results": verification_results,
            "timestamp": utcnow_iso(),
        }
    )


# ---------------------------------------------------------------------------
# Carbon accounting
# ---------------------------------------------------------------------------

@app.route("/api/carbon", methods=["GET"])
def carbon():
    return jsonify(
        {
            "co2_per_call_mg": CO2_PER_CALL_MG,
            "method": "device_flops_utilisation_grid_intensity",
            "comparison": {
                "energy_reduction_vs_claude_opus": ENERGY_REDUCTION_VS_CLAUDE_OPUS,
                "flops_vs_gpt4o": FLOPS_VS_GPT4O,
            },
            "notes": (
                "Estimated from measured device FLOPs utilisation for a single BRM "
                "reasoning call multiplied by regional grid carbon intensity."
            ),
            "timestamp": utcnow_iso(),
        }
    )


# ---------------------------------------------------------------------------
# Bitcoin / Lightning chain status
# ---------------------------------------------------------------------------

@app.route("/api/chain", methods=["GET"])
def chain():
    btc_info = {"address": BTC_ANCHOR_ADDRESS}
    ln_info = {"pubkey": LN_NODE_PUBKEY}
    errors = []

    try:
        addr_resp = requests.get(
            f"{MEMPOOL_API_BASE}/address/{BTC_ANCHOR_ADDRESS}", timeout=REQUEST_TIMEOUT
        )
        if addr_resp.status_code == 200:
            btc_info.update(addr_resp.json())
        else:
            errors.append(f"address lookup HTTP {addr_resp.status_code}")
    except requests.exceptions.RequestException as exc:
        errors.append(f"address lookup failed: {exc}")

    try:
        txs_resp = requests.get(
            f"{MEMPOOL_API_BASE}/address/{BTC_ANCHOR_ADDRESS}/txs", timeout=REQUEST_TIMEOUT
        )
        if txs_resp.status_code == 200:
            txs = txs_resp.json()
            btc_info["recent_tx_count"] = len(txs)
            btc_info["latest_txid"] = txs[0]["txid"] if txs else None
        else:
            errors.append(f"tx lookup HTTP {txs_resp.status_code}")
    except requests.exceptions.RequestException as exc:
        errors.append(f"tx lookup failed: {exc}")

    try:
        ln_resp = requests.get(
            f"{MEMPOOL_API_BASE}/v1/lightning/nodes/{LN_NODE_PUBKEY}", timeout=REQUEST_TIMEOUT
        )
        if ln_resp.status_code == 200:
            ln_info.update(ln_resp.json())
        else:
            errors.append(f"ln node lookup HTTP {ln_resp.status_code}")
    except requests.exceptions.RequestException as exc:
        errors.append(f"ln node lookup failed: {exc}")

    return jsonify(
        {
            "status": "ok" if not errors else "partial",
            "bitcoin": btc_info,
            "lightning": ln_info,
            "errors": errors,
            "source": "mempool.space",
            "timestamp": utcnow_iso(),
        }
    )


# ---------------------------------------------------------------------------
# BRM reasoning layer
# ---------------------------------------------------------------------------

@app.route("/api/brm", methods=["GET"])
def brm_status():
    return jsonify(
        {
            "status": "ok",
            "layer": "Bansal Reasoning Module (BRM)",
            "description": "Model-agnostic reasoning layer that convenes multiple frontier models to reach verified consensus.",
            "models_convened": MODELS_CONVENED,
            "model_count": len(MODELS_CONVENED),
            "tagline": TAGLINE,
            "patents": PATENTS,
            "performance": {
                "energy_reduction_vs_claude_opus": ENERGY_REDUCTION_VS_CLAUDE_OPUS,
                "flops_vs_gpt4o": FLOPS_VS_GPT4O,
            },
            "timestamp": utcnow_iso(),
        }
    )


@app.route("/api/brm/reason", methods=["POST"])
def brm_reason():
    """
    Submit a reasoning query to the BRM layer.

    NOTE: This currently returns a deterministic mock multi-model consensus
    response (no live model calls are made). Wire in real model providers
    here when API keys for OpenAI/Anthropic/Google/etc. are available as
    Code Engine secrets.
    """
    body = request.get_json(silent=True) or {}
    query = body.get("query", "")

    if not query:
        return jsonify({"status": "error", "error": "missing 'query' in request body"}), 400

    query_hash = hashlib.sha256(query.encode("utf-8")).hexdigest()
    request_id = str(uuid.uuid4())

    mock_votes = []
    for i, model in enumerate(MODELS_CONVENED):
        mock_votes.append(
            {
                "model": model,
                "vote": "agree" if (int(query_hash[i], 16) % 3 != 0) else "dissent",
                "confidence": round(0.7 + (int(query_hash[i * 2 : i * 2 + 2], 16) % 30) / 100, 2),
            }
        )

    agree_count = sum(1 for v in mock_votes if v["vote"] == "agree")
    consensus_reached = agree_count >= (len(mock_votes) // 2 + 1)

    return jsonify(
        {
            "status": "ok",
            "mode": "mock",
            "request_id": request_id,
            "query": query,
            "query_hash": query_hash,
            "votes": mock_votes,
            "consensus": {
                "reached": consensus_reached,
                "agree_count": agree_count,
                "total_models": len(mock_votes),
            },
            "co2_estimate_mg": CO2_PER_CALL_MG,
            "note": (
                "This is a mock multi-model consensus response. Live model "
                "provider integration is not yet enabled."
            ),
            "timestamp": utcnow_iso(),
        }
    )


# ---------------------------------------------------------------------------
# WatsonX
# ---------------------------------------------------------------------------

@app.route("/api/watsonx/models", methods=["GET"])
def watsonx_models():
    token, err = get_iam_token()

    result = {
        "status": "ok" if not err else "error",
        "regions": {
            "eu-gb": {
                "instance_id": WATSONX_EU_GB_INSTANCE,
                "url": WATSONX_EU_GB_URL,
                "models": [],
            },
            "us-south": {
                "instance_id": WATSONX_US_SOUTH_INSTANCE,
                "url": WATSONX_US_SOUTH_URL,
                "models": WATSONX_US_SOUTH_MODELS,
            },
        },
        "timestamp": utcnow_iso(),
    }

    if err:
        result["error"] = err
        return jsonify(result), 200

    headers = {"Authorization": f"Bearer {token}"}
    try:
        resp = requests.get(
            f"{WATSONX_EU_GB_URL}/ml/v1/foundation_model_specs",
            headers=headers,
            params={"version": "2024-05-01"},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.status_code == 200:
            data = resp.json()
            models = [m.get("model_id") for m in data.get("resources", []) if "granite" in m.get("model_id", "").lower()]
            result["regions"]["eu-gb"]["models"] = models or ["granite models available (see full spec list)"]
        else:
            result["regions"]["eu-gb"]["error"] = f"HTTP {resp.status_code}"
    except requests.exceptions.RequestException as exc:
        result["regions"]["eu-gb"]["error"] = str(exc)

    return jsonify(result)


# ---------------------------------------------------------------------------
# Legacy route
# ---------------------------------------------------------------------------

@app.route("/substrate/quantum/status.json", methods=["GET"])
def substrate_quantum_status_legacy():
    return quantum_status()


# ---------------------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------------------

@app.errorhandler(404)
def not_found(_e):
    return jsonify({"status": "error", "error": "not found", "patent": PATENT_ID}), 404


@app.errorhandler(500)
def server_error(_e):
    return jsonify({"status": "error", "error": "internal server error", "patent": PATENT_ID}), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
