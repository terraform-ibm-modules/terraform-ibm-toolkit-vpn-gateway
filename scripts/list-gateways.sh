#!/usr/bin/env bash

REGION="$1"
RESOURCE_GROUP="$2"
SUBNET_IDS="$3"
OUTPUT_FILE="$4"

if [[ -z "${OUTPUT_FILE}" ]]; then
  echo "OUTPUT_FILE is missing"
  exit 1
fi

mkdir -p "$(dirname "${OUTPUT_FILE}")"

JQ=$(command -v jq | command -v ./bin/jq)

if [[ -z "${JQ}" ]]; then
  echo "jq missing. Installing"
  mkdir -p bin && curl -sLo ./bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x ./bin/jq
  JQ=$(command -v ./bin/jq)
fi

echo "[]" > "${OUTPUT_FILE}"

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | ${JQ} -r '.access_token')

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com"
API_VERSION="2021-06-18"

IFS=','
subnet_ids=$SUBNET_IDS

VPN_GATEWAYS=$(curl -s -X GET "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2&resource_group.id=${RESOURCE_GROUP}" -H "Authorization: Bearer ${IAM_TOKEN}")

IFS=','
subnet_ids=$SUBNET_IDS
for id in $subnet_ids; do
  echo "${VPN_GATEWAYS}" | ${JQ} -c --arg ID "${id}" '.vpn_gateways[] | select(.subnet.id == $ID)' | \
    while read gateway;
  do
    jq --argjson ENTRY "${gateway}" '. += [$ENTRY]' < "${OUTPUT_FILE}" > "${OUTPUT_FILE}.tmp" && \
      cp "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}" && \
      rm "${OUTPUT_FILE}.tmp"
  done
done

echo "Matching gateways"
cat "${OUTPUT_FILE}"
