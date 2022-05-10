#!/usr/bin/env bash


INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]*)".*/\1/g')

export PATH="${BIN_DIR}:${PATH}"

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

TMP_DIR=$(echo "${INPUT}" | jq -r '.tmp_dir')
REGION=$(echo "${INPUT}" | jq -r '.region')
RESOURCE_GROUP=$(echo "${INPUT}" | jq -r '.resource_group')
SUBNET_IDS=$(echo "${INPUT}" | jq -c '.subnet_ids')
IBMCLOUD_API_KEY=$(echo "${INPUT}" | jq -r '.ibmcloud_api_key')

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR="./.tmp/vpn-gateway"
fi
mkdir -p "${TMP_DIR}"

OUTPUT_FILE="${TMP_DIR}/output.json"

echo "[]" > "${OUTPUT_FILE}"

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token')

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com"
API_VERSION="2021-06-18"

IFS=','
subnet_ids=$SUBNET_IDS

VPN_GATEWAYS=$(curl -s -X GET "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2&resource_group.id=${RESOURCE_GROUP}" -H "Authorization: Bearer ${IAM_TOKEN}")

IFS=','
subnet_ids=$SUBNET_IDS
for id in $subnet_ids; do
  echo "${VPN_GATEWAYS}" | jq -c --arg ID "${id}" '.vpn_gateways[] | select(.subnet.id == $ID)' | \
    while read gateway;
  do
    jq --argjson ENTRY "${gateway}" '. += [$ENTRY]' < "${OUTPUT_FILE}" > "${OUTPUT_FILE}.tmp" && \
      cp "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}" && \
      rm "${OUTPUT_FILE}.tmp"
  done
done

OUTPUT=$(jq -c '.' "${OUTPUT_FILE}")

rm -f "${OUTPUT_FILE}" 1> /dev/null 2> /dev/null

jq -n --arg OUTPUT "${OUTPUT}" '{"output": $OUTPUT}'
