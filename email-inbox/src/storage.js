// BRMSTE email inbox — storage layer
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// Two interchangeable implementations of the same tiny interface:
//   putEmail(record)            -> id
//   listEmails({address, limit}) -> [summary]
//   getEmail(id)                -> full record | null
//
// D1Storage is used by the Worker; MemoryStorage is used by the tests so the
// core logic can be exercised end-to-end without the workerd runtime.

export const SUMMARY_COLUMNS =
  "id, ts, mail_from, rcpt_to, subject, raw_size, message_id";

export function clampLimit(limit, fallback = 50, max = 200) {
  const n = Number(limit);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.min(Math.floor(n), max);
}

export class D1Storage {
  constructor(db) {
    // Intentionally tolerant: /health must answer even if DB is unbound.
    this.db = db;
  }

  #db() {
    if (!this.db) {
      throw new Error("D1 binding env.DB is not configured for brmste-email-inbox");
    }
    return this.db;
  }

  async putEmail(rec) {
    await this.#db()
      .prepare(
        `INSERT OR REPLACE INTO emails
           (id, ts, mail_from, rcpt_to, subject, text_body, html_body, raw_size, message_id, headers_json)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .bind(
        rec.id,
        rec.ts,
        rec.mail_from ?? null,
        rec.rcpt_to ?? null,
        rec.subject ?? null,
        rec.text_body ?? null,
        rec.html_body ?? null,
        rec.raw_size ?? null,
        rec.message_id ?? null,
        rec.headers_json ?? null,
      )
      .run();
    return rec.id;
  }

  async listEmails({ address, limit } = {}) {
    const lim = clampLimit(limit);
    if (address) {
      const { results } = await this.#db()
        .prepare(
          `SELECT ${SUMMARY_COLUMNS} FROM emails WHERE rcpt_to = ? ORDER BY ts DESC LIMIT ?`,
        )
        .bind(address.toLowerCase(), lim)
        .all();
      return results ?? [];
    }
    const { results } = await this.#db()
      .prepare(`SELECT ${SUMMARY_COLUMNS} FROM emails ORDER BY ts DESC LIMIT ?`)
      .bind(lim)
      .all();
    return results ?? [];
  }

  async getEmail(id) {
    return (
      (await this.#db()
        .prepare(`SELECT * FROM emails WHERE id = ?`)
        .bind(id)
        .first()) ?? null
    );
  }
}

export class MemoryStorage {
  constructor() {
    this.rows = [];
  }

  async putEmail(rec) {
    this.rows = this.rows.filter((r) => r.id !== rec.id);
    this.rows.push({ ...rec });
    return rec.id;
  }

  async listEmails({ address, limit } = {}) {
    const lim = clampLimit(limit);
    let rows = [...this.rows];
    if (address) {
      const addr = address.toLowerCase();
      rows = rows.filter((r) => r.rcpt_to === addr);
    }
    rows.sort((a, b) => b.ts - a.ts);
    return rows.slice(0, lim).map((r) => ({
      id: r.id,
      ts: r.ts,
      mail_from: r.mail_from,
      rcpt_to: r.rcpt_to,
      subject: r.subject,
      raw_size: r.raw_size,
      message_id: r.message_id,
    }));
  }

  async getEmail(id) {
    return this.rows.find((r) => r.id === id) ?? null;
  }
}
