@description('The Azure region in which to create the resource group.')
param location string

@description('The name of the Azure resource group to be created.')
param resourceGroupName string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: resourceGroupName
}
