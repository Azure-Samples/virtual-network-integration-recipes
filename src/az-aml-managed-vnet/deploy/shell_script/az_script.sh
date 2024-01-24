#!/bin/bash

# Azure CLI commands to execute
az_login() {
    # Log in to Azure (interactive login)
    az login
}

az_list_resource_groups() {
    # List all resource groups in the current subscription
    az group list --output table
}

az_create_resource_group() {
    # Create a new resource group
    resource_group_name="MyResourceGroup"
    location="East US"

    az group create --name $resource_group_name --location $location
}

# Execute Azure CLI commands
echo "Logging in to Azure..."
az_login

echo "Listing resource groups..."
az_list_resource_groups

echo "Creating a new resource group..."
az_create_resource_group

echo "Listing resource groups after creation..."
az_list_resource_groups

# Additional Azure CLI commands can be added as needed

# Note: It's important to handle errors and edge cases appropriately in a production script.
