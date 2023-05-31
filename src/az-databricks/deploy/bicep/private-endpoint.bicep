@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the private endpoint.')
param privateEndpointName string

@description('The name of the private endpoint DNS group.')
param privateEndpointDnsZoneGroupName string

@description('The private link service id.')
param privateLinkServiceId string

@description('The name of the virtual network used by Azure Databricks.')
param vnetName string

@description('The sub-resource name (groupId) for the private endpoint.')
param subResourceName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param peSubnetName string

@description('The Private DNS Zone id for the private endpoint.')
param privateDnsZoneId string

var privateSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, peSubnetName)

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            subResourceName
          ]
        }
      }
    ]
  }

  resource privateEndpointDnsGroup 'privateDnsZoneGroups@2022-09-01' = {
    name: privateEndpointDnsZoneGroupName
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}
