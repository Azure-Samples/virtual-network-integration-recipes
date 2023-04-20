@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Azure Databricks virtual network.')
param workspaceVnetName string

@description('The virtual network IP space to use for the Azure Databricks workspace virtual network')
param workspaceVnetAddressPrefix string

@description('The name of the virtual network subnet to be used for databricks workspace backend private endpoint.')
param workspaceBackendPrivateEndpointSubnetName string

@description('The IP space to use for the subnet for databricks workspace private endpoint.')
param workspaceBackendPrivateEndpointSubnetAddressPrefix string

@description('The name of the databricks workspace host subnet.')
param workspaceHostSubnetName string

@description('The IP space to use for the databricks host subnet.')
param workspaceHostSubnetAddressPrefix string

@description('The name of the databricks workspace container subnet.')
param workspaceContainerSubnetName string

@description('The IP space to use for the databricks container subnet.')
param workspaceContainerSubnetAddressPrefix string

@description('The name of the network security group to be attached to the databricks workspace subnets.')
param workspaceNetworkSecurityGroupName string

@description('The name of the transit virtual network.')
param transitVnetName string

@description('The virtual network IP space to use for the transit virtual network')
param transitVnetAddressPrefix string

@description('The name of the virtual network subnet to be used for private endpoints.')
param transitPrivateEndpointSubnetName string

@description('The IP space to use for the subnet for private endpoints.')
param transitPrivateEndpointSubnetAddressPrefix string

@description('The name of the AzureBastionSubnet subnet.')
param transitBastionSubnetName string

@description('The IP space to use for the AzureBastionSubnet subnet.')
param transitBastionSubnetAddressPrefix string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource dbNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: workspaceNetworkSecurityGroupName
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
      {
        name: 'DenyInternetOutBound'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 104
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Please note that though not required for the recipe, the "AzureBastionSubnet" subnet has been created to maintain idempotency of the deployment
// in case user decides to create a bastion host in the same VNet for testing purpose.
resource workspaceVnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: workspaceVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        workspaceVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: workspaceBackendPrivateEndpointSubnetName
        properties: {
          addressPrefix: workspaceBackendPrivateEndpointSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: workspaceHostSubnetName
        properties: {
          addressPrefix: workspaceHostSubnetAddressPrefix
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'del-host-databricks'
            }
          ]
          networkSecurityGroup: {
            id: dbNetworkSecurityGroup.id
          }
        }
      }
      {
        name: workspaceContainerSubnetName
        properties: {
          addressPrefix: workspaceContainerSubnetAddressPrefix
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'del-container-databricks'
            }
          ]
          networkSecurityGroup: {
            id: dbNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource transitVnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: transitVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        transitVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: transitPrivateEndpointSubnetName
        properties: {
          addressPrefix: transitPrivateEndpointSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: transitBastionSubnetName
        properties: {
          addressPrefix: transitBastionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output outWorkspaceVnetName string = workspaceVnet.name
output outWorkspaceVnetId string = workspaceVnet.id
output outWorkspaceHostSubnetName string = workspaceHostSubnetName
output outWorkspaceContainerSubnetName string = workspaceContainerSubnetName
output outWorkspacePrivateEndpointSubnetName string = workspaceBackendPrivateEndpointSubnetName
output outWorkspaceNetworkSecurityGroupName string = dbNetworkSecurityGroup.name

output outTransitVnetName string = transitVnet.name
output outTransitVnetId string = transitVnet.id
output outTransitPrivateEndpointSubnetName string = transitPrivateEndpointSubnetName
output outTransitBastionSubnetName string = transitBastionSubnetName
