(function () {
  const toggle = document.querySelector(".site-nav-toggle");
  const nav = document.querySelector(".site-nav");
  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      const open = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }

  const path = window.location.pathname.replace(/\/$/, "") || "/";
  document.querySelectorAll(".site-nav a[data-nav]").forEach((link) => {
    const href = link.getAttribute("href").replace(/\/$/, "") || "/";
    if (href === path) {
      link.setAttribute("aria-current", "page");
    }
  });
})();
