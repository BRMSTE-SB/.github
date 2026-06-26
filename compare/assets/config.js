/*
 * BRMSTE-SB — Peer comparison surface configuration
 * "IBM vs BRMSTE vs META"
 * BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
 *
 * This file is the single integration point for the comparison surface. It
 * carries (a) the three issuers being benchmarked, (b) their verifiable,
 * source-attributed static facts, and (c) the authorized market-data feed used
 * for the live quote band. Editing this file does NOT require touching the
 * rendering logic in compare.js.
 *
 * REGULATORY / INTEGRITY NOTE
 * --------------------------
 * This surface MUST NEVER display fabricated, simulated, or indicative prices,
 * market caps, or returns as if they were live. Live-market fields are blank
 * until the configured BizStrat(TM) feed returns an authorized quote; until
 * then each card shows an explicit "Awaiting authorized feed" state.
 *
 * Static facts (legal entity, listing, founded, HQ, sector, headcount, IP) are
 * dated and attributed in the `sources` block and in compare/README.md. They are
 * not live and are clearly labelled "as reported".
 */

window.BRMSTE_COMPARE_CONFIG = {
  /* Surface identity ------------------------------------------------------- */
  surface: {
    title: 'IBM vs BRMSTE vs META',
    eyebrow: 'Peer comparison · institutional reference',
    lede:
      'A like-for-like reference comparing BRMSTE against two listed technology ' +
      'incumbents — International Business Machines (NYSE: IBM) and Meta Platforms ' +
      '(NASDAQ: META). Live-market fields are delivered only through the authorized ' +
      'BizStrat\u2122 feed; where no authorized quote is available the surface states ' +
      'so explicitly and never shows indicative prices. Static facts are dated and ' +
      'attributed.',
  },

  /*
   * Authorized market-data feed.
   * `endpoint` receives a comma-separated list of symbols via {symbols}.
   * Expected JSON response shape (per instrument):
   *   { symbol, price, change, changePercent, currency, marketCap,
   *     asOf (ISO 8601), source, history: [number, ...] }
   * Wiring lives in compare.js -> normalizeQuotes(); adjust there if your
   * licensed provider returns a different envelope. Never embed feed secrets.
   */
  feed: {
    enabled: true,
    provider: 'BizStrat\u2122 API',
    endpoint: 'https://api.businessscience.ai/v1/quotes?symbols={symbols}',
    refreshSeconds: 30,
    requestTimeoutMs: 8000,
    withCredentials: false,
  },

  /*
   * Issuers under comparison. `subject: true` marks BRMSTE — the subject of the
   * comparison — which is rendered with emphasis. Each issuer carries a `quote`
   * descriptor (symbol/mic/exchange/currency) for the live band and a `facts`
   * map for the static comparison matrix.
   *
   * `accent`: card/column accent. `monogram`: short text rendered inside an
   * inline-SVG tile (no third-party trademarked logos are hotlinked — this keeps
   * the surface within the BRMSTE brand/patent gate and avoids trademark misuse).
   */
  issuers: [
    {
      key: 'ibm',
      monogram: 'IBM',
      accent: '#1f70c1',
      name: 'International Business Machines Corporation',
      shortName: 'IBM',
      quote: { symbol: 'IBM', exchange: 'NYSE', mic: 'XNYS', currency: 'USD' },
      facts: {
        listing: 'NYSE: IBM',
        founded: '1911',
        hq: 'Armonk, New York, USA',
        country: 'United States',
        sector: 'IT software & services · hybrid cloud · AI · consulting',
        employees: '264,300 full-time (31 Dec 2025)',
        segments: 'Software · Consulting · Infrastructure · Financing',
        products: 'watsonx · Red Hat · IBM Z mainframe · Quantum · Consulting',
        isin: 'US4592001014',
        ceo: 'Arvind Krishna',
        ip: 'Multi-decade leader in annual US patent grants ("Big Blue")',
        type: 'Public · large-cap incumbent',
      },
    },
    {
      key: 'brmste',
      subject: true,
      monogram: 'BRMS',
      accent: '#d4af37',
      name: 'BRMSTE LTD',
      shortName: 'BRMSTE',
      quote: { symbol: 'BRMS', exchange: 'NASDAQ', mic: 'XNAS', currency: 'USD' },
      facts: {
        listing: 'NASDAQ: BRMS (markets identity: BusinessScience.ai, Inc.)',
        founded: 'Companies House 15310393 (United Kingdom)',
        hq: 'United Kingdom',
        country: 'United Kingdom',
        sector: 'Traceable ELT infrastructure · circular economy · verifiable on-chain',
        employees: 'Early-stage \u00b7 not publicly disclosed',
        segments: 'BRMSTE Platform · Re-Tyre · Re-Tyre AI',
        products: 'BRMSTE substrate edge · Re-Tyre green steel · mining-pools · Carbon Drinking',
        isin: 'Awaiting allocation',
        ceo: 'Shravan Bansal (operator) \u00b7 Dimpy Bansal Trust (beneficiary)',
        ip: 'Granted patent GB2607860 (11 Oct 2023) \u00b7 PCT/GB2026/050406',
        type: 'Patent-backed \u00b7 institutional substrate · early-stage',
      },
    },
    {
      key: 'meta',
      monogram: 'META',
      accent: '#0866ff',
      name: 'Meta Platforms, Inc.',
      shortName: 'META',
      quote: { symbol: 'META', exchange: 'NASDAQ', mic: 'XNAS', currency: 'USD' },
      facts: {
        listing: 'NASDAQ: META (Class A)',
        founded: '2004 (IPO May 2012; renamed Meta Oct 2021)',
        hq: 'Menlo Park, California, USA',
        country: 'United States',
        sector: 'Social technology · advertising · AI · immersive computing',
        employees: '77,986 (31 Mar 2026)',
        segments: 'Family of Apps · Reality Labs',
        products: 'Facebook · Instagram · WhatsApp · Messenger · Threads · Meta AI · Quest',
        isin: 'US30303M1027',
        ceo: 'Mark Zuckerberg',
        ip: 'Large product, AI and Reality Labs portfolio',
        type: 'Public · large-cap incumbent',
      },
    },
  ],

  /*
   * Rows of the comparison matrix, in display order. `key` maps into each
   * issuer's `facts` map; `label` is the row heading. Keeping this declarative
   * means new dimensions can be added without editing compare.js.
   */
  matrix: [
    { key: 'listing', label: 'Listing' },
    { key: 'type', label: 'Profile' },
    { key: 'founded', label: 'Founded / registered' },
    { key: 'hq', label: 'Headquarters' },
    { key: 'sector', label: 'Sector & focus' },
    { key: 'segments', label: 'Operating segments' },
    { key: 'products', label: 'Flagship products' },
    { key: 'employees', label: 'Headcount (as reported)' },
    { key: 'ceo', label: 'Leadership' },
    { key: 'ip', label: 'Intellectual-property posture' },
    { key: 'isin', label: 'ISIN' },
  ],

  /*
   * Source attributions for the static facts. Rendered in the "Sources & basis"
   * section so every figure is traceable. (None of these are image URLs, so the
   * brand/patent gate's logo scan is unaffected.)
   */
  sources: [
    {
      label: 'IBM — incorporation, listing, headcount',
      detail: 'IBM Form 10-K (FY2025) and company profile; incorporated New York, 16 Jun 1911; NYSE: IBM; 264,300 full-time employees as of 31 Dec 2025.',
    },
    {
      label: 'Meta — incorporation, listing, headcount',
      detail: 'Meta Platforms Form 10-K (FY2025) and Q1 2026 results; incorporated Delaware Jul 2004; NASDAQ: META; 77,986 employees as of 31 Mar 2026.',
    },
    {
      label: 'BRMSTE — entity & intellectual property',
      detail: 'BRMSTE LTD, UK Companies House registration 15310393; granted patent GB2607860 (11 Oct 2023); international application PCT/GB2026/050406. Markets identity per the BRMSTE-SB markets surface (NASDAQ: BRMS / BusinessScience.ai, Inc.).',
    },
  ],

  /* Footer identity -------------------------------------------------------- */
  identity: {
    entity: 'BRMSTE LTD',
    companiesHouse: '15310393',
    patent: 'GB2607860',
    pct: 'PCT/GB2026/050406',
    beneficiary: 'Dimpy Bansal \u00b7 Dimpy Bansal Trust',
  },
};
