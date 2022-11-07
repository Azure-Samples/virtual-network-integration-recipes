#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

RESOURCE_GROUP_NAME=[YOUR-RESOURCE-GROUP-NAME]
LOCATION=northcentralus
VM_ROLE_NAME="Virtual Machine Administrator Login"

DEPLOYMENT_NAME="deploy-$(date +%Y%m%d_%H%m%s%N)"

az group create --location $LOCATION --name "$RESOURCE_GROUP_NAME"

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file main.bicep \
    --parameters azuredeploy.parameters.json > outputs.json

echo "Azure Bicep deployment complete. Output saved to 'outputs.json' file."

echo "Retrieving ID for virtual machine jumpbox . . . "
# Get VM resource ID from Bicep output!
VM="$(jq -r '.properties.outputs.vmId.value' outputs.json)"

echo "Enabling Virtual Machine access via Azure AD . . . "
# Enable VM access via Azure AD
USERNAME=$(az account show --query user.name --output tsv)

echo "Assigning '$VM_ROLE_NAME' role to user '$USERNAME' for VM ID '$VM'. . . "

az role assignment create \
    --role "Virtual Machine Administrator Login" \
    --assignee "$USERNAME" \
    --scope "$VM"