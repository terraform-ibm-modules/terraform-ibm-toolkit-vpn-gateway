#!/usr/bin/env bash

REGION="$1"
RESOURCE_GROUP="$2"
BASE_NAME="$3"
SUBNET_IDS="$4"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR="./.tmp/vpn-gateway"
fi
mkdir -p "${TMP_DIR}"

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

GATEWAY_IDS_FILE="${TMP_DIR}/vpn-gateway-ids-$(head /dev/urandom | LC_ALL=C tr -dc A-Za-z0-9 | head -c 5).txt"

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli is missing" >&2
  exit 1
fi

IAM_RESULT=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}")
IAM_TOKEN=$(echo "${IAM_RESULT}" | jq -r '.access_token')

if [[ -z "${IAM_TOKEN}" ]]; then
  echo "Error getting IAM_TOKEN"
  exit 1
fi

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com"
API_VERSION="2021-06-18"

IFS=','
subnet_ids=$SUBNET_IDS
count=1
for id in $subnet_ids; do
  name="${BASE_NAME}-${count}"
  echo "Creating $name VPN instance for subnet: $id"

  create_result=$(curl -s -H "Authorization: Bearer ${IAM_TOKEN}" -X POST "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2" -d "{\"name\":\"${name}\",\"mode\":\"policy\",\"subnet\":{\"id\": \"$id\"},\"resource_group\":{\"id\":\"${RESOURCE_GROUP}\"}}")

  vpn_gateway_id=$(echo "$create_result" | jq -r '.id // empty')

  echo "Provisioning $name: $vpn_gateway_id"

  echo "$vpn_gateway_id" >> "${GATEWAY_IDS_FILE}"

  count=$((count + 1))
done

GATEWAY_IDS_REGEX=$(cat "${GATEWAY_IDS_FILE}" | paste -sd "|" -)

sleep 30

echo "Waiting for VPN Gateways to be created: ${GATEWAY_IDS_REGEX}"

count=0
while [[ $count -lt 40 ]]; do
  statuses=$(curl -s -X GET "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2&resource_group.id=${RESOURCE_GROUP}" -H "Authorization: Bearer ${IAM_TOKEN}" | jq -r --arg re "${GATEWAY_IDS_REGEX}" '.vpn_gateways[] | select(.id|test($re)) | .status')

  echo "Statuses: $statuses"
  if [[ $(echo "$statuses" | grep -c "pending") -eq 0 ]]; then
    echo "VPN Gateways provisioned"
    break
  fi

  count=$((count + 1))
  echo "Waiting for VPN Gateways"
  sleep 30
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for VPN Gateways"
fi
