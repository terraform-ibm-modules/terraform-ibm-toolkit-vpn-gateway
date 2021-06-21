#!/usr/bin/env bash

REGION="$1"
RESOURCE_GROUP="$2"
BASE_NAME="$3"
SUBNET_IDS="$4"

JQ=$(command -v jq | command -v ./bin/jq)

if [[ -z "${JQ}" ]]; then
  echo "jq missing. Installing"
  mkdir -p bin && curl -sLo ./bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x ./bin/jq
  JQ=$(command -v ./bin/jq)
fi

IAM_RESULT=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}")
IAM_TOKEN=$(echo "${IAM_RESULT}" | ${JQ} '.access_token')

if [[ -z "${IAM_TOKEN}" ]]; then
  echo "Error getting IAM_TOKEN"
  exit 1
fi

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com/v1"
API_VERSION="2021-06-18"

IFS=','
subnet_ids=$SUBNET_IDS
count=1
for id in $subnet_ids; do
  name="${BASE_NAME}-${count}"
  echo "Provisioning $name VPN instance for subnet: $id"

  RESULT=$(curl -s -H "Authorization: Bearer ${IAM_TOKEN}" -X POST "${API_ENDPOINT}/vpn_gateways?version=${API_VERSION}&generation=2" -d "{\"name\":\"${name}\",\"mode\":\"policy\",\"subnet\":{\"id\": \"$id\"},\"resource_group\":{\"id\":\"${RESOURCE_GROUP}\"}}")

  echo "Result: ${RESULT}"

  count=$((count + 1))
done
