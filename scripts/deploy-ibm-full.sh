#!/usr/bin/env bash
# BRMSTE full IBM deploy: Code Engine BRM API + ICR image push.
# Operator-run only — IBM_API_KEY from keychain or env, never from repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRM_API_DIR="$ROOT/brmste-brm-api"

IBM_API_KEY="${IBM_API_KEY:-}"
IBM_ACCOUNT_ID="5dd2c9fe5e5b4718987c5ad1167fa19f"
IBM_QUANTUM_INSTANCE="191cdf4f-de18-45a9-8fa5-9eb0c68183ba"
IBM_SERVICE_CRN="crn:v1:bluemix:public:quantum-computing:us-east:a/${IBM_ACCOUNT_ID}:${IBM_QUANTUM_INSTANCE}::"

CE_REGION="${CE_REGION:-eu-gb}"
CE_PROJECT="${CE_PROJECT:-brmste-brm}"
CE_APP="${CE_APP:-brm-api}"
CE_CPU="0.5"
CE_MEMORY="1G"
CE_MIN_SCALE=1
CE_MAX_SCALE=3
CE_PORT=8080

ICR_REGION="${ICR_REGION:-uk.icr.io}"
ICR_NAMESPACE="${ICR_NAMESPACE:-brmste}"
IMAGE_NAME="${ICR_REGION}/${ICR_NAMESPACE}/brm-api"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

WATSONX_EU_GB_INSTANCE="be2ff8f4-12d2-4288-b9fe-c45edb83e5d8"
WATSONX_US_SOUTH_URL="https://us-south.ml.cloud.ibm.com"

echo "=== BRMSTE Full IBM Deploy ==="

if [[ -z "$IBM_API_KEY" ]]; then
  echo "IBM_API_KEY not set."
  echo "  1. Generate: https://cloud.ibm.com/iam/apikeys (name: brmste-quantum-operator)"
  echo "  2. export IBM_API_KEY=... && bash scripts/deploy-ibm-full.sh"
  exit 1
fi

command -v ibmcloud >/dev/null || {
  echo "Install IBM Cloud CLI: https://cloud.ibm.com/docs/cli"
  exit 1
}

ibmcloud login --apikey "$IBM_API_KEY" --no-region -q
ibmcloud target -r "$CE_REGION" -q

echo "=== Verify IAM token ==="
IAM_RESP=$(curl -s -X POST https://iam.cloud.ibm.com/identity/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBM_API_KEY")
IAM_TOKEN=$(echo "$IAM_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || echo "")
[[ -n "$IAM_TOKEN" ]] || { echo "IAM token failed"; exit 1; }
echo "IAM token OK"

echo "=== Build + push Docker image ==="
ibmcloud cr login --client docker
ibmcloud cr namespace-list | grep -q "$ICR_NAMESPACE" || \
  ibmcloud cr namespace-create "$ICR_NAMESPACE" --resource-group-name Default

cd "$BRM_API_DIR"
docker build -t "$IMAGE" .
docker push "$IMAGE"
docker tag "$IMAGE" "${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:latest"
cd "$ROOT"

echo "=== Code Engine project + app ==="
if ibmcloud ce project select --name "$CE_PROJECT" 2>/dev/null; then
  echo "Selected CE project: $CE_PROJECT"
else
  ibmcloud ce project create --name "$CE_PROJECT" --tag "brmste,brm-api"
  ibmcloud ce project select --name "$CE_PROJECT"
fi

CE_PROJECT_ID=$(ibmcloud ce project get --name "$CE_PROJECT" --output json 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")
CE_SUBDOMAIN="${CE_PROJECT_ID}.${CE_REGION}.codeengine.appdomain.cloud"

ibmcloud ce secret delete --name brm-api-secrets --force 2>/dev/null || true
ibmcloud ce secret create --name brm-api-secrets \
  --from-literal IBM_QUANTUM_API_KEY="$IBM_API_KEY" \
  --from-literal IBM_SERVICE_CRN="$IBM_SERVICE_CRN" \
  --from-literal IBM_COS_INSTANCE_ID="$WATSONX_EU_GB_INSTANCE" \
  --from-literal QUANTUM_INSTANCE="$IBM_QUANTUM_INSTANCE" \
  --from-literal WATSONX_US="$WATSONX_US_SOUTH_URL" \
  --from-literal CE_PROJECT_ID="$CE_PROJECT_ID" \
  --from-literal CE_SUBDOMAIN="$CE_SUBDOMAIN" \
  --from-literal CE_APP="$CE_APP" \
  --from-literal CE_REGION="$CE_REGION" \
  --from-literal CE_DOMAIN="${CE_APP}.${CE_SUBDOMAIN}" \
  --from-literal CE_API_BASE_URL="https://${CE_APP}.${CE_SUBDOMAIN}" \
  --from-literal XAI_API_KEY="${XAI_API_KEY:-}" \
  --from-literal GROK_API_KEY="${GROK_API_KEY:-${XAI_API_KEY:-}}" \
  --from-literal COINMARKETCAP_API_KEY="${COINMARKETCAP_API_KEY:-}" \
  --from-literal MEMPOOL_ENTERPRISE_API_KEY="${MEMPOOL_ENTERPRISE_API_KEY:-}" \
  --from-literal ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-}" \
  --from-literal BRMSTE_SERVICE="brmste-brm-api" \
  --from-literal PORT="8080"

if ibmcloud ce application get --name "$CE_APP" 2>/dev/null | grep -q "Running\|Ready\|Deploying"; then
  ibmcloud ce application update \
    --name "$CE_APP" \
    --image "$IMAGE" \
    --env-from-secret brm-api-secrets \
    --cpu "$CE_CPU" --memory "$CE_MEMORY" \
    --min-scale "$CE_MIN_SCALE" --max-scale "$CE_MAX_SCALE" \
    --port "$CE_PORT" --wait
else
  ibmcloud ce application create \
    --name "$CE_APP" \
    --image "$IMAGE" \
    --env-from-secret brm-api-secrets \
    --cpu "$CE_CPU" --memory "$CE_MEMORY" \
    --min-scale "$CE_MIN_SCALE" --max-scale "$CE_MAX_SCALE" \
    --port "$CE_PORT" \
    --registry-secret ibm-icr --wait
fi

CE_APP_URL=$(ibmcloud ce application get --name "$CE_APP" --output json 2>/dev/null | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status',{}).get('address',{}).get('url',''))" 2>/dev/null || echo "")

echo "BRM API URL: ${CE_APP_URL:-unknown}"

if [[ -n "$CE_APP_URL" && -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]]; then
  printf '%s' "$CE_APP_URL" | npx wrangler secret put BRM_API --name brmste-quantum-gi 2>/dev/null || true
  printf '%s' "$CE_APP_URL" | npx wrangler secret put BRM_API --name brmste-786x-voyager 2>/dev/null || true
fi

echo "=== Smoke tests ==="
for ENDPOINT in "/health" "/" "/api/quantum/status" "/api/brm"; do
  curl -s -o /dev/null -w "  %{http_code}  ${CE_APP_URL}${ENDPOINT}\n" -m 15 "${CE_APP_URL}${ENDPOINT}" 2>/dev/null || true
done

echo "IBM deploy complete."
