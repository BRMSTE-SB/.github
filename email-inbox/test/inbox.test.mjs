// BRMSTE email inbox — end-to-end logic tests (Node / vitest)
// Exercises the real parse -> store -> read path with an injected MemoryStorage,
// so no workerd runtime is required.

import { describe, it, expect, beforeEach } from "vitest";
import {
  handleEmailMessage,
  handleInboxRequest,
  parseEmail,
  recordFromParsed,
  __test__,
} from "../src/inbox.js";
import { MemoryStorage } from "../src/storage.js";

const SAMPLE = [
  "From: Alice Example <alice@example.com>",
  "To: sb@brmste.ai",
  "Subject: BRMSTE test — hello SB",
  "Message-ID: <test-0001@example.com>",
  "Date: Fri, 26 Jun 2026 11:00:00 +0000",
  "MIME-Version: 1.0",
  'Content-Type: multipart/alternative; boundary="b1"',
  "",
  "--b1",
  'Content-Type: text/plain; charset="utf-8"',
  "",
  "Hello SB, this is the plain-text body.",
  "--b1",
  'Content-Type: text/html; charset="utf-8"',
  "",
  "<p>Hello SB, this is the <b>HTML</b> body.</p>",
  "--b1--",
  "",
].join("\r\n");

function streamFrom(str) {
  const bytes = new TextEncoder().encode(str);
  return new ReadableStream({
    start(controller) {
      controller.enqueue(bytes);
      controller.close();
    },
  });
}

function fakeMessage(raw, { from = "alice@example.com", to = "sb@brmste.ai" } = {}) {
  const bytes = new TextEncoder().encode(raw);
  const forwarded = [];
  return {
    from,
    to,
    rawSize: bytes.length,
    raw: streamFrom(raw),
    forwarded,
    async forward(addr) {
      forwarded.push(addr);
    },
    setReject() {},
  };
}

const ENV = { INBOX_ADDRESSES: "sb@brmste.ai", INBOX_TOKEN: "test-token-123" };

describe("parseEmail / recordFromParsed", () => {
  it("parses a multipart message into a normalized record", async () => {
    const parsed = await parseEmail(SAMPLE);
    const rec = recordFromParsed(parsed, {
      mail_from: "alice@example.com",
      rcpt_to: "sb@brmste.ai",
      raw_size: SAMPLE.length,
      ts: 1750939200000,
    });
    expect(rec.id).toBe("test-0001@example.com");
    expect(rec.mail_from).toBe("alice@example.com");
    expect(rec.rcpt_to).toBe("sb@brmste.ai");
    expect(rec.subject).toContain("hello SB");
    expect(rec.text_body).toContain("plain-text body");
    expect(rec.html_body).toContain("<b>HTML</b>");
    expect(JSON.parse(rec.headers_json)["message-id"]).toBeDefined();
  });
});

describe("handleEmailMessage", () => {
  let storage;
  beforeEach(() => {
    storage = new MemoryStorage();
  });

  it("captures an allowed recipient into storage", async () => {
    const res = await handleEmailMessage(fakeMessage(SAMPLE), ENV, storage);
    expect(res.stored).toBe(true);
    expect(res.to).toBe("sb@brmste.ai");

    const list = await storage.listEmails({ address: "sb@brmste.ai" });
    expect(list).toHaveLength(1);
    expect(list[0].subject).toContain("hello SB");

    const full = await storage.getEmail(res.id);
    expect(full.text_body).toContain("plain-text body");
  });

  it("ignores recipients not on the allowlist", async () => {
    const msg = fakeMessage(SAMPLE.replace("To: sb@brmste.ai", "To: nobody@brmste.ai"), {
      to: "nobody@brmste.ai",
    });
    const res = await handleEmailMessage(msg, ENV, storage);
    expect(res.stored).toBe(false);
    expect(res.reason).toBe("recipient-not-allowed");
    expect(await storage.listEmails({})).toHaveLength(0);
  });

  it("forwards a copy when FORWARD_TO is set", async () => {
    const msg = fakeMessage(SAMPLE);
    await handleEmailMessage(msg, { ...ENV, FORWARD_TO: "ops@example.com" }, storage);
    expect(msg.forwarded).toContain("ops@example.com");
  });
});

describe("handleInboxRequest (HTTP reader)", () => {
  let storage;
  beforeEach(async () => {
    storage = new MemoryStorage();
    await handleEmailMessage(fakeMessage(SAMPLE), ENV, storage);
  });

  const req = (path, init) =>
    handleInboxRequest(new Request(`https://inbox.brmste.ai${path}`, init), ENV, storage);

  it("serves /health without a token", async () => {
    const res = await req("/health");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.service).toBe("brmste-email-inbox");
    expect(body.addresses).toContain("sb@brmste.ai");
  });

  it("rejects /inbox without a token (401)", async () => {
    const res = await req("/inbox");
    expect(res.status).toBe(401);
  });

  it("rejects /inbox with a wrong token (401)", async () => {
    const res = await req("/inbox", { headers: { Authorization: "Bearer nope" } });
    expect(res.status).toBe(401);
  });

  it("returns 503 when no token is configured", async () => {
    const res = await handleInboxRequest(
      new Request("https://inbox.brmste.ai/inbox"),
      { INBOX_ADDRESSES: "sb@brmste.ai" },
      storage,
    );
    expect(res.status).toBe(503);
  });

  it("lists messages with a valid Bearer token", async () => {
    const res = await req("/inbox", { headers: { Authorization: "Bearer test-token-123" } });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.count).toBe(1);
    expect(body.emails[0].rcpt_to).toBe("sb@brmste.ai");
  });

  it("accepts the token as a query param and filters by address", async () => {
    const res = await req("/inbox?token=test-token-123&address=sb@brmste.ai");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.address).toBe("sb@brmste.ai");
    expect(body.count).toBe(1);
  });

  it("fetches a single message body by id", async () => {
    const list = await storage.listEmails({});
    const id = list[0].id;
    const res = await req(`/inbox?id=${encodeURIComponent(id)}`, {
      headers: { Authorization: "Bearer test-token-123" },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.email.html_body).toContain("HTML");
  });

  it("404s an unknown id and unknown path", async () => {
    const a = await req("/inbox?id=does-not-exist", {
      headers: { Authorization: "Bearer test-token-123" },
    });
    expect(a.status).toBe(404);
    const b = await req("/nope");
    expect(b.status).toBe(404);
  });
});

describe("safeEqual", () => {
  it("is true only for identical strings", () => {
    expect(__test__.safeEqual("abc", "abc")).toBe(true);
    expect(__test__.safeEqual("abc", "abd")).toBe(false);
    expect(__test__.safeEqual("abc", "abcd")).toBe(false);
    expect(__test__.safeEqual("", "")).toBe(true);
  });
});
