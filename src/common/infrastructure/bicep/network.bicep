@description('The name for the Azure virtual network to be created.')
param virtualNetworkName string

@description('The name of the virtual network subnet to be used for Azure App Service regional virtual network integration.')
param subnetAppServiceIntName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointName string

@description('Azure region for the virtual network.')
param location string = resourceGroup().location

@description('The virtual network IP space to use for the new virutal network.')
param vnetAddressPrefix string

@description('The IP space to use for the subnet for Azure App Service regional virtual network integration.')
param subnetAppServiceIntAddressPrefix string

@description('The IP space to use for the subnet for private endpoints.')
param subnetPrivateEndpointAddressPrefix string

@description('The service types to enable service endpoints for on the App Service integration subnet.')
param subnetAppServiceIntServiceEndpointTypes array = []

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

var nsgName = 'nsg-${resourceBaseName}'

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${nsgName}-pe'
  location: location
}

resource appServiceIntegrationNsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${nsgName}-appServiceInt'
  location: location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetAppServiceIntName
        properties: {
          addressPrefix: subnetAppServiceIntAddressPrefix
          networkSecurityGroup: {
            id: appServiceIntegrationNsg.id
          }

          serviceEndpoints: [for service in subnetAppServiceIntServiceEndpointTypes: {
            service: service
            locations: [
              '*'
            ]
          }]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetPrivateEndpointName
        properties: {
          addressPrefix: subnetPrivateEndpointAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }

  resource appServiceIntegrationSubnet 'subnets' existing = {
    name: subnetAppServiceIntName
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: subnetPrivateEndpointName
  }
}

output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output subnetAppServiceIntId string = virtualNetwork::appServiceIntegrationSubnet.id
output subnetPrivateEndpointId string = virtualNetwork::privateEndpointSubnet.id
