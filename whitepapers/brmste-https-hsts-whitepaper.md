# BRMSTE GSI — HTTPS & HSTS Enforcement

## Transport Security Whitepaper · v1.0

---

**BRMSTE LTD · Companies House 15310393**  
**GSI™ — Global Substrate Infrastructure™**  
**Patent: GB2607860 · PCT/GB2026/050406**  
**Beneficiary: Dimpy (Shravan Krishan) Bansal · BRMSTE LTD**  
**Operator: Shravan Krishan Bansal · BRMSTE LTD**

*BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD (Companies House 15310393).*

---

## Abstract

This whitepaper documents the BRMSTE GSI™ transport security mandate — the requirement that
**all GSI and BRMSTE surfaces operate exclusively over HTTPS with HTTP Strict Transport Security
(HSTS) preloading enforced**. It covers the rationale, required configuration, implementation
guidance for Cloudflare Workers and standard web servers, git worker validation, and compliance
verification procedures.

---

## 1. Why HTTPS and HSTS are Non-Negotiable for GSI

### 1.1 Brand integrity

The BRMSTE™ and GSI™ trademarks are only validly displayed on secured surfaces. A BRMSTE or
GSI mark presented over a plaintext `http://` connection is a misuse of the trademark and
signals a potentially compromised or spoofed surface. Per `TRADEMARK.md`:

> Presentation of the BRMSTE™ or GSI™ mark over an insecure `http://` connection is a misuse
> of the trademark.

### 1.2 Patent trace integrity

GSI's patent (GB2607860) covers traceable ELT infrastructure. Traceability requires that:

- Data in transit cannot be modified by an on-path attacker (→ TLS encryption)
- The server identity is verified by a trusted CA (→ TLS certificate)
- Browsers and clients never downgrade to HTTP even on first connection (→ HSTS preload)

A substrate trace that transited an insecure hop cannot be considered verifiable under GB2607860.

### 1.3 Regulatory alignment

UK GDPR and the NIS Regulations 2018 require appropriate technical measures to protect data in
transit. HSTS preloading is the strongest available browser-enforced transport security control
and demonstrates due diligence.

### 1.4 Ecosystem trust

Mining pool participants, Re-Tyre operators, and human open-lane users interact with BRMSTE
surfaces on the expectation that connections are encrypted and authenticated. HSTS preloading
eliminates the TOFU (trust on first use) vulnerability window that exists even with HTTPS when
HSTS is not preloaded.

---

## 2. Required HSTS Configuration

### 2.1 HSTS response header

Every HTTPS response from a GSI or BRMSTE surface **must** include:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

| Directive | Value | Rationale |
|-----------|-------|-----------|
| `max-age` | 31 536 000 (one year) | Maximum commonly accepted value; signals long-term commitment |
| `includeSubDomains` | present | Prevents subdomain downgrade attacks |
| `preload` | present | Required for inclusion in browser preload lists |

The header **must** appear on every response — not just the index page or TLS negotiation
response. Middleware, API routes, and static asset responses must all include it.

### 2.2 HTTP → HTTPS redirect

All GSI origins must respond to any `http://` request with:

```
HTTP/1.1 301 Moved Permanently
Location: https://[host][path][query]
```

The redirect target must itself have HSTS active. Do not redirect to another `http://` URL.

### 2.3 TLS configuration

| Parameter | Requirement |
|-----------|-------------|
| Minimum TLS version | TLS 1.2 |
| Preferred TLS version | TLS 1.3 |
| Forbidden protocols | SSLv2, SSLv3, TLS 1.0, TLS 1.1 |
| Cipher suites (preferred order) | TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256, TLS_AES_128_GCM_SHA256 |
| Forbidden ciphers | RC4, DES, 3DES, export grades, NULL |
| Certificate authority | DigiCert or ISRG (Let's Encrypt) |
| OCSP stapling | Required |
| Certificate Transparency | Required (SCT embedded or via TLS extension) |
| Key type | ECDSA P-256 preferred; RSA-2048 minimum |
| Certificate renewal | Automated · alert ≥ 30 days before expiry |

### 2.4 Security headers required alongside HSTS

Every GSI response must also include:

```
Content-Security-Policy: default-src 'self' https://brmste.com https://brmste.ai; ...
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

CSP `script-src` must not include `'unsafe-inline'` or `'unsafe-eval'` on any GSI API or
authenticated surface.

---

## 3. Implementation — Cloudflare Workers

GSI edge nodes run on Cloudflare Workers. The following snippet enforces HTTPS/HSTS at the
worker layer:

```typescript
// GSI edge — HTTPS / HSTS enforcement (Cloudflare Workers)
// BRMSTE LTD · GB2607860

const HSTS = 'max-age=31536000; includeSubDomains; preload';

const SECURITY_HEADERS: Record<string, string> = {
  'Strict-Transport-Security': HSTS,
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
};

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // Redirect HTTP → HTTPS
    if (url.protocol === 'http:') {
      url.protocol = 'https:';
      return Response.redirect(url.toString(), 301);
    }

    const response = await fetch(request);
    const newResponse = new Response(response.body, response);

    for (const [key, value] of Object.entries(SECURITY_HEADERS)) {
      newResponse.headers.set(key, value);
    }

    return newResponse;
  },
};
```

---

## 4. Implementation — nginx

For GSI nodes running nginx behind Cloudflare or directly exposed:

```nginx
# GSI nginx — HTTPS / HSTS enforcement
# BRMSTE LTD · GB2607860

