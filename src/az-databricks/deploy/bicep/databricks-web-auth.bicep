@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Azure Databricks workspace.')
param databricksWorkspaceName string

@description('The name of the managed resource group for Azure Databricks')
param managedResourceGroupName string

@description('The name of the Azure Databricks virtual network.')
param vnetName string

@description('The virtual network IP space to use for the Azure Databricks workspace virtual network')
param vnetAddressPrefix string

@description('The name of the databricks workspace host subnet.')
param hostSubnetName string

@description('The IP space to use for the databricks host subnet.')
param hostSubnetAddressPrefix string

@description('The name of the databricks workspace container subnet.')
param containerSubnetName string

@description('The IP space to use for the databricks container subnet.')
param containerSubnetAddressPrefix string

@description('The name of the network security group to be attached to the databricks workspace subnets.')
param networkSecurityGroupName string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroupName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
        properties: {
          description: 'Required for workers communication with Azure SQL services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
        properties: {
          description: 'Required for workers communication with Azure Storage services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: hostSubnetName
        properties: {
          addressPrefix: hostSubnetAddressPrefix
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'del-host-databricks'
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: containerSubnetName
        properties: {
          addressPrefix: containerSubnetAddressPrefix
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'del-container-databricks'
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

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
        value: vnet.id
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

// Setting a lock for this databricks workspace
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lock-${databricksWorkspaceName}-do-not-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Azure Databricks web authentication workspace should not be deleted.'
  }
  scope: databricks
}

output outDatabricksWorkspaceId string = databricks.id
output outDatabricksWorkspaceName string = databricks.name
output outDatabricksStorageAccountName string = databricks.properties.parameters.storageAccountName.value
