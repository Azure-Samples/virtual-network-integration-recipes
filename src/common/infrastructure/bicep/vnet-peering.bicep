@description('The name of the source Virtual Network.')
param vnetName string

@description('The name of the remote Virtual Network.')
param remoteVnetName string

@description('The resource group name of the remote Virtual Network.')
param remoteResourceGroupName string = resourceGroup().name

@description('The subscription id of the remote Virtual Network.')
param remoteSubscriptionId string = subscription().subscriptionId

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing =  {
  name: vnetName
}

resource remoteVnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing =  {
  name: remoteVnetName
  scope: resourceGroup(remoteSubscriptionId, remoteResourceGroupName)
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  parent: vnet
  name: 'peer-${vnetName}-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: remoteVnet.id
    }
  }
}
