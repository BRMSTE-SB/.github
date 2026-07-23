// BRMSTE email inbox — Cloudflare Email Worker entrypoint
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// email(): inbound mail to sb@brmste.ai (routed via Cloudflare Email Routing)
//          is parsed and stored in D1 (binding DB).
// fetch(): GET /health (open) and GET /inbox (Bearer INBOX_TOKEN) read it back.

import { handleEmailMessage, handleInboxRequest } from "./inbox.js";
import { D1Storage } from "./storage.js";

export default {
  async email(message, env, _ctx) {
    const storage = new D1Storage(env.DB);
    try {
      await handleEmailMessage(message, env, storage);
    } catch (err) {
      // Never reject the mail because of a storage hiccup — log for observability.
      console.error(
        "brmste-email-inbox: failed to store message",
        err?.stack || String(err),
      );
    }
  },

  async fetch(request, env) {
    try {
      const storage = new D1Storage(env.DB);
      return await handleInboxRequest(request, env, storage);
    } catch (err) {
      console.error(
        "brmste-email-inbox: fetch error",
        err?.stack || String(err),
      );
      return new Response(
        JSON.stringify({ ok: false, error: "internal-error" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json; charset=utf-8" },
        },
      );
    }
  },
};
