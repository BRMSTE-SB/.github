#!/bin/bash
# BRMSTE coming-soon — deploy to IBM Cloud Object Storage static website
# BRMSTE LTD · Companies House 15310393 · GB2607860
#
# Usage: IBMCLOUD_API_KEY=... bash scripts/deploy-coming-soon-ibm-cos.sh
#
# The API key comes from the environment (Cloud Agents → Secrets, CI secret,
# or local shell) — never from chat and never committed. See docs/IBM-CLOUD.md.
set -euo pipefail

: "${IBMCLOUD_API_KEY:?Set IBMCLOUD_API_KEY in the environment (never paste keys in chat)}"

COS_GUID="${COS_GUID:-552e051f-21be-41d9-8a0e-b7c87f5e451a}"
COS_EP="${COS_EP:-https://s3.eu-gb.cloud-object-storage.appdomain.cloud}"
BUCKET="${BUCKET:-brmste-coming-soon}"
PAGE_TOKEN="brmste-coming-soon-v5"
SITE_DIR="$(cd "$(dirname "$0")/../coming-soon/site" && pwd)"

echo "==> IAM token"
TOKEN=$(curl -sS -X POST 'https://iam.cloud.ibm.com/identity/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

echo "==> Ensure bucket ${BUCKET}"
curl -sS -X PUT "$COS_EP/$BUCKET" \
  -H "Authorization: Bearer $TOKEN" \
  -H "ibm-service-instance-id: $COS_GUID" \
  -o /dev/null -w "bucket HTTP %{http_code}\n" || true

echo "==> Website configuration"
curl -sS -X PUT "$COS_EP/$BUCKET?website" -H "Authorization: Bearer $TOKEN" \
  --data-binary '<WebsiteConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><IndexDocument><Suffix>index.html</Suffix></IndexDocument><ErrorDocument><Key>index.html</Key></ErrorDocument></WebsiteConfiguration>' \
  -o /dev/null -w "website HTTP %{http_code}\n"

mime() {
  case "$1" in
    *.html) echo "text/html; charset=utf-8" ;;
    *.css)  echo "text/css; charset=utf-8" ;;
    *.js)   echo "application/javascript; charset=utf-8" ;;
    *.json) echo "application/json" ;;
    *.svg)  echo "image/svg+xml" ;;
    *.png)  echo "image/png" ;;
    *.jpg|*.jpeg) echo "image/jpeg" ;;
    *.webp) echo "image/webp" ;;
    *.txt|*.md) echo "text/plain; charset=utf-8" ;;
    *) echo "application/octet-stream" ;;
  esac
}

put() { # key, content-type, file
  local code
  code=$(curl -sS -X PUT "$COS_EP/$BUCKET/$1" -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: $2" --data-binary "@$3" -o /dev/null -w "%{http_code}")
  [ "$code" = "200" ] || { echo "FAIL $1 HTTP $code"; exit 1; }
}

echo "==> Upload site files"
cd "$SITE_DIR"
while IFS= read -r f; do
  put "${f#./}" "$(mime "$f")" "$f"
done < <(find . -type f)

echo "==> Clean-URL page copies (worker route parity)"
for page in brand open portfolio banking companies-house broadcast glass-mirrors carbon-justice; do
  put "$page" "text/html; charset=utf-8" "./$page.html"
done

echo "==> Health endpoint"
printf '{"ok":true,"page":"%s","platform":"ibm-cos-static-site","brand":"BRMSTE LTD 15310393"}' "$PAGE_TOKEN" > /tmp/brmste-health.json
put "health" "application/json" /tmp/brmste-health.json

SITE_URL="https://${BUCKET}.s3-web.${COS_EP#https://s3.}"
echo "==> Verify"
curl -sS "$SITE_URL/health"
echo
echo "Deployed: $SITE_URL"
