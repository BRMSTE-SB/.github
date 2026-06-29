-- BRMSTE email inbox — D1 schema
-- BRMSTE LTD · Companies House 15310393 · GB2607860
-- Applied to D1 database: brmste-email-inbox (5f18fadc-f347-430c-8f11-eccb116e9351)

CREATE TABLE IF NOT EXISTS emails (
  id           TEXT PRIMARY KEY, -- Message-ID (cleaned) or generated id
  ts           INTEGER NOT NULL, -- received time, epoch ms
  mail_from    TEXT,             -- envelope sender (lowercased)
  rcpt_to      TEXT,             -- envelope recipient (lowercased)
  subject      TEXT,
  text_body    TEXT,
  html_body    TEXT,
  raw_size     INTEGER,
  message_id   TEXT,
  headers_json TEXT              -- JSON object of parsed headers
);

CREATE INDEX IF NOT EXISTS idx_emails_rcpt_ts ON emails (rcpt_to, ts DESC);
CREATE INDEX IF NOT EXISTS idx_emails_ts ON emails (ts DESC);
