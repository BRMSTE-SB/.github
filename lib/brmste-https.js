/**
 * BRMSTE full HTTPS edge headers — shared across Cloudflare Workers.
 * BRMSTE LTD · Companies House 15310393 · GB2607860
 *
 * HSTS: 2-year max-age, includeSubDomains, preload (matches Cloudflare edge cert policy).
 * All BRMSTE surfaces MUST serve HTTPS only; HTTP redirects at zone level.
 */

export const HSTS_VALUE = "max-age=63072000; includeSubDomains; preload";

export const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "img-src 'self' https://brmste.com https://brmste.ai https://raw.githubusercontent.com https://img.shields.io data:",
  "style-src 'self' 'unsafe-inline'",
  "script-src 'self' 'unsafe-inline'",
  "connect-src 'self' https://brmste.com https://brmste.ai https://api.brmste.com https://*.codeengine.appdomain.cloud",
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

/** Apply security headers to a Response or header bag. */
export function withSecurityHeaders(headers = {}) {
  return { ...SECURITY_HEADERS, ...headers };
}
