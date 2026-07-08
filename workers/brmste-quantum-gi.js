/**
 * BRMSTE Quantum GI Worker
 * ========================
 * Routes:
 *   GET  /health, /                     → liveness
 *   GET  /status, /substrate/quantum/status.json → full unified status
 *   GET  /quantum, /quantum/backends    → IBM Quantum backend list
 *   GET  /quantum/status                → lightweight backend recommendation
 *   GET  /quantum/jobs[?limit=]         → recent job list
 *   GET  /quantum/jobs/:id              → single job + metrics
 *   POST /quantum/attest                → submit ISA Bell circuit (fixes error 1517)
 *   GET  /coin, /ibm/cos/coin           → brmste-coin.json from IBM COS
 *   GET  /coin/inventory                → condensed coin summary
 *   GET  /coin/verify                   → cross-check quantum job IDs
 *   GET  /ibm/cos/objects               → full bucket listing
 *   GET  /watsonx/models                → WatsonX foundation model list
 *
 * Cron (scheduled):
 *   "0 * * * *"  → hourly ISA attestation job + KV update
 *   "0 0 * * *"  → daily coin.json sync + full KV registry write
 *
 * Secrets (wrangler secret put):
 *   IBM_QUANTUM_API_KEY
 *
 * Vars (wrangler.toml):
 *   SERVICE_CRN, COS_ENDPOINT, COS_BUCKET, COS_INSTANCE,
 *   ANCHOR_ADDRESS, LN_NODE, BRM_API, WATSONX_EU_GB, WATSONX_US_SOUTH
 *
 * KV (wrangler.toml [[kv_namespaces]]):
 *   MINE_EVENTS  (binding name)
 *
 * Patent: BRMSTE-COIN-SB2026 · BRMSTE-KERNEL-SB2026
 * Inventor: Shravan Krishan Avtar Bansal
 */

// ── Constants ─────────────────────────────────────────────────────────────────
const QUANTUM_BASE     = "https://quantum.cloud.ibm.com/api/v1";
const IAM_URL          = "https://iam.cloud.ibm.com/identity/token";
const IBM_API_VERSION  = "2026-04-15";
const MEMPOOL_API      = "https://mempool.space/api";
const WATSONX_EU_BASE  = "https://eu-gb.ml.cloud.ibm.com";
const WATSONX_US_BASE  = "https://us-south.ml.cloud.ibm.com";

// ISA Bell-state circuit for Heron r2 (fixes error 1517)
// Native gate set: {cz, id, rz, sx, x} — no h gate
// H decomposition: rz(π/2) · sx · rz(π/2)
const ISA_BELL_CIRCUIT = `OPENQASM 3.0;
include "stdgates.inc";
qubit[2] q;
bit[2] c;
// H q[0] via native gates
rz(pi/2) q[0];
sx q[0];
rz(pi/2) q[0];
// CX(q[0],q[1]) via H-sandwich + CZ
rz(pi/2) q[1];
sx q[1];
rz(pi/2) q[1];
cz q[0], q[1];
rz(pi/2) q[1];
sx q[1];
rz(pi/2) q[1];
// Measure
c[0] = measure q[0];
c[1] = measure q[1];`;

// ── IAM token cache (per isolate) ────────────────────────────────────────────
let _token = null;
let _tokenExpiry = 0;

