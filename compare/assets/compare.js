/*
 * BRMSTE-SB — Peer comparison surface controller ("IBM vs BRMSTE vs META")
 * BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
 *
 * Responsibilities:
 *  - Render the hero, live quote band, comparison matrix, IP posture cards,
 *    sources and footer entirely from BRMSTE_COMPARE_CONFIG.
 *  - Poll the authorized BizStrat(TM) feed and render LIVE quotes only.
 *  - Degrade gracefully: NEVER display fabricated prices. When the feed is
 *    unavailable, each instrument shows an explicit "Awaiting authorized feed".
 */
(function () {
  'use strict';

  var CFG = window.BRMSTE_COMPARE_CONFIG;
  if (!CFG) {
    console.error('BRMSTE compare: configuration missing.');
    return;
  }

  /* ------------------------------------------------------------------ utils */
  function $(sel, root) {
    return (root || document).querySelector(sel);
  }
  function el(tag, attrs, children) {
    var node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        if (k === 'class') node.className = attrs[k];
        else if (k === 'text') node.textContent = attrs[k];
        else if (k === 'html') node.innerHTML = attrs[k];
        else node.setAttribute(k, attrs[k]);
      });
    }
    (children || []).forEach(function (c) {
      if (c == null) return;
      node.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
    });
    return node;
  }
  function svgTile(monogram, accent) {
    // Inline SVG monogram tile — no third-party trademarked logos are hotlinked,
    // keeping the surface within the BRMSTE brand/patent gate.
    var ns = 'http://www.w3.org/2000/svg';
    var svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('class', 'tile');
    svg.setAttribute('viewBox', '0 0 48 48');
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', monogram);
    var rect = document.createElementNS(ns, 'rect');
    rect.setAttribute('x', '1');
    rect.setAttribute('y', '1');
    rect.setAttribute('width', '46');
    rect.setAttribute('height', '46');
    rect.setAttribute('rx', '11');
    rect.setAttribute('fill', '#07101f');
    var border = document.createElementNS(ns, 'rect');
    border.setAttribute('x', '3.5');
    border.setAttribute('y', '3.5');
    border.setAttribute('width', '41');
    border.setAttribute('height', '41');
    border.setAttribute('rx', '9');
    border.setAttribute('fill', 'none');
    border.setAttribute('stroke', accent || '#d4af37');
    border.setAttribute('stroke-width', '1.4');
    var txt = document.createElementNS(ns, 'text');
    txt.setAttribute('x', '24');
    txt.setAttribute('y', '24');
    txt.setAttribute('text-anchor', 'middle');
    txt.setAttribute('dominant-baseline', 'central');
    txt.setAttribute('font-family', 'SFMono-Regular, Menlo, Consolas, monospace');
    txt.setAttribute('font-size', monogram.length > 3 ? '11' : '13');
    txt.setAttribute('font-weight', '700');
    txt.setAttribute('letter-spacing', '0.5');
    txt.setAttribute('fill', accent || '#d4af37');
    txt.textContent = monogram;
    svg.appendChild(rect);
    svg.appendChild(border);
    svg.appendChild(txt);
    return svg;
  }
  function fmtPrice(value, currency) {
    if (value == null || isNaN(value)) return null;
    try {
      return new Intl.NumberFormat('en-GB', {
        style: 'currency',
        currency: currency || 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(value);
    } catch (e) {
      return Number(value).toFixed(2);
    }
  }
  function fmtChange(abs, pct) {
    if (abs == null || isNaN(abs)) return null;
    var sign = abs > 0 ? '+' : '';
    var pctStr = pct == null || isNaN(pct) ? '' : ' (' + sign + pct.toFixed(2) + '%)';
    return sign + abs.toFixed(2) + pctStr;
  }
  function dirClass(abs) {
    if (abs == null || isNaN(abs) || abs === 0) return 'is-flat';
    return abs > 0 ? 'is-up' : 'is-down';
  }
  function keyFor(q) {
    return q.mic + ':' + q.symbol;
  }

  /* ----------------------------------------------------------- feed fetching */
  function fetchQuotes(symbols) {
    if (!CFG.feed || !CFG.feed.enabled) {
      return Promise.reject(new Error('feed-disabled'));
    }
    var url = CFG.feed.endpoint.replace('{symbols}', encodeURIComponent(symbols.join(',')));
    var controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = controller
      ? setTimeout(function () {
          controller.abort();
        }, CFG.feed.requestTimeoutMs || 8000)
      : null;

    return fetch(url, {
      headers: { Accept: 'application/json' },
      credentials: CFG.feed.withCredentials ? 'include' : 'same-origin',
      signal: controller ? controller.signal : undefined,
    })
      .then(function (res) {
        if (timer) clearTimeout(timer);
        if (!res.ok) throw new Error('feed-http-' + res.status);
        return res.json();
      })
      .then(normalizeQuotes);
  }

  /*
   * Map an arbitrary provider envelope into a { "MIC:SYMBOL": quote } dictionary.
   * Adjust the field accessors here to match your licensed provider.
   */
  function normalizeQuotes(payload) {
    var list = Array.isArray(payload)
      ? payload
      : payload && Array.isArray(payload.quotes)
      ? payload.quotes
      : payload && Array.isArray(payload.data)
      ? payload.data
      : [];
    var out = {};
    list.forEach(function (q) {
      var sym = q.symbol || q.ticker;
      var mic = q.mic || q.exchangeMic || q.micCode;
      if (!sym || !mic) return;
      out[mic + ':' + sym] = {
        price: num(q.price != null ? q.price : q.last),
        change: num(q.change != null ? q.change : q.chg),
        changePercent: num(q.changePercent != null ? q.changePercent : q.changePct),
        currency: q.currency || q.ccy,
        asOf: q.asOf || q.timestamp || q.time,
        source: q.source || CFG.feed.provider,
      };
    });
    return out;
  }
  function num(v) {
    if (v == null || v === '') return null;
    var n = typeof v === 'number' ? v : parseFloat(String(v).replace(/[, ]/g, ''));
    return isNaN(n) ? null : n;
  }

  /* --------------------------------------------------------------- feed dot */
  function setFeed(state, label, updated) {
    var dot = $('#feed-dot');
    var lab = $('#feed-label');
    var upd = $('#feed-updated');
    if (dot) dot.className = 'dot dot-' + state;
    if (lab) lab.textContent = label;
    if (upd) upd.textContent = updated || '';
  }

  /* --------------------------------------------------------------- renderers */
  function renderHero() {
    if (CFG.surface) {
      if (CFG.surface.eyebrow) $('#hero-eyebrow').textContent = CFG.surface.eyebrow;
      if (CFG.surface.lede) $('#hero-lede').textContent = CFG.surface.lede;
    }
  }

  function renderQuoteCards() {
    var grid = $('#quote-grid');
    grid.innerHTML = '';
    CFG.issuers.forEach(function (iss) {
      var q = iss.quote;
      var card = el('article', {
        class: 'quote-card' + (iss.subject ? ' is-subject' : ''),
        style: '--accent:' + (iss.accent || '#d4af37'),
        'data-key': keyFor(q),
        'aria-label': iss.shortName + ' quote',
      });

      var idBlock = el('div', { class: 'quote-card__id' }, [
        el('p', { class: 'quote-card__sym mono', text: q.exchange + ': ' + q.symbol }),
        el('p', { class: 'quote-card__name', text: iss.name }),
      ]);
      var top = el('div', { class: 'quote-card__top' }, [
        svgTile(iss.monogram, iss.accent),
        idBlock,
        iss.subject ? el('span', { class: 'subject-flag', text: 'Subject' }) : null,
      ]);

      var priceWrap = el('div', { class: 'quote-card__price' }, [
        el('span', { class: 'q-price mono is-empty', 'data-role': 'price', text: '\u2014' }),
        el('span', {
          class: 'q-change mono is-wait',
          'data-role': 'change',
          text: 'Awaiting authorized feed',
        }),
      ]);

      var meta = el('div', { class: 'q-meta' }, [
        el('span', { text: iss.facts && iss.facts.type ? iss.facts.type : q.currency }),
        el('span', { 'data-role': 'asof', text: q.currency }),
      ]);

      card.appendChild(top);
      card.appendChild(priceWrap);
      card.appendChild(meta);
      grid.appendChild(card);
    });
  }

  function applyQuotes(quotes) {
    CFG.issuers.forEach(function (iss) {
      var card = $('.quote-card[data-key="' + keyFor(iss.quote) + '"]');
      if (!card) return;
      var priceEl = $('[data-role="price"]', card);
      var changeEl = $('[data-role="change"]', card);
      var asofEl = $('[data-role="asof"]', card);
      var q = quotes && quotes[keyFor(iss.quote)];

      if (!q || q.price == null) {
        priceEl.textContent = '\u2014';
        priceEl.className = 'q-price mono is-empty';
        changeEl.textContent = 'Awaiting authorized feed';
        changeEl.className = 'q-change mono is-wait';
        asofEl.textContent = iss.quote.currency;
        return;
      }
      var ccy = q.currency || iss.quote.currency;
      priceEl.textContent = fmtPrice(q.price, ccy) || '\u2014';
      priceEl.className = 'q-price mono';
      var chg = fmtChange(q.change, q.changePercent);
      changeEl.textContent = chg || '\u2014';
      changeEl.className = 'q-change mono ' + dirClass(q.change);
      asofEl.textContent = q.asOf ? 'as of ' + new Date(q.asOf).toLocaleString('en-GB') : ccy;
    });
  }

  function renderMatrix() {
    var head = $('#matrix-head');
    var body = $('#matrix-body');
    head.innerHTML = '';
    body.innerHTML = '';

    head.appendChild(el('th', { scope: 'col', text: 'Dimension' }));
    CFG.issuers.forEach(function (iss) {
      var th = el('th', { scope: 'col', class: iss.subject ? 'is-subject' : '' }, [
        document.createTextNode(iss.shortName),
        el('span', { class: 'col-mono', text: iss.quote.exchange + ': ' + iss.quote.symbol }),
      ]);
      head.appendChild(th);
    });

    CFG.matrix.forEach(function (row) {
      var tr = el('tr', {}, [el('th', { scope: 'row', text: row.label })]);
      CFG.issuers.forEach(function (iss) {
        var val = (iss.facts && iss.facts[row.key]) || '\u2014';
        tr.appendChild(el('td', { class: iss.subject ? 'is-subject' : '', text: val }));
      });
      body.appendChild(tr);
    });
  }

  function renderPosture() {
    var wrap = $('#posture-cards');
    wrap.innerHTML = '';
    CFG.issuers.forEach(function (iss) {
      var card = el('article', { class: 'posture' + (iss.subject ? ' is-subject' : '') }, [
        el('p', { class: 'posture__sym', text: iss.quote.exchange + ': ' + iss.quote.symbol }),
        el('h3', { class: 'posture__name', text: iss.name }),
        el('p', { class: 'posture__ip', text: (iss.facts && iss.facts.ip) || '\u2014' }),
      ]);
      wrap.appendChild(card);
    });
  }

  function renderSources() {
    var list = $('#sources-list');
    list.innerHTML = '';
    (CFG.sources || []).forEach(function (s) {
      list.appendChild(
        el('li', {}, [el('b', { text: s.label }), el('span', { text: s.detail })])
      );
    });
  }

  function renderFooter() {
    var foot = $('#foot-id');
    var id = CFG.identity || {};
    foot.innerHTML = '';
    foot.appendChild(
      el('span', { class: 'foot__id', text: id.entity + ' · Companies House ' + id.companiesHouse })
    );
    foot.appendChild(el('span', { class: 'foot__patent', text: id.patent + ' · ' + id.pct }));
    if (id.beneficiary) foot.appendChild(el('span', { text: 'Beneficiary: ' + id.beneficiary }));
  }

  /* --------------------------------------------------------------- polling */
  function symbolsList() {
    return CFG.issuers.map(function (i) {
      return i.quote.symbol;
    });
  }

  function tick() {
    setFeed('connecting', 'Connecting…', '');
    fetchQuotes(symbolsList())
      .then(function (quotes) {
        applyQuotes(quotes);
        var any = Object.keys(quotes || {}).length > 0;
        if (any) {
          setFeed('live', CFG.feed.provider + ' · live', 'Updated ' + new Date().toLocaleTimeString('en-GB'));
        } else {
          setFeed('wait', 'Awaiting authorized feed', '');
        }
      })
      .catch(function () {
        applyQuotes(null);
        setFeed('wait', 'Awaiting authorized feed', '');
      });
  }

  /* ------------------------------------------------------------------ boot */
  function boot() {
    renderHero();
    renderQuoteCards();
    renderMatrix();
    renderPosture();
    renderSources();
    renderFooter();

    tick();
    var secs = (CFG.feed && CFG.feed.refreshSeconds) || 30;
    setInterval(tick, Math.max(5, secs) * 1000);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
