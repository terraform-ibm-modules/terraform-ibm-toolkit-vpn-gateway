#!/usr/bin/env bash

REGION="$1"
RESOURCE_GROUP="$2"
SUBNET_IDS="$3"

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

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token')

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com"
API_VERSION="2021-06-18"

VPN_GATEWAYS=$(curl -s -X GET "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2&resource_group.id=${RESOURCE_GROUP}" -H "Authorization: Bearer ${IAM_TOKEN}")

IFS=','
subnet_ids=$SUBNET_IDS
for id in $subnet_ids; do
  echo "${VPN_GATEWAYS}" | jq -r --arg ID "${id}" '.vpn_gateways[] | select(.subnet.id == $ID) | .id' | \
    while read vpn_gateway_id;
  do
    curl -s -X DELETE "${API_ENDPOINT}/v1/vpn_gateways/${vpn_gateway_id}?version=${API_VERSION}&generation=2" -H "Authorization: Bearer ${IAM_TOKEN}"

    echo "$vpn_gateway_id" >> "${GATEWAY_IDS_FILE}"
  done
done

GATEWAY_IDS_REGEX=$(cat "${GATEWAY_IDS_FILE}" | paste -sd "|" -)

echo "Waiting for VPN Gateways to be deleted"

count=0
while [[ $count -lt 45 ]]; do
  ids=$(curl -s -X GET "${API_ENDPOINT}/v1/vpn_gateways?version=${API_VERSION}&generation=2&resource_group.id=${RESOURCE_GROUP}" -H "Authorization: Bearer ${IAM_TOKEN}" | jq -r '.vpn_gateways[] | .id' | grep -E "${GATEWAY_IDS_REGEX}" | paste -sd ";" -)

  if [[ -z "$ids" ]]; then
    echo "VPN Gateway have been deleted"
    break
  fi

  count=$((count + 1))
  echo "Waiting for VPN Gateways to be deleted: $ids"
  sleep 60
done

if [[ $count -eq 45 ]]; then
  echo "Timed out waiting for VPN Gateway to be deleted"
fi
