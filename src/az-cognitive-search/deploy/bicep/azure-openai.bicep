param name string
param location string
param customSubDomainName string
param sku string
param publicNetworkAccess string
param vnetName string
param subnetName string
param privateZoneDnsId string
param tags object

var peGroupId = 'account'
var privateSubnetId = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetName, subnetName)

resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'OpenAI'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    publicNetworkAccess: publicNetworkAccess
    customSubDomainName: customSubDomainName
  }
  tags: tags
}

resource openaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (publicNetworkAccess == 'Disabled') {
  name: 'pe-openai-account-${peGroupId}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-openai-account-${peGroupId}'
        properties: {
          privateLinkServiceId: openaiAccount.id
          groupIds: [
            peGroupId
          ]
        }
      }
    ]
  }
}

resource openaiPrivateDnsZonesGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (publicNetworkAccess == 'Disabled') {
  parent: openaiPrivateEndpoint
  name: 'openaiPrivateDnsZonesGroups'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateZoneDnsId
        }
      }
    ]
  }
}

output outAzureOpenaiAccountId string = openaiAccount.id
output outAzureOpenaiAccountName string = openaiAccount.name
output outAzureOpenaiEndpoint string = openaiAccount.properties.endpoint
