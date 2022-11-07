targetScope = 'resourceGroup'

@description('The application VNet name; this is the VNet which has the subnet for private endpoints required for application connectivity.')
param applicationVnetName string

@description('The agent VNet name; this is the VNet which has the self-hosted agent running for CI/CD.')
param operationsVnetName string

@description('The resource group for the target VNet.')
param operationsResourceGroupName string

@description('The subscription id of the remote Virtual Network.')
param operationsSubscriptionId string

resource applicationVnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: applicationVnetName
}

resource agentVnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: operationsVnetName
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
}

resource agentResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: operationsResourceGroupName
  scope: subscription(operationsSubscriptionId)
}

module peering001 'vnet-peering.bicep' = {
  name: 'vnetPeering001'
  scope: resourceGroup()
  params: {
    vnetName: applicationVnet.name
    remoteVnetName: agentVnet.name
    remoteResourceGroupName: agentResourceGroup.name
    remoteSubscriptionId: operationsSubscriptionId
  }
}

module peering002 'vnet-peering.bicep' = {
  name: 'vnetPeering002'
  scope: resourceGroup(operationsSubscriptionId, agentResourceGroup.name)
  params: {
    vnetName: agentVnet.name
    remoteVnetName: applicationVnet.name
    remoteResourceGroupName: resourceGroup().name
    remoteSubscriptionId: subscription().subscriptionId
  }
}
