// BRMSTE email inbox — outbound (CloudMailin) tests
import { describe, it, expect, vi, afterEach } from "vitest";
import {
  buildSendRequest,
  normalizeMessage,
  sendViaCloudMailin,
  cloudmailinConfig,
  isConfigured,
} from "../src/send.js";
import { handleInboxRequest } from "../src/inbox.js";
import { MemoryStorage } from "../src/storage.js";

const CFG = { username: "503fce0b2fa7314d", apiKey: "secret-api-key" };

function mockFetch(status, jsonBody) {
  return vi.fn(async () => ({
    status,
    json: async () => jsonBody,
  }));
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("normalizeMessage", () => {
  it("coerces to into an array and maps text -> plain", () => {
    const m = normalizeMessage(
      { to: "x@example.com", text: "hi", subject: "s" },
      { from: "BRMSTE <sb@brmste.ai>" },
    );
    expect(m.to).toEqual(["x@example.com"]);
    expect(m.plain).toBe("hi");
    expect(m.from).toBe("BRMSTE <sb@brmste.ai>");
  });

  it("throws when to is missing", () => {
    expect(() => normalizeMessage({ subject: "s" })).toThrow("missing-to");
  });
});

describe("buildSendRequest", () => {
  it("targets the CloudMailin endpoint with Basic auth and JSON body", () => {
    const req = buildSendRequest(CFG, {
      to: "agent@sothebysrealty.com",
      from: "BRMSTE <sb@brmste.ai>",
      subject: "Hello",
      plain: "Body",
    });
    expect(req.url).toBe(
      "https://api.cloudmailin.com/api/v0.1/503fce0b2fa7314d/messages",
    );
    expect(req.method).toBe("POST");
    const decoded = atob(req.headers.Authorization.replace(/^Basic\s+/, ""));
    expect(decoded).toBe("503fce0b2fa7314d:secret-api-key");
    const body = JSON.parse(req.body);
    expect(body.to).toEqual(["agent@sothebysrealty.com"]);
    expect(body.subject).toBe("Hello");
    expect(body.plain).toBe("Body");
  });

  it("throws when credentials are absent", () => {
    expect(() => buildSendRequest({ username: "", apiKey: "" }, { to: "a@b.c" })).toThrow(
      "cloudmailin-not-configured",
    );
  });
});

describe("sendViaCloudMailin", () => {
  const env = {
    CLOUDMAILIN_USERNAME: CFG.username,
    CLOUDMAILIN_API_KEY: CFG.apiKey,
    CLOUDMAILIN_FROM: "BRMSTE <sb@brmste.ai>",
  };

  it("returns ok on 202 and posts the right request", async () => {
    const fetchImpl = mockFetch(202, { id: "msg-123" });
    const res = await sendViaCloudMailin(
      env,
      { to: "x@example.com", subject: "s", plain: "hi" },
      fetchImpl,
    );
    expect(res).toEqual({ ok: true, status: 202, id: "msg-123", message: { id: "msg-123" } });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toContain("/503fce0b2fa7314d/messages");
    expect(init.headers.Authorization).toMatch(/^Basic /);
    expect(JSON.parse(init.body).from).toBe("BRMSTE <sb@brmste.ai>");
  });

  it("maps 401 -> unauthorized and 422 -> validation-failed", async () => {
    const a = await sendViaCloudMailin(env, { to: "x@e.com", plain: "h" }, mockFetch(401, {}));
    expect(a).toMatchObject({ ok: false, status: 401, error: "unauthorized" });
    const b = await sendViaCloudMailin(env, { to: "x@e.com", plain: "h" }, mockFetch(422, { error: "bad" }));
    expect(b).toMatchObject({ ok: false, status: 422, error: "validation-failed" });
  });

  it("supports test_mode for safe validation sends", async () => {
    const fetchImpl = mockFetch(202, { id: "t1", test_mode: true });
    await sendViaCloudMailin(env, { to: "x@e.com", plain: "h", test_mode: true }, fetchImpl);
    expect(JSON.parse(fetchImpl.mock.calls[0][1].body).test_mode).toBe(true);
  });
});

describe("isConfigured / cloudmailinConfig", () => {
  it("reflects env presence", () => {
    expect(isConfigured({})).toBe(false);
    expect(isConfigured({ CLOUDMAILIN_USERNAME: "u", CLOUDMAILIN_API_KEY: "k" })).toBe(true);
    expect(cloudmailinConfig({}).from).toBe("BRMSTE <sb@brmste.ai>");
  });
});

describe("handleInboxRequest POST /send", () => {
  const storage = new MemoryStorage();
  const baseEnv = {
    INBOX_TOKEN: "tok",
    CLOUDMAILIN_USERNAME: CFG.username,
    CLOUDMAILIN_API_KEY: CFG.apiKey,
  };
  const send = (init, env = baseEnv) =>
    handleInboxRequest(
      new Request("https://brmste.ai/send", { method: "POST", ...init }),
      env,
      storage,
    );

  it("405 on GET", async () => {
    const res = await handleInboxRequest(
      new Request("https://brmste.ai/send"),
      baseEnv,
      storage,
    );
    expect(res.status).toBe(405);
  });

  it("503 without an inbox token", async () => {
    const res = await send({ headers: { "content-type": "application/json" }, body: "{}" }, {
      CLOUDMAILIN_USERNAME: "u",
      CLOUDMAILIN_API_KEY: "k",
    });
    expect(res.status).toBe(503);
  });

  it("401 with a wrong token", async () => {
    const res = await send({
      headers: { Authorization: "Bearer nope", "content-type": "application/json" },
      body: JSON.stringify({ to: "a@b.c", plain: "h" }),
    });
    expect(res.status).toBe(401);
  });

  it("503 when CloudMailin is not configured", async () => {
    const res = await send(
      {
        headers: { Authorization: "Bearer tok", "content-type": "application/json" },
        body: JSON.stringify({ to: "a@b.c", plain: "h" }),
      },
      { INBOX_TOKEN: "tok" },
    );
    expect(res.status).toBe(503);
    expect((await res.json()).error).toBe("cloudmailin-not-configured");
  });

  it("422 on missing fields", async () => {
    const res = await send({
      headers: { Authorization: "Bearer tok", "content-type": "application/json" },
      body: JSON.stringify({ subject: "no recipient" }),
    });
    expect(res.status).toBe(422);
  });

  it("202 on a valid authorized send", async () => {
    vi.stubGlobal("fetch", mockFetch(202, { id: "sent-1" }));
    const res = await send({
      headers: { Authorization: "Bearer tok", "content-type": "application/json" },
      body: JSON.stringify({ to: "agent@sothebysrealty.com", subject: "Hi", plain: "Hello" }),
    });
    expect(res.status).toBe(202);
    expect((await res.json())).toMatchObject({ ok: true, id: "sent-1" });
  });
});
