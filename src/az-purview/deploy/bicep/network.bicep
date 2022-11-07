@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the virtual network.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param privateEndpointSubnetName string

@description('The name of the virtual network subnet to be used for self-hosted integration runtime (SHIR) subnet.')
param shirSubnetName string

@description('The virtual network IP space to use for the new virutal network.')
param vnetAddressPrefix string

@description('The IP space to use for the subnet for private endpoints.')
param privateEndpointSubnetAddressPrefix string

@description('The IP space to use for the AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string

@description('The IP space to use for the self-hosted integration runtime.')
param shirSubnetAddressPrefix string

@description('The tags to be applied to the provisioned resources.')
param tags object

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
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: shirSubnetName
        properties: {
          addressPrefix: shirSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
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
output outPrivateEndpointSubnetName string = privateEndpointSubnetName
output outShirSubnetName string = shirSubnetName
