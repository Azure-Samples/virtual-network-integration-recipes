#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# The short name for the Azure region (az account list-locations --query [].name -o tsv)
LOCATION=eastus

# The name of the resource group to be created for the deployment.
RESOURCE_GROUP_NAME=[YOUR-RESOURCE-GROUP-NAME]

# The name of the operations resource group (used in a hub/spoke vnet model).
OPERATIONS_RESOURCE_GROUP_NAME=[YOUR-OPERATIONS-RESOURCE-GROUP-NAME]

# The name of the existing virtual network within the OPERATIONS_RESOURCE_GROUP_NAME resource group; used to establish a peering relationship.
OPERATIONS_VNET_NAME=[YOUR-OPERATIONS-VIRUTAL-NETWORK-NAME]

# Flag to indicate if virtual network peering should be established. Set to "true" if peering to the OPERATIONS_VNET_NAME virtual network.
PEER_VNET="false"

az group create --location $LOCATION --name "$RESOURCE_GROUP_NAME"

az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file main.bicep \
    --parameters azuredeploy.parameters.json > output.json

if [[ $PEER_VNET == "true" ]]; then
    echo "Retrieving virtual network name created in Private HTTP Function recipe deployment . . ."

    RECIPE_VNET_NAME="$(jq -r '.properties.outputs.virtualNetworkName.value' output.json)"

    echo "Retrieved virtual network name: '$RECIPE_VNET_NAME'."

    # Hub vnet to the recipe vnet.
    echo "Establishing peering relationship: '$OPERATIONS_VNET_NAME' to '$RECIPE_VNET_NAME' . . ."
    az deployment group create \
        --resource-group "$OPERATIONS_RESOURCE_GROUP_NAME" \
        --template-file '../../../common/infrastructure/bicep/vnet-peering.bicep' \
        --parameters sourceVnetName="$OPERATIONS_VNET_NAME" targetVnetName="$RECIPE_VNET_NAME" targetResourceGroup="$RESOURCE_GROUP_NAME"

    # Recipe vnet to the hub vnet
    echo "Establishing peering relationship: '$RECIPE_VNET_NAME' to '$OPERATIONS_VNET_NAME' . . ."
    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file '../../../common/infrastructure/bicep/vnet-peering.bicep' \
        --parameters sourceVnetName="$RECIPE_VNET_NAME" targetVnetName="$OPERATIONS_VNET_NAME" targetResourceGroup="$OPERATIONS_RESOURCE_GROUP_NAME"
fi