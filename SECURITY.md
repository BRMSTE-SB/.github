# Security Policy · BRMSTE-SB Full Global

## Scope

All repositories under **BRMSTE-SB** and the **BRMSTE LTD** GitHub Enterprise ([brmste-ltd](https://github.com/enterprises/brmste-ltd)).

## Reporting

Report suspected vulnerabilities to **security@brmste.ai**. Do not open public issues for security findings.

## Repository lanes

| Lane | Visibility | Rule |
|------|------------|------|
| **Fort Knox** | Private | Production IP · least privilege · no secrets in git |
| **Human open** | Public | Catalog, starter, org governance · GB2607860 · no keys · AI, MCP, cloud, **all social media** **full free** — carbon justice only |

Public human and governance repos: `open-gits`, `brmste-human-future`, `mining-pools`, `.github`.

## Standards

- No secrets in git — use GitHub Environments + org secrets
- Rotate credentials on any suspected exposure
- Production deploys require reviewed PR + passing checks
- `config/cf-workers.env`, wallet keys, and RPC credentials must never be committed
- Secret scanning + push protection enabled on all repos
- Dependabot security updates enabled where Enterprise permits

## Access

- Least privilege — default org permission is **none**
- 2FA mandatory for all members
- Member repo creation disabled — admin provisioned only
- External collaborators require enterprise admin approval
- Deploy keys disabled org-wide

BRMSTE LTD · Companies House 15310393
