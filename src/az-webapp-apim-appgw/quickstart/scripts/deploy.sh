#!/bin/bash

RESOURCE_GROUP_NAME=$1
LOCATION=$2

if [[ -z $RESOURCE_GROUP_NAME ]] || [[ -z $LOCATION ]]
then  
    echo "Parameters missing."
    echo "Usage: deploy.sh resource_group location "
    echo "Try: deploy.sh rg-foo eastus"
    exit
fi

echo "Setting resource group: $RESOURCE_GROUP_NAME"

DEPLOYMENT_LABEL=Deployment-$(date +"%Y-%m-%d_%H%M%S")

az group create --location "$LOCATION" --name "$RESOURCE_GROUP_NAME"

echo "Setting deployment label: $DEPLOYMENT_LABEL"

# NOTE: Parameters defined in-line below will override those set in azuredeploy.parameters.json file.
az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_LABEL" \
    --template-file ../main.bicep \
    --parameters ../azuredeploy.parameters.json \
    --confirm-with-what-if
    
