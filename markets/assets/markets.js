/*
 * BusinessScience.ai, Inc. — Markets surface controller
 * BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
 *
 * Responsibilities:
 *  - Render the listings table and headline (BRMS / NASDAQ) band from config.
 *  - Poll the authorized BizStrat(TM) feed and render LIVE quotes.
 *  - Compute the NASDAQ session state (pre-market / open / closed) in US/Eastern.
 *  - Degrade gracefully: never display fabricated prices. When the feed is
 *    unavailable, instruments show an explicit "Awaiting authorized feed" state.
 */
(function () {
  'use strict';

  var CFG = window.BSAI_MARKETS_CONFIG;
  if (!CFG) {
    console.error('BSAI markets: configuration missing.');
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
  function fmtPrice(value, currency) {
    if (value == null || isNaN(value)) return '—';
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
    if (abs == null || isNaN(abs)) return '—';
    var sign = abs > 0 ? '+' : '';
    var pctStr = pct == null || isNaN(pct) ? '' : ' (' + sign + pct.toFixed(2) + '%)';
    return sign + abs.toFixed(2) + pctStr;
  }
  function dirClass(abs) {
    if (abs == null || isNaN(abs) || abs === 0) return 'is-flat';
    return abs > 0 ? 'is-up' : 'is-down';
  }
  function keyFor(inst) {
    return inst.mic + ':' + inst.symbol;
  }

  /* ------------------------------------------------ NASDAQ session (US/East) */
  function nasdaqSession(now) {
    // Build an US/Eastern wall-clock from the current instant.
    var parts;
    try {
      parts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'America/New_York',
        weekday: 'short',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      }).formatToParts(now);
    } catch (e) {
      return { label: 'Session unavailable', state: 'unknown' };
    }
    var map = {};
    parts.forEach(function (p) {
      map[p.type] = p.value;
    });
    var weekday = map.weekday;
    var hour = parseInt(map.hour, 10);
    var minute = parseInt(map.minute, 10);
    var mins = hour * 60 + minute;
    var isWeekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].indexOf(weekday) !== -1;

    if (!isWeekday) return { label: 'NASDAQ closed · weekend', state: 'closed' };
    if (mins >= 570 && mins < 960) return { label: 'NASDAQ open', state: 'open' }; // 09:30–16:00
    if (mins >= 240 && mins < 570) return { label: 'NASDAQ pre-market', state: 'pre' }; // 04:00–09:30
    if (mins >= 960 && mins < 1200) return { label: 'NASDAQ after-hours', state: 'post' }; // 16:00–20:00
    return { label: 'NASDAQ closed', state: 'closed' };
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
      var mic = q.mic || q.exchange || '';
      if (!sym) return;
      var price = num(q.price != null ? q.price : q.last);
      var change = num(q.change != null ? q.change : q.chg);
      var pct = num(q.changePercent != null ? q.changePercent : q.changePct);
      out[(mic ? mic + ':' : '') + sym] = {
        symbol: sym,
        mic: mic,
        price: price,
        change: change,
        changePercent: pct,
        currency: q.currency || null,
        marketStatus: q.marketStatus || null,
        asOf: q.asOf || q.timestamp || null,
        source: q.source || CFG.feed.provider,
        history: Array.isArray(q.history) ? q.history.map(num) : null,
      };
    });
    return out;
  }
  function num(v) {
    if (v == null || v === '') return null;
    var n = Number(v);
    return isNaN(n) ? null : n;
  }

  /* --------------------------------------------------------------- sparkline */
  function sparkline(history, up) {
    var w = 132,
      h = 36,
      pad = 2;
    var svg = el('svg', {
      class: 'spark',
      viewBox: '0 0 ' + w + ' ' + h,
      width: w,
      height: h,
      'aria-hidden': 'true',
      preserveAspectRatio: 'none',
    });
    if (!history || history.length < 2) return svg;
    var min = Math.min.apply(null, history);
    var max = Math.max.apply(null, history);
    var span = max - min || 1;
    var step = (w - pad * 2) / (history.length - 1);
    var pts = history.map(function (v, i) {
      var x = pad + i * step;
      var y = pad + (h - pad * 2) * (1 - (v - min) / span);
      return x.toFixed(1) + ',' + y.toFixed(1);
    });
    var stroke = up ? 'var(--up)' : 'var(--down)';
    svg.appendChild(
      el('polyline', {
        points: pts.join(' '),
        fill: 'none',
        stroke: stroke,
        'stroke-width': '1.6',
        'stroke-linejoin': 'round',
        'stroke-linecap': 'round',
      })
    );
    return svg;
  }

  /* ----------------------------------------------------------------- render */
  var rowsByKey = {};

  function buildTable() {
    var tbody = $('#mkt-rows');
    if (!tbody) return;
    tbody.innerHTML = '';
    rowsByKey = {};
    CFG.instruments.forEach(function (inst) {
      var k = keyFor(inst);
      var tr = el('tr', { 'data-key': k }, [
        el('td', { class: 'col-region', text: inst.region }),
        el('td', { class: 'col-exch' }, [
          el('span', { class: 'exch-name', text: inst.exchange }),
          el('span', { class: 'exch-mic', text: inst.mic }),
        ]),
        el('td', { class: 'col-sym mono', text: inst.symbol }),
        el('td', { class: 'col-isin mono', text: inst.isin || '—' }),
        el('td', { class: 'col-price mono', text: '—' }),
        el('td', { class: 'col-change mono', text: '—' }),
        el('td', { class: 'col-status' }, [
          el('span', { class: 'pill pill-wait', text: 'Awaiting feed' }),
        ]),
        el('td', { class: 'col-source', text: '—' }),
      ]);
      rowsByKey[k] = tr;
      tbody.appendChild(tr);
    });
  }

  function applyQuotes(quotes) {
    CFG.instruments.forEach(function (inst) {
      var k = keyFor(inst);
      var tr = rowsByKey[k];
      if (!tr) return;
      var q = quotes[k] || quotes[inst.symbol] || null;
      var priceCell = $('.col-price', tr);
      var changeCell = $('.col-change', tr);
      var statusCell = $('.col-status', tr);
      var sourceCell = $('.col-source', tr);

      if (q && q.price != null) {
        priceCell.textContent = fmtPrice(q.price, q.currency || inst.currency);
        changeCell.textContent = fmtChange(q.change, q.changePercent);
        changeCell.className = 'col-change mono ' + dirClass(q.change);
        statusCell.innerHTML = '';
        statusCell.appendChild(el('span', { class: 'pill pill-live', text: 'LIVE' }));
        sourceCell.textContent = q.source || CFG.feed.provider;
      } else {
        priceCell.textContent = '—';
        changeCell.textContent = '—';
        changeCell.className = 'col-change mono is-flat';
        statusCell.innerHTML = '';
        statusCell.appendChild(el('span', { class: 'pill pill-wait', text: 'Awaiting feed' }));
        sourceCell.textContent = '—';
      }

      if (inst.primary) applyHero(inst, q);
    });
  }

  function applyHero(inst, q) {
    var priceEl = $('#hero-price');
    var changeEl = $('#hero-change');
    var isinEl = $('#hero-isin');
    var asOfEl = $('#hero-asof');
    var sparkWrap = $('#hero-spark');
    if (isinEl) isinEl.textContent = inst.isin || '—';

    if (q && q.price != null) {
      priceEl.textContent = fmtPrice(q.price, q.currency || inst.currency);
      priceEl.classList.remove('is-empty');
      changeEl.textContent = fmtChange(q.change, q.changePercent);
      changeEl.className = 'hero-change mono ' + dirClass(q.change);
      if (asOfEl) {
        asOfEl.textContent = q.asOf
          ? 'As of ' + new Date(q.asOf).toLocaleString('en-GB', { timeZoneName: 'short' })
          : 'As of ' + new Date().toLocaleTimeString('en-GB');
      }
      if (sparkWrap) {
        sparkWrap.innerHTML = '';
        sparkWrap.appendChild(sparkline(q.history, (q.change || 0) >= 0));
      }
    } else {
      priceEl.textContent = '—';
      priceEl.classList.add('is-empty');
      changeEl.textContent = 'Awaiting authorized feed';
      changeEl.className = 'hero-change mono is-wait';
      if (asOfEl) asOfEl.textContent = 'No authorized quote available';
      if (sparkWrap) sparkWrap.innerHTML = '';
    }
  }

  /* ------------------------------------------------------------ status bar */
  function setConnState(state, detail) {
    var dot = $('#feed-dot');
    var label = $('#feed-label');
    var updated = $('#feed-updated');
    if (dot) dot.className = 'dot dot-' + state;
    if (label) label.textContent = detail;
    if (updated && state === 'live') {
      updated.textContent = 'Updated ' + new Date().toLocaleTimeString('en-GB');
    }
  }

  function refreshSession() {
    var s = nasdaqSession(new Date());
    var sEl = $('#session-label');
    var sDot = $('#session-dot');
    if (sEl) sEl.textContent = s.label;
    if (sDot) sDot.className = 'dot session-' + s.state;
  }

  /* --------------------------------------------------------------- runtime */
  function tick() {
    var symbols = CFG.instruments.map(function (i) {
      return i.symbol;
    });
    var unique = symbols.filter(function (v, i) {
      return symbols.indexOf(v) === i;
    });
    setConnState('connecting', 'Connecting to ' + (CFG.feed.provider || 'feed') + '…');
    fetchQuotes(unique)
      .then(function (quotes) {
        var hasAny = Object.keys(quotes).length > 0;
        applyQuotes(quotes);
        if (hasAny) {
          setConnState('live', 'Live · ' + (CFG.feed.provider || 'feed'));
        } else {
          setConnState('wait', 'Feed reachable · no quotes returned');
        }
      })
      .catch(function (err) {
        applyQuotes({});
        var msg =
          err && err.message === 'feed-disabled'
            ? 'Feed integration pending'
            : 'Awaiting authorized feed';
        setConnState('wait', msg);
      });
  }

  function start() {
    buildTable();
    applyQuotes({}); // initial explicit "awaiting" state — no fabricated data
    refreshSession();
    tick();
    var period = Math.max(5, (CFG.feed && CFG.feed.refreshSeconds) || 15) * 1000;
    setInterval(tick, period);
    setInterval(refreshSession, 30000);

    var yr = $('#year');
    if (yr) yr.textContent = String(new Date().getFullYear());
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
