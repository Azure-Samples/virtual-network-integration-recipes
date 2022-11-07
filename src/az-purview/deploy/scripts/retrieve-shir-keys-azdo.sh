#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

echo "This script is meant to be run as part of an Azure DevOps pipeline."
echo "WARNING: This script uses an undocumented API (.proxy.purview.azure.com) which may change in future releases."

# Validating input parameters
if [ $# -ne 2 ]
then
    echo "Usage: $0 <PURVIEW_ACCOUNT_NAME> <PURVIEW_SHIR_NAME>"
    exit 1
fi

PURVIEW_ACCOUNT_NAME=$1
PURVIEW_SHIR_NAME=$2

# Create bearer token
bearer_token=$(az account get-access-token --resource https://purview.azure.net --output json | jq -r .accessToken)

# Create SHIR Key
# curl - To aid debugging in case of failure, remove --fail flag to show detailed output.
curl --request PUT \
  --url "https://$PURVIEW_ACCOUNT_NAME.proxy.purview.azure.com/integrationRuntimes/$PURVIEW_SHIR_NAME?api-version=2020-12-01-preview" \
  --header "authorization: Bearer $bearer_token" \
  --header "content-type: application/json" \
  --fail --silent --show-error \
  --data '{"name": "'"$PURVIEW_SHIR_NAME"'","properties":{"type":"SelfHosted"}}'

# Retrieve SHIR Key
shir_key=$(curl --request POST \
  --url "https://$PURVIEW_ACCOUNT_NAME.proxy.purview.azure.com/integrationRuntimes/$PURVIEW_SHIR_NAME/listAuthKeys?api-version=2020-12-01-preview" \
  --header "authorization: Bearer $bearer_token" \
  --header 'content-type: application/json' \
  --fail --silent --show-error \
  --data '{"name": "'"$PURVIEW_SHIR_NAME"'","properties":{"type":"SelfHosted"}}' | jq -r .authKey1)

# Set AzDO variable
echo "##vso[task.setvariable variable=PVIEW_SHIR_KEY;]$shir_key"