async function getToken(apiKey) {
  const now = Date.now() / 1000;
  if (_token && now < _tokenExpiry - 60) return _token;
  const r = await fetch(IAM_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${encodeURIComponent(apiKey)}`,
  });
  if (!r.ok) throw new Error(`IAM token failed: ${r.status}`);
  const d = await r.json();
  _token = d.access_token;
  _tokenExpiry = now + (d.expires_in || 3600);
  return _token;
}

function qHdrs(token, env) {
  return {
    "Authorization": `Bearer ${token}`,
    "Service-CRN": env.SERVICE_CRN,
    "IBM-API-Version": IBM_API_VERSION,
    "Accept": "application/json",
    "Content-Type": "application/json",
  };
}

function cosHdrs(token, env) {
  return {
    "Authorization": `Bearer ${token}`,
    "ibm-service-instance-id": env.COS_INSTANCE,
    "Accept": "application/json",
  };

}

function ibmHdrs(token) {
  return { "Authorization": `Bearer ${token}`, "Accept": "application/json" };
}

// ── Response helpers ──────────────────────────────────────────────────────────
function jsonResp(data, status = 200, env = {}) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "X-BRMSTE-Patent": "BRMSTE-COIN-SB2026",
      "X-BRMSTE-Anchor": env.ANCHOR_ADDRESS || "32i1m6gNcSHwiPX9nfTNXVjme9j5DU8y5g",
      "X-BRMSTE-LN": env.LN_NODE || "",
    },
  });
}

// ── Backend selector ──────────────────────────────────────────────────────────
async function getBackends(token, env) {
  const r = await fetch(`${QUANTUM_BASE}/backends`, { headers: qHdrs(token, env) });
  const d = await r.json();
  return (d.devices || []).sort((a, b) => a.queue_length - b.queue_length);
}

// ── Submit ISA attestation job ─────────────────────────────────────────────
async function submitAttestationJob(token, env, coin_id, backend) {
  const payload = {
    program_id: "sampler",
    backend,
    tags: ["brmste-coin", "isa-bell", "quantum-attest", coin_id ? coin_id.substring(0, 30) : "brmste"],
    params: {
      pubs: [[{ qasm: ISA_BELL_CIRCUIT }, [], 4096]],
      version: 2,
    },
  };
  const r = await fetch(`${QUANTUM_BASE}/jobs`, {
    method: "POST",
    headers: qHdrs(token, env),
    body: JSON.stringify(payload),
  });
  return { status: r.status, data: await r.json() };
}

// ── KV helpers ────────────────────────────────────────────────────────────────
async function kvWrite(env, key, value) {
  if (!env.MINE_EVENTS) return;
  try {
    await env.MINE_EVENTS.put(key, JSON.stringify(value), { expirationTtl: 86400 * 30 });
  } catch (_) {}
}

async function kvRead(env, key) {
  if (!env.MINE_EVENTS) return null;
  try {
    const v = await env.MINE_EVENTS.get(key);
    return v ? JSON.parse(v) : null;
  } catch (_) { return null; }
}

// ── Scheduled handler (cron) ──────────────────────────────────────────────────
async function handleScheduled(event, env) {
  const cron = event.cron;
  try {
    const token = await getToken(env.IBM_QUANTUM_API_KEY);
    const backends = await getBackends(token, env);
    const best = backends[0]?.name || "ibm_kingston";

    // Always: update backend status in KV
    await kvWrite(env, "quantum_status", {
      ts: new Date().toISOString(),
      backends: backends.map(b => ({ name: b.name, queue: b.queue_length, clops: b.clops?.value })),
      recommended: best,
    });

    // Hourly: submit new ISA attestation job
    const coinId = `BRMSTE-CRON-${Date.now()}`;
    const { data: job } = await submitAttestationJob(token, env, coinId, best);
    if (job.id) {
      await kvWrite(env, `quantum_job_${job.id}`, {
        job_id: job.id, backend: job.backend || best,
        submitted_at: new Date().toISOString(), circuit: "ISA-Bell-Heron-r2",
        coin_id: coinId, cron, status: "submitted",
      });
      // Update attestation registry
      const existing = await kvRead(env, "coin_attestation_registry") || { jobs: [] };
      existing.jobs = [{ id: job.id, backend: job.backend || best, ts: new Date().toISOString() }, ...existing.jobs].slice(0, 100);
      existing.last_updated = new Date().toISOString();
      await kvWrite(env, "coin_attestation_registry", existing);
    }

    // Daily (midnight): also sync all jobs
    if (cron === "0 0 * * *") {
      const jobsResp = await fetch(`${QUANTUM_BASE}/jobs?limit=200`, { headers: qHdrs(token, env) });
      const jobsData = await jobsResp.json();
      await kvWrite(env, "quantum_jobs", {
        ts: new Date().toISOString(),
        total: jobsData.count,
        jobs: (jobsData.jobs || []).map(j => ({
          id: j.id, status: j.status, backend: j.backend,
          created: j.created, qpu: j.usage?.qpu_charge_time_seconds,
        })),
      });
    }
  } catch (err) {
    await kvWrite(env, "cron_error", { ts: new Date().toISOString(), cron, error: err.message });
  }
}

// ── Main fetch handler ────────────────────────────────────────────────────────
export default {
  async scheduled(event, env, ctx) {
    ctx.waitUntil(handleScheduled(event, env));
  },

  async fetch(request, env, ctx) {
    const url  = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (method === "OPTIONS") {
      return new Response(null, { status: 204, headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
      }});
    }

    try {
      const apiKey = env.IBM_QUANTUM_API_KEY;

      // ── /health, / ─────────────────────────────────────────────────────
      if (path === "/" || path === "/health") {
        return jsonResp({
          status: "ok", service: "BRMSTE Quantum GI Worker",
          ts: new Date().toISOString(),
          patent: "BRMSTE-COIN-SB2026",
          ibm_quantum: { instance: "191cdf4f-de18-45a9-8fa5-9eb0c68183ba", region: "us-east" },
          cloudflare: { account: "7ea6547b1d6eb1cbd6d0ac5cf960ce2a", zones: 41, workers: 38 },
          bitcoin: { anchor: env.ANCHOR_ADDRESS, ln_node: env.LN_NODE, op_return_block: 946772 },
          cron: ["0 * * * * (hourly attest)", "0 0 * * * (daily sync)"],
          isa_fix: "error_1517_resolved — rz+sx+rz for H gate",
        }, 200, env);
      }

      // ── /status, /substrate/quantum/status.json ────────────────────────
      if (path === "/status" || path === "/substrate/quantum/status.json") {
        const token = await getToken(apiKey);
        const [backends, jobsR] = await Promise.all([
          getBackends(token, env),
          fetch(`${QUANTUM_BASE}/jobs?limit=10`, { headers: qHdrs(token, env) }),
        ]);
        const jobs = (await jobsR.json()).jobs || [];
        const cached = await kvRead(env, "coin_attestation_registry");
        return jsonResp({
          schema: "brmste-quantum-status/v1", ts: new Date().toISOString(),
          ibm_quantum: {
            instance: "191cdf4f-de18-45a9-8fa5-9eb0c68183ba", region: "us-east",
            recommended: backends[0]?.name,
            backends: backends.map(b => ({
              name: b.name, qubits: b.qubits, queue: b.queue_length,
              clops: b.clops?.value, status: b.status?.name,
            })),
            recent_jobs: jobs.slice(0, 5).map(j => ({ id: j.id, status: j.status, backend: j.backend, created: j.created })),
          },
          bitcoin: { anchor: env.ANCHOR_ADDRESS, ln_node: env.LN_NODE, op_return_block: 946772 },
          cloudflare: { account: "7ea6547b1d6eb1cbd6d0ac5cf960ce2a", zones: 41, workers: 38 },
          kv_attestations: cached ? cached.jobs?.length : 0,
          patent: "BRMSTE-COIN-SB2026 · BRMSTE-KERNEL-SB2026",
          isa_fix_applied: true,
        }, 200, env);
      }

      // ── /quantum, /quantum/backends ────────────────────────────────────
      if (path === "/quantum" || path === "/quantum/backends") {
        const token = await getToken(apiKey);
        const backends = await getBackends(token, env);
        return jsonResp({
          schema: "brmste-quantum-backends/v1", ts: new Date().toISOString(),
          count: backends.length, recommended: backends[0]?.name,
          isa_native_gates: ["cz","id","rz","sx","x"],
          isa_fix: "h → rz(π/2)·sx·rz(π/2)",
          backends: backends.map(b => ({
            name: b.name, qubits: b.qubits, queue_length: b.queue_length,
            clops: b.clops?.value, status: b.status?.name,
            processor: `${b.processor_type?.family} r${b.processor_type?.revision}`,
            two_q_error_median: b.performance_metrics?.two_q_error_median?.value,
          })),
        }, 200, env);
      }

      // ── /quantum/status ────────────────────────────────────────────────
      if (path === "/quantum/status") {
        const token = await getToken(apiKey);
        const backends = await getBackends(token, env);
        return jsonResp({
          connected: true, ts: new Date().toISOString(),
          recommended: backends[0]?.name,
          online: backends.filter(b => b.status?.name === "online").length,
          isa_fix_applied: true,
        }, 200, env);
      }

      // ── /quantum/jobs ──────────────────────────────────────────────────
      if (path === "/quantum/jobs") {
        const token = await getToken(apiKey);
        const limit = url.searchParams.get("limit") || "20";
        const r = await fetch(`${QUANTUM_BASE}/jobs?limit=${limit}`, { headers: qHdrs(token, env) });
        const d = await r.json();
        const completed = (d.jobs||[]).filter(j => j.status === "Completed").length;
        const queued = (d.jobs||[]).filter(j => j.status === "Queued").length;
        const failed = (d.jobs||[]).filter(j => j.status === "Failed").length;
        return jsonResp({
          schema: "brmste-quantum-jobs/v1", ts: new Date().toISOString(),
          total: d.count, completed, queued, failed,
          total_qpu_seconds: (d.jobs||[]).reduce((s,j) => s + (j.usage?.qpu_charge_time_seconds||0), 0),
          jobs: (d.jobs||[]).map(j => ({
            id: j.id, status: j.status, backend: j.backend,
            created: j.created, qpu: j.usage?.qpu_charge_time_seconds,
          })),
        }, 200, env);
      }

      // ── /quantum/jobs/:id ──────────────────────────────────────────────
      if (path.startsWith("/quantum/jobs/") && path.length > 14) {
        const jobId = path.split("/quantum/jobs/")[1];
        const token = await getToken(apiKey);
        const [jobR, metricsR] = await Promise.all([
          fetch(`${QUANTUM_BASE}/jobs/${jobId}`, { headers: qHdrs(token, env) }),
          fetch(`${QUANTUM_BASE}/jobs/${jobId}/metrics`, { headers: qHdrs(token, env) }),
        ]);
        const job = await jobR.json();
        const metrics = metricsR.status === 200 ? await metricsR.json() : null;
        return jsonResp({ job, metrics }, 200, env);
      }

      // ── POST /quantum/attest ───────────────────────────────────────────
      if (path === "/quantum/attest" && method === "POST") {
        const token = await getToken(apiKey);
        const body = await request.json().catch(() => ({}));
        const coin_id = body.coin_id || `BRMSTE-CF-${Date.now()}`;
        const backends = await getBackends(token, env);
        const best = body.backend || backends[0]?.name || "ibm_kingston";
        const { status, data: job } = await submitAttestationJob(token, env, coin_id, best);
        // Write to KV
        if (job.id && env.MINE_EVENTS) {
          await kvWrite(env, `quantum_job_${job.id}`, {
            job_id: job.id, backend: job.backend || best, coin_id,
            submitted_at: new Date().toISOString(), circuit: "ISA-Bell-Heron-r2",
          });
        }
        return jsonResp({
          coin_id, quantum_job_id: job.id, backend: job.backend || best,
          status: "submitted", circuit: "Bell-state ISA (Heron r2 native: cz,rz,sx,x)",
          isa_fix: "error_1517_resolved", shots: 4096,
          patent: "BRMSTE-COIN-SB2026", ts: new Date().toISOString(),
        }, status === 200 ? 200 : 202, env);
      }

      // ── /coin, /ibm/cos/coin ───────────────────────────────────────────
      if (path === "/coin" || path === "/ibm/cos/coin") {
        const token = await getToken(apiKey);
        const r = await fetch(`${env.COS_ENDPOINT}/${env.COS_BUCKET}/public/coin/brmste-coin.json`, { headers: cosHdrs(token, env) });
        const d = await r.json();
        return jsonResp(d, 200, env);
      }

      // ── /coin/inventory ────────────────────────────────────────────────
      if (path === "/coin/inventory") {
        const token = await getToken(apiKey);
        const r = await fetch(`${env.COS_ENDPOINT}/${env.COS_BUCKET}/public/coin/brmste-coin.json`, { headers: cosHdrs(token, env) });
        const d = await r.json();
        return jsonResp({
          schema: "brmste-coin-inventory/v1", ts: new Date().toISOString(),
          ticker: d.ticker, status: d.status, supply: d.supply,
          ibm_quantum: d.ibm_quantum, blockchain: d.blockchain,
          patent_family: d.patent_family,
          completed_jobs: (d.ibm_quantum_jobs||[]).filter(j=>j.status==="Completed").length,
          queued_jobs: (d.ibm_quantum_jobs||[]).filter(j=>j.status==="Queued").length,
        }, 200, env);
      }

      // ── /coin/verify ───────────────────────────────────────────────────
      if (path === "/coin/verify") {
        const token = await getToken(apiKey);
        const [coinR, jobsR] = await Promise.all([
          fetch(`${env.COS_ENDPOINT}/${env.COS_BUCKET}/public/coin/brmste-coin.json`, { headers: cosHdrs(token, env) }),
          fetch(`${QUANTUM_BASE}/jobs?limit=200`, { headers: qHdrs(token, env) }),
        ]);
        const coin = await coinR.json();
        const liveJobs = (await jobsR.json()).jobs || [];
        const liveIds = new Set(liveJobs.map(j => j.id));
        const coinJobs = coin.ibm_quantum_jobs || [];
        const verified = coinJobs.map(j => ({ ...j, verified: liveIds.has(j.id) }));
        return jsonResp({ coin_id: "brmste-coin-ibm", verified_jobs: verified, total_live_jobs: liveJobs.length }, 200, env);
      }

      // ── /ibm/cos/objects ───────────────────────────────────────────────
      if (path === "/ibm/cos/objects") {
        const token = await getToken(apiKey);
        const r = await fetch(`${env.COS_ENDPOINT}/${env.COS_BUCKET}`, { headers: cosHdrs(token, env) });
        const xml = await r.text();
        const keys = [...xml.matchAll(/<Key>([^<]+)<\/Key>/g)].map(m => m[1]);
        const sizes = [...xml.matchAll(/<Size>([^<]+)<\/Size>/g)].map(m => parseInt(m[1]));
        return jsonResp({
          bucket: env.COS_BUCKET, region: "eu-gb", count: keys.length,
          total_bytes: sizes.reduce((s,v) => s+v, 0),
          objects: keys.map((k,i) => ({ key: k, size: sizes[i]||0 })),
        }, 200, env);
      }

      // ── /watsonx/models ────────────────────────────────────────────────
      if (path === "/watsonx/models") {
        const token = await getToken(apiKey);
        const [euR, usR] = await Promise.all([
          fetch(`${WATSONX_EU_BASE}/ml/v1/foundation_model_specs?version=2023-09-30&limit=20`, { headers: ibmHdrs(token) }),
          fetch(`${WATSONX_US_BASE}/ml/v1/foundation_model_specs?version=2023-09-30&limit=20`, { headers: ibmHdrs(token) }),
        ]);
        const eu = euR.ok ? (await euR.json()).resources||[] : [];
        const us = usR.ok ? (await usR.json()).resources||[] : [];
        return jsonResp({
          ts: new Date().toISOString(),
          eu_gb: { instance: env.WATSONX_EU_GB, count: eu.length, models: eu.map(m => m.model_id) },
          us_south: { instance: env.WATSONX_US_SOUTH, count: us.length, models: us.map(m => m.model_id) },
        }, 200, env);
      }

      // ── 404 ───────────────────────────────────────────────────────────
      return jsonResp({
        error: "Not found",
        routes: [
          "GET  /health", "GET  /status", "GET  /substrate/quantum/status.json",
          "GET  /quantum", "GET  /quantum/status", "GET  /quantum/backends",
          "GET  /quantum/jobs[?limit=N]", "GET  /quantum/jobs/:id",
          "POST /quantum/attest",
          "GET  /coin", "GET  /coin/inventory", "GET  /coin/verify",
          "GET  /ibm/cos/coin", "GET  /ibm/cos/objects",
          "GET  /watsonx/models",
        ],
        patent: "BRMSTE-COIN-SB2026",
      }, 404, env);

    } catch (err) {
      return jsonResp({ error: err.message, ts: new Date().toISOString() }, 500, env);
    }
  },
};
