// BRMSTE coming-soon Worker — tests (node:test, no external deps)
//
// Locks the edge behaviour served on all 38 zones: security headers, /health
// payload, banking live-only guard, path normalization, per-surface routing,
// and the carbonjustice.uk override.
import { describe, it } from "node:test";
import assert from "node:assert/strict";

import worker from "../src/index.js";

const HSTS = "max-age=63072000; includeSubDomains; preload";

// Mock ASSETS binding. `status` controls what the static asset fetch returns so
// we can exercise both the hit (200) and miss (404) branches. Accepts either a
// URL (pages/substrate) or a Request (/public).
function makeEnv({ assetStatus = 200, vars = {} } = {}) {
  return {
    ...vars,
    ASSETS: {
      async fetch(input) {
        const href = typeof input === "string" ? input : (input.url ?? String(input));
        const path = new URL(href).pathname;
        if (assetStatus !== 200) {
          return new Response("", { status: assetStatus });
        }
        return new Response(`asset:${path}`, {
          status: 200,
          headers: { "Content-Type": "application/octet-stream" },
        });
      },
    },
  };
}

function get(url, env = makeEnv()) {
  return worker.fetch(new Request(url, { method: "GET" }), env);
}

describe("security headers", () => {
  it("applies the BRMSTE HSTS + hardening headers on every response", async () => {
    const res = await get("https://brmste.com/health");
    assert.equal(res.headers.get("strict-transport-security"), HSTS);
    assert.equal(res.headers.get("x-content-type-options"), "nosniff");
    assert.equal(res.headers.get("x-frame-options"), "DENY");
    const csp = res.headers.get("content-security-policy");
    assert.match(csp, /default-src 'self'/);
    assert.match(csp, /frame-ancestors 'none'/);
    assert.match(csp, /upgrade-insecure-requests/);
  });

  it("hardens 404 responses too", async () => {
    const res = await get("https://brmste.com/does-not-exist");
    assert.equal(res.status, 404);
    assert.equal(res.headers.get("x-frame-options"), "DENY");
    assert.equal(res.headers.get("strict-transport-security"), HSTS);
  });
});

describe("/health", () => {
  it("reports ok with the configured page token and surfaces", async () => {
    const env = makeEnv({ vars: { BRMSTE_PAGE: "brmste-coming-soon-v5" } });
    const res = await get("https://brmste.com/health", env);
    assert.equal(res.status, 200);
    assert.match(res.headers.get("content-type"), /application\/json/);
    const body = await res.json();
    assert.equal(body.ok, true);
    assert.equal(body.page, "brmste-coming-soon-v5");
    assert.ok(Array.isArray(body.surfaces));
    assert.ok(body.surfaces.includes("home"));
    assert.ok(body.surfaces.includes("carbon-justice"));
    assert.equal(body.https.hsts, HSTS);
    assert.equal(body.banking.configured, false);
  });

  it("marks the carbon-justice domain on carbonjustice.uk", async () => {
    const body = await (await get("https://carbonjustice.uk/health")).json();
    assert.equal(body.domain, "carbonjustice.uk");
    assert.equal(body.surface, "carbon-justice");
  });

  it("omits the domain override on non carbon-justice hosts", async () => {
    const body = await (await get("https://brmste.com/health")).json();
    assert.equal(body.domain, undefined);
  });
});

describe("/api/banking/networth", () => {
  it("is live-only and returns 503 when eToro keys are absent", async () => {
    const res = await get("https://brmste.com/api/banking/networth");
    assert.equal(res.status, 503);
    assert.equal(res.headers.get("x-brmste-surface"), "banking-api");
    const body = await res.json();
    assert.equal(body.ok, false);
    assert.equal(body.liveOnly, true);
  });
});

describe("routing", () => {
  it("normalizes trailing slashes and serves the matching surface", async () => {
    const res = await get("https://brmste.com/brand/");
    assert.equal(res.status, 200);
    assert.equal(res.headers.get("x-brmste-surface"), "brand");
    assert.match(res.headers.get("content-type"), /text\/html/);
  });

  it("serves the carbon-justice page at / on carbonjustice.uk", async () => {
    const res = await get("https://carbonjustice.uk/");
    assert.equal(res.status, 200);
    assert.equal(res.headers.get("x-brmste-surface"), "carbon-justice");
  });

  it("serves substrate JSON with a cache header", async () => {
    const res = await get("https://brmste.com/substrate/starmind/mystery.json");
    assert.equal(res.status, 200);
    assert.equal(res.headers.get("x-brmste-surface"), "substrate");
    assert.match(res.headers.get("content-type"), /application\/json/);
    assert.match(res.headers.get("cache-control"), /max-age=300/);
  });

  it("returns 404 when the static asset for a known surface is missing", async () => {
    const env = makeEnv({ assetStatus: 404 });
    const res = await get("https://brmste.com/brand", env);
    assert.equal(res.status, 404);
  });

  it("returns 404 for unknown paths", async () => {
    const res = await get("https://brmste.com/not-a-real-surface");
    assert.equal(res.status, 404);
  });
});
