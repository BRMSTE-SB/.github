(function () {
  if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  var canvas = document.getElementById("onchain-canvas");
  if (!canvas) return;
  var ctx = canvas.getContext("2d");
  var w = 0;
  var h = 0;
  var pts = [];

  function resize() {
    w = canvas.width = window.innerWidth;
    h = canvas.height = window.innerHeight;
  }

  resize();
  window.addEventListener("resize", resize, { passive: true });

  var colors = ["rgba(247,147,26,", "rgba(255,179,71,", "rgba(201,169,78,"];
  for (var i = 0; i < 80; i++) {
    pts.push({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4,
      r: Math.random() * 2.2 + 0.6,
      c: colors[Math.floor(Math.random() * colors.length)],
      p: Math.random() * Math.PI * 2,
      ps: Math.random() * 0.02 + 0.004,
    });
  }

  function draw() {
    ctx.clearRect(0, 0, w, h);
    for (var i = 0; i < pts.length; i++) {
      var a = pts[i];
      a.x += a.vx;
      a.y += a.vy;
      a.p += a.ps;
      if (a.x < 0) a.x = w;
      if (a.x > w) a.x = 0;
      if (a.y < 0) a.y = h;
      if (a.y > h) a.y = 0;
      var al = 0.38 + Math.sin(a.p) * 0.24;
      ctx.beginPath();
      ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
      ctx.fillStyle = a.c + al + ")";
      ctx.fill();
      for (var j = i + 1; j < pts.length; j++) {
        var b = pts[j];
        var dx = a.x - b.x;
        var dy = a.y - b.y;
        var d = Math.sqrt(dx * dx + dy * dy);
        if (d < 120) {
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.strokeStyle = "rgba(247,147,26," + (1 - d / 120) * 0.14 + ")";
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }

  draw();
})();

(function () {
  var fill = document.getElementById("timeline-fill");
  var dayLabel = document.getElementById("timeline-day");
  if (!fill) return;

  fetch("/api/ip-valuation/status")
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var t = data.transfer_90_days;
      if (!t) return;

      var start = new Date(t.period_start + "T00:00:00Z");
      var end = new Date(t.period_end + "T23:59:59Z");
      var now = new Date();
      var total = end - start;
      var elapsed = Math.min(Math.max(now - start, 0), total);
      var pct = total > 0 ? (elapsed / total) * 100 : 100;
      var dayNum = Math.min(Math.ceil(elapsed / 86400000), t.days);

      fill.style.width = pct.toFixed(1) + "%";
      if (dayLabel) {
        dayLabel.textContent = "Day " + dayNum + " of " + t.days + " · " + t.from.name + " → " + t.to.name;
      }

      var amountEl = document.getElementById("valuation-amount");
      var metaEl = document.getElementById("valuation-meta");
      var v = data.valuation;
      if (amountEl && v) {
        amountEl.textContent = v.valuation_gbp_formatted || ("£" + v.valuation_gbp.toLocaleString("en-GB"));
      }
      if (metaEl && v && data.anchor) {
        metaEl.innerHTML =
          "<strong>1 SAT = 1 £</strong> · " +
          v.funded_satoshis.toLocaleString("en-GB") + " sats · " +
          v.tx_count.toLocaleString("en-GB") + " chain events · " +
          '<code>' + data.anchor.address + "</code>";
      }

      var workGrid = document.getElementById("work-grid");
      if (workGrid && data.work_against_ip) {
        workGrid.innerHTML = "";
        data.work_against_ip.forEach(function (item, idx) {
          var card = document.createElement("div");
          card.className = "onchain-card";
          card.style.animationDelay = (1.3 + idx * 0.08) + "s";
          var link = item.policy || item.manifest || item.surface || "#";
          card.innerHTML =
            "<h2>" + item.title + "</h2>" +
            "<p><a href=\"" + link + "\" rel=\"noopener\">View register →</a></p>";
          workGrid.appendChild(card);
        });
      }

      var licGrid = document.getElementById("licensor-grid");
      if (licGrid && data.fellow_licensors) {
        licGrid.innerHTML = "";
        data.fellow_licensors.forEach(function (lic, idx) {
          var card = document.createElement("div");
          card.className = "onchain-card";
          card.style.animationDelay = (1.8 + idx * 0.12) + "s";
          var infra = lic.infra
            ? "Hetzner " + lic.infra.hetzner_ip + " · " + lic.infra.project
            : lic.lane;
          card.innerHTML =
            "<h2>" + lic.name + "</h2>" +
            "<p>" + lic.lane + "</p>" +
            "<p style=\"margin-top:0.5rem;font-size:0.78rem\">" + infra + "</p>";
          licGrid.appendChild(card);
        });
      }
    })
    .catch(function () {
      if (dayLabel) dayLabel.textContent = "90 days · Shravan Bansal → Kohinoor Bansal";
      if (fill) fill.style.width = "100%";
    });
})();
