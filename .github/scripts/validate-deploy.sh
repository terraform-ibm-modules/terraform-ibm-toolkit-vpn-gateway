#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

echo "terraform.tfvars"
cat terraform.tfvars

PREFIX_NAME=$(cat terraform.tfvars | grep name_prefix | sed "s/name_prefix=//g" | sed 's/"//g' | sed "s/_/-/g")
REGION=$(cat terraform.tfvars | grep -E "^region" | sed "s/region=//g" | sed 's/"//g')
RESOURCE_GROUP_NAME=$(cat terraform.tfvars | grep resource_group_name | sed "s/resource_group_name=//g" | sed 's/"//g')

echo "PREFIX_NAME: ${PREFIX_NAME}"
echo "REGION: ${REGION}"
echo "RESOURCE_GROUP_NAME: ${RESOURCE_GROUP_NAME}"
echo "IBMCLOUD_API_KEY: ${IBMCLOUD_API_KEY}"

VPC_NAME="${PREFIX_NAME}-vpc"

exit 0
