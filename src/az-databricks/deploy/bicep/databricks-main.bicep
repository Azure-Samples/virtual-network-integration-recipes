@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Azure Databricks workspace.')
param databricksWorkspaceName string

@description('The name of the managed resource group for Azure Databricks')
param managedResourceGroupName string

@description('The name of the virtual network used by Azure Databricks.')
param vnetName string

@description('The name of the databricks host subnet.')
param hostSubnetName string

@description('The name of the databricks container subnet.')
param containerSubnetName string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource databricks 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksWorkspaceName
  location: location
  tags: tags
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: {
      customVirtualNetworkId: {
        value: resourceId('Microsoft.Network/virtualNetworks', vnetName)
      }
      customPrivateSubnetName: {
        value: containerSubnetName
      }
      customPublicSubnetName: {
        value: hostSubnetName
      }
      enableNoPublicIp: {
        value: true
      }
      requireInfrastructureEncryption: {
        value: true
      }
    }
    publicNetworkAccess: 'Disabled'
    requiredNsgRules: 'NoAzureDatabricksRules'
  }
}

output outDatabricksWorkspaceId string = databricks.id
output outDatabricksWorkspaceName string = databricks.name
output outDatabricksStorageAccountName string = databricks.properties.parameters.storageAccountName.value
