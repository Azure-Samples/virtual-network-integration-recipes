@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The IP address prefix for the virtual network')
param vnetAddressPrefix string = '10.13.0.0/16'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param privateEndpointSubnetAddressPrefix string = '10.13.0.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string =  '10.13.1.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param shirSubnetAddressPrefix string =  '10.13.2.0/24'

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The ID of the Azure subscription containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneSubscriptionId string = subscription().subscriptionId

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZones string = 'new'

// General/Common variables
// Ensure that a user-provided value is lowercase.
var baseName = toLower(resourceBaseName)
var tags = {
  baseName : baseName
}

// Private DNS Zone variables
var privateDnsNames = [
  'privatelink.servicebus.windows.net'
  'privatelink.purviewstudio.azure.com'
  'privatelink.purview.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.dfs.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
]

// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceGroup().name : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var keyVaultPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var namespacePrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.servicebus.windows.net')
var portalPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.purviewstudio.azure.com')
var accountPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.purview.azure.com')
var dfsPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')
var queuePrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.queue.${environment().suffixes.storage}')

// Networking related variables
var vnetName = 'vnet-${baseName}'
var privateEndpointSubnetName = 'snet-${baseName}-pe'
var shirSubnetName = 'snet-${baseName}-shir'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'

// Azure Storage account related variables
var storageAccountName = 'st${baseName}'
var defaultContainerName = 'container001'

// Purview
var purviewAccountName = 'pview-${baseName}'

module dnsZone '../../../common/infrastructure/bicep/private-dns-zones.bicep' = if (newOrExistingDnsZones == 'new') {
  name: 'dnsZoneDeploy'
  scope: resourceGroup()
  params: {
    privateDnsNames: privateDnsNames
    tags: tags
  }
}

module network 'network.bicep' = {
  name: 'networkDeploy'
  scope: resourceGroup()
  params: {
    location: location
    vnetName: vnetName
    privateEndpointSubnetName: privateEndpointSubnetName
    shirSubnetName: shirSubnetName
    vnetAddressPrefix: vnetAddressPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
    shirSubnetAddressPrefix: shirSubnetAddressPrefix
    tags: tags
  }
}

module privateDnsZoneVnetLink '../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = [ for (names, i) in privateDnsNames: {
  name: 'privateDnsZoneVnetLinkDeploy-${i}'
  scope: resourceGroup(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: names
    vnetId: network.outputs.outVnetId
    vnetLinkName: '${network.outputs.outVnetName}-link'
  }
  dependsOn: [
    dnsZone
    network
  ]
}]

module keyVault 'key-vault.bicep' = {
  name: 'keyVaultDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    keyVaultName: keyVaultName
    keyVaultPrivateDnsZoneId: keyVaultPrivateDnsZoneId
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

module storage 'storage.bicep' = {
  name: 'StorageDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    storageAccountName: storageAccountName
    defaultContainerName: defaultContainerName
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    dfsPrivateDnsZoneId: dfsPrivateDnsZoneId
    blobPrivateDnsZoneId: blobPrivateDnsZoneId
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

module purview 'purview.bicep' = {
  name: 'PurviewDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    purviewAccountName: purviewAccountName
    storageAccountName: storage.outputs.outStorageAccountName
    keyVaultName: keyVault.outputs.outKeyVaultName
    namespacePrivateDnsZoneId: namespacePrivateDnsZoneId
    portalPrivateDnsZoneId: portalPrivateDnsZoneId
    accountPrivateDnsZoneId: accountPrivateDnsZoneId
    blobPrivateDnsZoneId: blobPrivateDnsZoneId
    queuePrivateDnsZoneId: queuePrivateDnsZoneId
  }
  dependsOn: [
    storage
    keyVault
  ]
}

output outVirtualNetworkName string = network.outputs.outVnetName
output outPrivateEndpointSubnetName string = network.outputs.outPrivateEndpointSubnetName
output outShirSubnetName string = network.outputs.outShirSubnetName
output outKeyVaultName string = keyVault.outputs.outKeyVaultName
output outStorageAccountName string = storage.outputs.outStorageAccountName
output outStorageFilesysName string = storage.outputs.outStorageFilesysName
output outPurviewAccountName string = purview.outputs.outPurviewAccountName
output outPurviewCatalogUri  string = purview.outputs.outPurviewCatalogUri
