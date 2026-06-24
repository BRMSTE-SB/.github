import { SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";

// `SELF` dispatches requests to the Worker exactly as it runs when deployed to
// Cloudflare Workers (workerd), using the vars from wrangler.toml.
const ORIGIN = "https://edge.brmste.com";

describe("brmste-edge Worker (workerd runtime)", () => {
  it("GET /healthz → 200 ok with HSTS enforced", async () => {
    const res = await SELF.fetch(`${ORIGIN}/healthz`);
    expect(res.status).toBe(200);
    expect(res.headers.get("strict-transport-security")).toContain("max-age=31536000");
    const body = (await res.json()) as { status: string; entity: string; patent: string };
    expect(body.status).toBe("ok");
    expect(body.entity).toBe("BRMSTE LTD");
    expect(body.patent).toBe("GB2607860");
  });

  it("GET / → 200 HTML with canonical brand + patent footer", async () => {
    const res = await SELF.fetch(`${ORIGIN}/`);
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/html");
    const html = await res.text();
    expect(html).toContain("BRMSTE LTD");
    expect(html).toContain("GB2607860");
  });

  it("GET /substrate/edge.json → lists the edge surfaces", async () => {
    const res = await SELF.fetch(`${ORIGIN}/substrate/edge.json`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { runtime: string; surfaces: string[] };
    expect(body.runtime).toBe("cloudflare-workers");
    expect(body.surfaces).toContain("/healthz");
  });

  it("GET /substrate/patent-enforcement.json → cites GB2607860 + PCT", async () => {
    const res = await SELF.fetch(`${ORIGIN}/substrate/patent-enforcement.json`);
    expect(res.status).toBe(200);
    const text = await res.text();
    expect(text).toContain("GB2607860");
    expect(text).toContain("PCT/GB2026/050406");
  });

  it("unknown path → 404 (additive; never claims the domain root)", async () => {
    const res = await SELF.fetch(`${ORIGIN}/definitely-not-a-real-path`);
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe("not_found");
  });

  it("HTTP → HTTPS 301 redirect", async () => {
    const res = await SELF.fetch("http://edge.brmste.com/healthz", { redirect: "manual" });
    expect(res.status).toBe(301);
    expect(res.headers.get("location")).toBe("https://edge.brmste.com/healthz");
  });
});
