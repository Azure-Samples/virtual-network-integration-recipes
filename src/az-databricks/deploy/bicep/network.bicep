@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param baseName string

@description('The name of the virtual network.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param peSubnetName string

@description('The name of the databricks host subnet.')
param hostSubnetName string

@description('The name of the databricks container subnet.')
param containerSubnetName string

@description('The name of the network security group to be attached to the databricks subnets.')
param networkSecurityGroupName string

@description('The virtual network IP space to use for the new virutal network.')
param vnetAddressPrefix string

@description('The IP space to use for the subnet for private endpoints.')
param privateEndpointSubnetAddressPrefix string

@description('The IP space to use for the AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string

@description('The IP space to use for the databricks host subnet.')
param hostSubnetAddressPrefix string

@description('The IP space to use for the databricks container subnet.')
param containerSubnetAddressPrefix string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource dbNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: '${baseName}-nsgsg-001'
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
        name: '${baseName}-nsgsg-002'
        properties: {
          description: 'Required for workers communication with Databricks Webapp.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: '${baseName}-nsgsg-003'
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
        name: '${baseName}-nsgsg-004'
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
        name: '${baseName}-nsgsg-005'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
        }
      }
      {
        name: '${baseName}-nsgsg-006'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Please note that though not required for the recipe, the "AzureBastionSubnet" subnet has been created to maintain idempotency of the deployment
// in case user decides to create a bastion host in the same VNet for testing purpose.
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
        name: peSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: hostSubnetName
        properties: {
          addressPrefix: hostSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'db-container-vnet-integration'
            }
          ]
          networkSecurityGroup: {
            id: dbNetworkSecurityGroup.id
          }
        }
      }
      {
        name: containerSubnetName
        properties: {
          addressPrefix: containerSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
              name: 'db-host-vnet-integration'
            }
          ]
          networkSecurityGroup: {
            id: dbNetworkSecurityGroup.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output outVnetName string = vnet.name
output outVnetId string = vnet.id
output outPrivateEndpointSubnetName string = peSubnetName
output outHostSubnetName string = hostSubnetName
output outContainerSubnetName string = containerSubnetName
output outNetworkSecurityGroupName string = dbNetworkSecurityGroup.name
