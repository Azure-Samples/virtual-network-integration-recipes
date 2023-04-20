targetScope = 'subscription'

@description('The name of the resource group to create.')
param resourceGroupName string

@description('The location for all resources.')
param location string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resourceGroupId string = rg.id
output resourceGroupName string = rg.name
