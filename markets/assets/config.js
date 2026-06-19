/*
 * BusinessScience.ai, Inc. — Markets surface configuration
 * BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
 *
 * This file is the single integration point between the public Markets page
 * and the authorized BizStrat(TM) market-data feed. Editing this file does NOT
 * require touching the rendering logic in markets.js.
 *
 * REGULATORY NOTE
 * ---------------
 * This surface MUST NEVER display fabricated, simulated, or indicative prices
 * as if they were live. When no authorized quote is available the page shows an
 * explicit "Awaiting authorized feed" state. Only data returned by the
 * configured BizStrat(TM) endpoint (or a licensed redistributor) may be shown.
 */

window.BSAI_MARKETS_CONFIG = {
  /* Issuer identity -------------------------------------------------------- */
  issuer: {
    legalName: 'BusinessScience.ai, Inc.',
    shortName: 'BusinessScience.ai',
    primarySymbol: 'BRMS',
    primaryExchange: 'NASDAQ',
    primaryMic: 'XNAS',
    primaryCurrency: 'USD',
    primaryIsin: '', // populate with the registered ISIN once allocated
    investorRelations: 'ir@businessscience.ai',
  },

  /*
   * Authorized market-data feed.
   * `endpoint` receives a comma-separated list of symbols via {symbols}.
   * Expected JSON response shape (per instrument):
   *   {
   *     symbol, price, change, changePercent, currency,
   *     marketStatus, asOf (ISO 8601), source, history: [number, ...]
   *   }
   * The exact wiring lives in markets.js -> normalizeQuotes(); adjust there if
   * your licensed provider returns a different envelope.
   */
  feed: {
    enabled: true,
    provider: 'BizStrat(TM) API',
    endpoint: 'https://api.businessscience.ai/v1/quotes?symbols={symbols}',
    refreshSeconds: 15,
    requestTimeoutMs: 8000,
    // Set true only behind an authenticated session/cookie; never embed secrets.
    withCredentials: false,
  },

  /*
   * Instruments shown in the "Listings & cross-exchange" table.
   * `primary: true` marks the headline listing rendered in the hero band.
   */
  instruments: [
    {
      primary: true,
      region: 'United States',
      exchange: 'NASDAQ',
      mic: 'XNAS',
      symbol: 'BRMS',
      isin: '',
      currency: 'USD',
      name: 'BusinessScience.ai, Inc. — Common Stock',
    },
    {
      region: 'United Kingdom',
      exchange: 'London Stock Exchange',
      mic: 'XLON',
      symbol: 'BRMS',
      isin: '',
      currency: 'GBP',
      name: 'BusinessScience.ai, Inc. — Depositary Receipt',
    },
    {
      region: 'European Union',
      exchange: 'Deutsche Börse Xetra',
      mic: 'XETR',
      symbol: 'BRMS',
      isin: '',
      currency: 'EUR',
      name: 'BusinessScience.ai, Inc. — Depositary Receipt',
    },
  ],

  /*
   * Commodity lanes — descriptive surfaces linked to BRMS investor programmes.
   * These are NOT exchange-listed securities and are clearly labelled as such.
   */
  commodityLanes: [
    {
      code: 'RE-TYRE GREEN',
      category: 'Green steel · circular economy',
      blurb:
        'Circular-economy commodity programme — Re-Tyre green steel and recovered carbon black, settled through audited BizStrat(TM) lots.',
    },
    {
      code: 'BRMSTE GOLD',
      category: 'Energy · carbon · digital assets',
      blurb:
        'Energy, carbon and digital-asset commodity lane operated on the BizStrat(TM) API under BRMSTE LTD governance.',
    },
    {
      code: 'MYTHOS CREME',
      category: 'Heritage commodity',
      blurb:
        'Premium heritage commodity lots — a limited surface listed for reference on the markets feed.',
    },
  ],

  /* Jurisdiction / registration headline ----------------------------------- */
  registrations: {
    jurisdictions: 158,
    framework: 'PCT member states · Audit House and Kingdoms registry',
  },
};
