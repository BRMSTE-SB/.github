// BRMSTE branded MD render — shared edge/origin headers
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// HSTS matches the BRMSTE coming-soon worker so the policy is identical at the
// Cloudflare edge and on the Hetzner origin nodes.

export const HSTS_VALUE = "max-age=63072000; includeSubDomains; preload";

// CSP locks images to canonical BRMSTE hosts (+ shields badges) per BRAND.md;
// no scripts are served (the render is static HTML).
export const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "img-src 'self' https://brmste.com https://brmste.ai https://raw.githubusercontent.com https://img.shields.io data:",
  "style-src 'self' 'unsafe-inline'",
  "script-src 'none'",
  "base-uri 'none'",
  "frame-ancestors 'none'",
  "upgrade-insecure-requests",
].join("; ");

export const SECURITY_HEADERS = {
  "Strict-Transport-Security": HSTS_VALUE,
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "Content-Security-Policy": CONTENT_SECURITY_POLICY,
};

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".webp": "image/webp",
  ".ico": "image/x-icon",
  ".txt": "text/plain; charset=utf-8",
};

export function contentType(pathname) {
  const i = pathname.lastIndexOf(".");
  const ext = i === -1 ? "" : pathname.slice(i).toLowerCase();
  return TYPES[ext] || "application/octet-stream";
}
