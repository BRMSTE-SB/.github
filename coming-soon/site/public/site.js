(function () {
  const path = window.location.pathname.replace(/\/$/, "") || "/";
  document.querySelectorAll(".brand-nav a[data-nav]").forEach((link) => {
    const href = link.getAttribute("href").replace(/\/$/, "") || "/";
    if (href === path) link.setAttribute("aria-current", "page");
  });
})();
