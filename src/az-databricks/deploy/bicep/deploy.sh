#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# The short name for the Azure region (az account list-locations --query [].name -o tsv)
LOCATION=australiaeast

# The name of the existing virtual network within the OPERATIONS_RESOURCE_GROUP_NAME resource group; used to establish a peering relationship.
OPERATIONS_VNET_NAME=[YOUR-OPERATIONS-VIRUTAL-NETWORK-NAME]

# The name of the operations resource group (used in a hub/spoke vnet model).
OPERATIONS_RESOURCE_GROUP_NAME=[YOUR-OPERATIONS-RESOURCE-GROUP-NAME]

# The subscription id of the operations resource group (used in a hub/spoke vnet model).
OPERATIONS_SUBSCRIPTION_ID=[YOUR-OPERATIONS-SUBSCRIPTION_ID]

# Flag to indicate if virtual network peering should be established. Set to "true" if peering to the OPERATIONS_VNET_NAME virtual network.
PEER_VNET="false"

# Getting current subscription id
SUBSCRIPTION_ID="$(az account show | jq -r '.id')"

az deployment sub create \
    --location $LOCATION \
    --name "databricksVnetRcpDeploy" \
    --template-file main.bicep \
    --parameters azuredeploy.parameters.json > output.json

if [[ $PEER_VNET == "true" ]]; then
    echo "Retrieving virtual network name created in Azure Databricks recipe deployment . . ."

    RECIPE_VNET_NAME="$(jq -r '.properties.outputs.outTransitVirtualNetworkName.value' output.json)"
    RECIPE_RESOURCE_GROUP_NAME="$(jq -r '.properties.outputs.outResourceGroupName.value' output.json)"

    echo "Retrieved virtual network name: '$RECIPE_VNET_NAME'."

    # Recipe vnet to the hub vnet
    echo "Establishing peering relationship: '$RECIPE_VNET_NAME' to '$OPERATIONS_VNET_NAME' . . ."
    az deployment group create \
        --resource-group "$RECIPE_RESOURCE_GROUP_NAME" \
        --template-file '../../../common/infrastructure/bicep/vnet-peering.bicep' \
        --parameters vnetName="$RECIPE_VNET_NAME" remoteVnetName="$OPERATIONS_VNET_NAME" remoteResourceGroupName="$OPERATIONS_RESOURCE_GROUP_NAME" remoteSubscriptionId="$OPERATIONS_SUBSCRIPTION_ID"

    # Hub vnet to the recipe vnet.
    echo "Establishing peering relationship: '$OPERATIONS_VNET_NAME' to '$RECIPE_VNET_NAME' . . ."
    az account set -s "$OPERATIONS_SUBSCRIPTION_ID"
    az deployment group create \
        --resource-group "$OPERATIONS_RESOURCE_GROUP_NAME" \
        --template-file '../../../common/infrastructure/bicep/vnet-peering.bicep' \
        --parameters vnetName="$OPERATIONS_VNET_NAME" remoteVnetName="$RECIPE_VNET_NAME" remoteResourceGroupName="$RESOURCE_GROUP_NAME" remoteSubscriptionId="$SUBSCRIPTION_ID"
fi