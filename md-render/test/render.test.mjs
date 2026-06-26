// BRMSTE branded MD render — tests
import { describe, it, expect } from "vitest";
import { HSTS_VALUE, SECURITY_HEADERS, CONTENT_SECURITY_POLICY, contentType } from "../headers.mjs";
import { renderSite, discoverDocs } from "../build.mjs";
import { safeJoin } from "../serve.mjs";

describe("HSTS + security headers", () => {
  it("enforces the BRMSTE HSTS policy", () => {
    expect(HSTS_VALUE).toBe("max-age=63072000; includeSubDomains; preload");
    expect(SECURITY_HEADERS["Strict-Transport-Security"]).toBe(HSTS_VALUE);
    expect(SECURITY_HEADERS["X-Content-Type-Options"]).toBe("nosniff");
    expect(SECURITY_HEADERS["X-Frame-Options"]).toBe("DENY");
  });

  it("CSP allows only canonical image hosts and no scripts", () => {
    expect(CONTENT_SECURITY_POLICY).toContain("https://brmste.com");
    expect(CONTENT_SECURITY_POLICY).toContain("https://brmste.ai");
    expect(CONTENT_SECURITY_POLICY).toContain("raw.githubusercontent.com");
    expect(CONTENT_SECURITY_POLICY).toContain("script-src 'none'");
  });

  it("maps content types", () => {
    expect(contentType("/x/index.html")).toMatch(/text\/html/);
    expect(contentType("/logo.svg")).toBe("image/svg+xml");
    expect(contentType("/data.json")).toMatch(/application\/json/);
    expect(contentType("/unknown.bin")).toBe("application/octet-stream");
  });
});

describe("renderSite", () => {
  const html = renderSite([
    { rel: "README.md", md: "# Hello BRMSTE\n\nGovernance text." },
    { rel: "docs/X.md", md: "## Sub heading\n\n- item" },
  ]);

  it("is branded with the canonical collider logo and patent footer", () => {
    expect(html).toContain("https://brmste.com/brmste-favicon.svg");
    expect(html).toContain("BRMSTE · MD RENDER");
    expect(html).toContain("GB2607860");
    expect(html).toContain("HSTS enforced");
  });

  it("renders markdown and builds sidebar anchors", () => {
    expect(html).toContain("<h1>Hello BRMSTE</h1>");
    expect(html).toContain('id="readme-md"');
    expect(html).toContain('href="#docs-x-md"');
    expect(html).toContain("<h2>Sub heading</h2>");
  });

  it("uses only canonical image hosts in the shell", () => {
    const imgs = [...html.matchAll(/<img[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    for (const src of imgs) {
      expect(src.startsWith("https://brmste.com/")).toBe(true);
    }
  });
});

describe("discoverDocs", () => {
  const docs = discoverDocs();
  it("finds repo docs with README first", () => {
    expect(docs.length).toBeGreaterThan(5);
    expect(docs[0]).toBe("README.md");
  });
  it("excludes node_modules, dist and the md-render dir itself", () => {
    for (const d of docs) {
      expect(d.startsWith("node_modules/")).toBe(false);
      expect(d.startsWith("md-render/")).toBe(false);
      expect(d.includes("/dist/")).toBe(false);
    }
  });
});

describe("safeJoin path traversal guard", () => {
  it("keeps normal paths under the root", () => {
    expect(safeJoin("/srv/dist", "/index.html")).toBe("/srv/dist/index.html");
  });
  it("never escapes the root on traversal attempts", () => {
    const r = safeJoin("/srv/dist", "/../../etc/passwd");
    expect(r === null || r.startsWith("/srv/dist/")).toBe(true);
  });
});
