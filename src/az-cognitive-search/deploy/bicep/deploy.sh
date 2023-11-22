#!/bin/bash

# The short name for the Azure region (az account list-locations --query [].name -o tsv)
LOCATION=australiaeast

# The name of the resource group to be created for the deployment.
RESOURCE_GROUP_NAME=rg-rcp-vector-search

az group create --location "${LOCATION}" --name "${RESOURCE_GROUP_NAME}"

az deployment group create --resource-group "${RESOURCE_GROUP_NAME}" --template-file main.bicep --verbose