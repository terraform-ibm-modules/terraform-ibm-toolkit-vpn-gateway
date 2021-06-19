#!/usr/bin/env bash

REGION="$1"
BASE_NAME="$2"
SUBNET_IDS="$3"

JQ=$(command -v jq | command -v ./bin/jq)

if [[ -z "${JQ}" ]]; then
  echo "jq missing. Installing"
  mkdir -p bin && curl -Lo ./bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x ./bin/jq
  JQ=$(command -v ./bin/jq)
fi

IAM_TOKEN=$(curl -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | ${JQ} '.access_token')

API_ENDPOINT="https://${REGION}.iaas.cloud.ibm.com/v1"
API_VERSION="2021-06-18"

IFS=','
subnet_ids=$SUBNET_IDS
count=1
for id in subnet_ids; do
  curl -H "Authorization: ${IAM_TOKEN}" \
    -X POST "${API_ENDPOINT}/vpn_gateways?version=${API_VERSION}&generation=2" \
    -d "{\"name\":\"${BASE_NAME}-${count}\",\"subnet\":{\"id\": \"$id\"}}"

  count=$((count + 1))
done
