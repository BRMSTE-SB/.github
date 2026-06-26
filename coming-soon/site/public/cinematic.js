(function () {
  if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  var canvas = document.getElementById("cinematic-canvas");
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

  var colors = ["rgba(0,135,90,", "rgba(16,185,129,", "rgba(201,169,78,"];
  for (var i = 0; i < 72; i++) {
    pts.push({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.35,
      vy: (Math.random() - 0.5) * 0.35,
      r: Math.random() * 2 + 0.8,
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
      var al = 0.35 + Math.sin(a.p) * 0.22;
      ctx.beginPath();
      ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
      ctx.fillStyle = a.c + al + ")";
      ctx.fill();
      for (var j = i + 1; j < pts.length; j++) {
        var b = pts[j];
        var dx = a.x - b.x;
        var dy = a.y - b.y;
        var d = Math.sqrt(dx * dx + dy * dy);
        if (d < 110) {
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.strokeStyle = "rgba(16,185,129," + (1 - d / 110) * 0.12 + ")";
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
    requestAnimationFrame(draw);
  }

  draw();
})();
