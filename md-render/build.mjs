// BRMSTE branded MD render — static site builder
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// Discovers every Markdown doc in the repo and renders a single branded,
// self-contained HTML page (dark BRMSTE shell + GitHub-style content) into
// dist/. Served from the Hetzner origin nodes behind Cloudflare (HSTS).

import { readdirSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { marked } from "marked";

const HERE = dirname(new URL(import.meta.url).pathname);
const ROOT = resolve(HERE, "..");
const OUT_DIR = join(HERE, "dist");

// Canonical BRMSTE collider mark (BRAND.md — canonical hosts only).
const LOGO = "https://brmste.com/brmste-favicon.svg";

const SKIP_DIRS = new Set([
  "node_modules",
  ".git",
  "dist",
  ".wrangler",
  "md-render",
]);

const slug = (s) =>
  s.replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-|-$/g, "").toLowerCase();

export function discoverDocs(root = ROOT) {
  const entries = readdirSync(root, { recursive: true, withFileTypes: true });
  const files = [];
  for (const e of entries) {
    if (!e.isFile() || !e.name.endsWith(".md")) continue;
    const rel = join(e.parentPath || e.path || root, e.name)
      .replace(root + "/", "")
      .replace(root, "");
    if (rel.split("/").some((seg) => SKIP_DIRS.has(seg))) continue;
    files.push(rel);
  }
  // README and org profile first, then the rest alphabetically.
  const priority = ["README.md", "profile/README.md", "AGENTS.md"];
  return files.sort((a, b) => {
    const pa = priority.indexOf(a);
    const pb = priority.indexOf(b);
    if (pa !== -1 || pb !== -1) {
      return (pa === -1 ? 99 : pa) - (pb === -1 ? 99 : pb);
    }
    return a.localeCompare(b);
  });
}

const CSS = `
:root{color-scheme:light}*{box-sizing:border-box}
body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;color:#1f2328;background:#f6f8fa}
.layout{display:flex;min-height:100vh}
aside{width:300px;flex:0 0 300px;background:#07101f;color:#cdd9e5;position:sticky;top:0;height:100vh;overflow:auto}
.brand{display:flex;align-items:center;gap:12px;padding:18px 20px;border-bottom:1px solid #16263f}
.brand img{width:36px;height:36px}
.brand b{color:#fff;font-size:15px;letter-spacing:.3px;display:block}
.brand small{color:#7d8ea3;font-size:11px}
aside nav a{display:block;padding:7px 20px;color:#9db3cc;text-decoration:none;font-size:13px;border-left:3px solid transparent}
aside nav a:hover{background:#0d1b30;color:#fff;border-left-color:#10b981}
main{flex:1;min-width:0;padding:32px 40px 120px;max-width:1000px}
.topbar{display:flex;align-items:center;gap:10px;margin:0 0 24px;color:#57606a;font-size:13px}
.topbar .dot{width:8px;height:8px;border-radius:50%;background:#10b981}
section{background:#fff;border:1px solid #d0d7de;border-radius:10px;padding:26px 34px;margin:0 0 26px;box-shadow:0 1px 2px rgba(0,0,0,.04);scroll-margin-top:16px}
.doc-path{font:600 12px ui-monospace,SFMono-Regular,Menlo,monospace;color:#07101f;background:#10b981;display:inline-block;padding:3px 10px;border-radius:6px;margin-bottom:16px}
.md h1,.md h2{border-bottom:1px solid #d8dee4;padding-bottom:.3em;margin-top:1.3em}
.md h1{font-size:1.85em}.md h2{font-size:1.35em}
.md table{border-collapse:collapse;width:100%;margin:1em 0;display:block;overflow:auto}
.md th,.md td{border:1px solid #d0d7de;padding:6px 13px;text-align:left}.md th{background:#f6f8fa}
.md code{background:#eff1f3;padding:.2em .4em;border-radius:6px;font-size:85%;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
.md pre{background:#0d1117;color:#e6edf3;padding:16px;border-radius:8px;overflow:auto}
.md pre code{background:transparent;padding:0;color:inherit}
.md img{max-width:100%}.md blockquote{border-left:4px solid #10b981;color:#57606a;margin:0;padding:0 1em}
.md a{color:#0969da}
footer{color:#57606a;font-size:12px;border-top:1px solid #d0d7de;padding-top:16px;margin-top:24px}
`;

export function renderSite(docs) {
  marked.setOptions({ gfm: true, breaks: false });
  let nav = "";
  let body = "";
  for (const { rel, md } of docs) {
    const id = slug(rel);
    nav += `<a href="#${id}">${rel}</a>`;
    body += `<section id="${id}"><div class="doc-path">${rel}</div><div class="md">${marked.parse(md)}</div></section>`;
  }
  return `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex">
<title>BRMSTE · Document Render</title>
<link rel="icon" href="${LOGO}">
<style>${CSS}</style></head>
<body><div class="layout">
<aside>
<div class="brand"><img src="${LOGO}" alt="BRMSTE GSI Carbon Collider"><span><b>BRMSTE · MD RENDER</b><small>GSI Governance · ${docs.length} docs</small></span></div>
<nav>${nav}</nav>
</aside>
<main>
<div class="topbar"><span class="dot"></span> Served from the Hetzner fleet · Cloudflare edge · HSTS enforced</div>
${body}
<footer>BRMSTE LTD · Companies House 15310393 · GB2607860 · Global Shravan Bansal Brand</footer>
</main></div></body></html>`;
}

export function main() {
  const docs = discoverDocs().map((rel) => ({
    rel,
    md: readFileSync(join(ROOT, rel), "utf8"),
  }));
  const html = renderSite(docs);
  mkdirSync(OUT_DIR, { recursive: true });
  writeFileSync(join(OUT_DIR, "index.html"), html);
  // Minimal home so unknown paths can redirect/fallback to the index.
  console.log(`Rendered ${docs.length} docs -> ${join(OUT_DIR, "index.html")}`);
  return docs.length;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
