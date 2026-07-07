# IBM Cloud · BRMSTE resource identity

**BRMSTE LTD · Companies House 15310393 · Human-open lane**

IBM Cloud account and resource inventory for BRMSTE. No secrets in this file — credentials live in Cursor MCP configuration, Cloud Agent secrets, or operator-managed CI secrets, never in chat or in the repo.

## Account

| Item | Value |
|------|-------|
| Account ID | `5dd2c9fe5e5b4718987c5ad1167fa19f` |
| Account type | TRIAL (single resource group only) |
| IAM identity | `IBMid-692001RNSY` |
| Console | [cloud.ibm.com](https://cloud.ibm.com) |

## Resource group

| Item | Value |
|------|-------|
| Name | `brmste` (renamed from `Default` — TRIAL accounts allow exactly one group) |
| ID | `dea9dbb8947f4d1a8858a12f91f63714` |
| CRN | `crn:v1:bluemix:public:resource-controller::a/5dd2c9fe5e5b4718987c5ad1167fa19f::resource-group:dea9dbb8947f4d1a8858a12f91f63714` |

## Service instances

| Name | Service | Region | GUID | State |
|------|---------|--------|------|-------|
| `BRMSTE` | IBM Cloud Projects (`project`) | `eu-gb` | `f9e25add-f83a-4e43-bf6e-07a9ee529e8e` | active |
| `open-instance` | Quantum Computing (`quantum-computing`) | `us-east` | `191cdf4f-de18-45a9-8fa5-9eb0c68183ba` | active |

## Credential policy

- **Never paste IBM Cloud API keys in chat.** Any key that appears in a conversation is compromised — revoke it at [IAM → API keys](https://cloud.ibm.com/iam/apikeys) and mint a fresh one.
- Agent access goes through Cursor MCP configuration or Cursor Dashboard **Cloud Agents → Secrets** (injected as env vars, redacted in transcripts).
- CI access goes through GitHub Actions repository secrets configured by the operator in repo settings.

## Useful API endpoints (agent reference)

```
POST https://iam.cloud.ibm.com/identity/token          # apikey → bearer token
GET  https://iam.cloud.ibm.com/v1/apikeys/details      # key → account_id (IAM-Apikey header)
GET  https://resource-controller.cloud.ibm.com/v2/resource_groups?account_id=<id>
GET  https://resource-controller.cloud.ibm.com/v2/resource_instances
```

## Related

- [MCP-AGENT-POLICY.md](MCP-AGENT-POLICY.md)
- [AGENTS.md](../AGENTS.md)
- [CARBON-JUSTICE.md](../CARBON-JUSTICE.md)