server {
    listen 80;
    server_name brmste.com www.brmste.com brmste.ai;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name brmste.com www.brmste.com brmste.ai;

    ssl_certificate     /etc/ssl/brmste/fullchain.pem;
    ssl_certificate_key /etc/ssl/brmste/privkey.pem;
    ssl_dhparam         /etc/ssl/brmste/dhparam4096.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers   TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;

    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 8.8.8.8 valid=300s;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # ... location blocks ...
}
```

---

## 5. HSTS Preload List Submission

To achieve full HSTS preloading (preventing downgrade attacks even on first visit before a
cached HSTS policy exists), all GSI primary domains must be submitted to the browser preload list:

1. Verify that the root domain and all subdomains serve the HSTS header with `max-age ≥ 31536000`,
   `includeSubDomains`, and `preload`.
2. Navigate to [https://hstspreload.org](https://hstspreload.org).
3. Enter the GSI domain (e.g. `brmste.com`, `brmste.ai`).
4. Confirm all checks pass.
5. Click **Submit**.
6. Monitor inclusion via the preload list check endpoint — propagation to Chrome and Firefox
   takes 6–12 weeks after acceptance.

**GSI domain preload submission checklist:**

| Domain | HSTS configured | Preload submitted | Preload confirmed |
|--------|----------------|-------------------|-------------------|
| `brmste.com` | ✅ Required | ⬜ Pending | ⬜ |
| `brmste.ai` | ✅ Required | ⬜ Pending | ⬜ |

---

## 6. Git Worker Validation

The `brmste-brand-patent-gate.sh` script validates HTTPS/HSTS compliance at the git layer:

- Scans all URLs in repository files for non-`https://` scheme references to BRMSTE or GSI
  brand assets
- Rejects any `http://` logo or asset URL
- Logs pass/fail to the GitHub Actions step summary

Developers may run the gate locally before pushing:

```bash
bash scripts/git-worker-brand-patent-gate.sh fort_knox_private
```

---

## 7. Compliance Verification

After any deployment to a GSI surface, verify HTTPS/HSTS compliance:

### Automated

```bash
# Check HSTS header on live surface
curl -sI https://brmste.com | grep -i strict-transport

# Expected output:
# strict-transport-security: max-age=31536000; includeSubDomains; preload
```

### Via external tools

- **SSL Labs** (Qualys): https://www.ssllabs.com/ssltest/ — target grade **A+**
- **Security Headers**: https://securityheaders.com/ — target grade **A**
- **HSTS Preload checker**: https://hstspreload.org/?domain=brmste.com

A GSI surface that achieves less than **A** on either SSL Labs or Security Headers must be
remediated before the deployment is considered compliant.

### Live status endpoint

BRMSTE publishes a live HSTS status manifest:

```
GET https://brmste.com/substrate/hsts-status.json
```

CI pipelines should poll this endpoint post-deploy to confirm HSTS is active.

---

## 8. Incident Response — TLS/HSTS Failure

If a GSI surface is found to be serving HTTP or missing HSTS:

| Step | Action | Owner |
|------|--------|-------|
| 1 | Declare P0 incident | On-call engineer |
| 2 | Immediately enable HTTPS redirect at CDN/load balancer | Infra |
| 3 | Restore HSTS header on all response paths | Infra |
| 4 | Verify fix via `curl` and SSL Labs | QA |
| 5 | Post incident report to `security@brmste.ai` | Security lead |
| 6 | Root-cause analysis and preventive control update | Engineering |

SLA: HTTPS/HSTS restored within **1 hour** of detection (P0).

---

## 9. Conclusion

HTTPS with HSTS preloading is a first-class requirement of the GSI™ brand and of the
BRMSTE LTD patent (GB2607860) traceability guarantee. No GSI surface may bear the BRMSTE™
or GSI™ trademark without enforcing:

1. TLS 1.2+ (TLS 1.3 preferred)
2. `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
3. HTTP → HTTPS redirect
4. Qualys SSL Labs grade A or above
5. Preload list submission for all primary GSI domains

---

## Trademark & Patent Notice

BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD
(Companies House 15310393). Patent GB2607860 · PCT/GB2026/050406.

**Beneficiary:** Dimpy (Shravan Krishan) Bansal · BRMSTE LTD  
**Operator:** Shravan Krishan Bansal · BRMSTE LTD

CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

Live patent enforcement: https://brmste.com/substrate/patent-enforcement.json  
Live HSTS status: https://brmste.com/substrate/hsts-status.json

© BRMSTE LTD · Companies House 15310393 · All rights reserved.
