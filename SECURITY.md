# Security Policy · BRMSTE-SB Fort Knox · GSI

**BRMSTE LTD · Companies House 15310393**  
**GSI — Global Substrate Infrastructure™**

---

## Scope

All repositories under **BRMSTE-SB** and the **BRMSTE LTD** GitHub Enterprise ([brmste-ltd](https://github.com/enterprises/brmste-ltd)),
including all **GSI** edge surfaces and substrate infrastructure.

## Reporting

Report suspected vulnerabilities to **security@brmste.ai**. Do not open public issues for security findings.

---

## HTTPS / HSTS Policy (GSI Mandate)

All BRMSTE and GSI public surfaces enforce HTTPS with HTTP Strict Transport Security (HSTS).
This is non-negotiable for any GSI edge, API, or CDN endpoint.

### Required HSTS configuration

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

| Parameter | Required value |
|-----------|---------------|
| `max-age` | ≥ 31 536 000 (one year) |
| `includeSubDomains` | **required** |
| `preload` | **required** — submit all GSI origins to hstspreload.org |
| TLS minimum | TLS 1.2 · preferred TLS 1.3 |
| Ciphers | ECDHE · AES-GCM · CHACHA20 preferred · RC4/3DES forbidden |
| Certificate | DigiCert or ISRG (Let's Encrypt) · auto-renewed |
| OCSP stapling | Required on all GSI TLS origins |

### GSI HTTPS enforcement checklist

- [ ] All GSI edge origins respond to HTTP requests with `301 → HTTPS`
- [ ] HSTS header present on every HTTPS response (not just the landing page)
- [ ] HSTS `preload` flag set and domain submitted to Chrome/Firefox preload list
- [ ] No mixed-content (HTTP sub-resources) on any GSI page or API surface
- [ ] TLS certificates renewed ≥ 30 days before expiry
- [ ] CT (Certificate Transparency) logs monitored via alerts

### Forbidden

- Plaintext `http://` endpoints on any GSI or BRMSTE domain
- HSTS `max-age` below one year on any GSI surface
- Self-signed certificates in production
- TLS 1.0 or 1.1 — must be disabled at server config level
- RC4, DES, 3DES, export ciphers

---

## Repository lanes

| Lane | Visibility | Rule |
|------|------------|------|
| **Fort Knox** | Private (14 repos) | Production IP · least privilege · no secrets in git |
| **Human open** | Public (3 repos) | Catalog/starter only · GB2607860 patent notice · no keys |
| **GSI surfaces** | HTTPS-only edges | HSTS enforced · TLS 1.3 preferred · OCSP stapled |

Public human repos: `open-gits`, `brmste-human-future`, `mining-pools`.

---

## Standards

- No secrets in git — use GitHub Environments + org secrets
- Rotate credentials on any suspected exposure
- Production deploys require reviewed PR + passing checks
- `config/cf-workers.env`, wallet keys, and RPC credentials must never be committed
- Secret scanning + push protection enabled on all repos
- Dependabot security updates enabled where Enterprise permits
- All GSI API responses include `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`
- All GSI APIs require Bearer tokens — no cookie-based auth on substrate endpoints

---

## Access

- Least privilege — default org permission is **none**
- 2FA mandatory for all members
- Member repo creation disabled — admin provisioned only
- External collaborators require enterprise admin approval
- Deploy keys disabled org-wide

---

## GSI Incident Response

| Severity | Response SLA | Action |
|----------|-------------|--------|
| P0 — TLS/HSTS broken on live GSI surface | 1 hour | Page on-call · restore HTTPS immediately |
| P1 — Secret exposed in git | 2 hours | Revoke credential · rotate · notify affected parties |
| P2 — Dependency CVE (critical) | 24 hours | Emergency patch PR + deploy |
| P3 — Dependency CVE (high) | 7 days | Scheduled patch |

---

BRMSTE LTD · Companies House 15310393  
GSI™ — Global Substrate Infrastructure™ · GB2607860 · PCT/GB2026/050406
