@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The IP address prefix for the virtual network')
param vnetAddressPrefix string = '10.11.0.0/16'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param privateEndpointSubnetAddressPrefix string = '10.11.0.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string =  '10.11.1.0/24'

@description('The IP address prefix for the containerß subnet of Azure Databricks.')
param containerSubnetAddressPrefix string = '10.11.2.0/24'

@description('The IP address prefix for the host subnet of Azure Databricks.')
param hostSubnetAddressPrefix string = '10.11.3.0/24'

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
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.dfs.${environment().suffixes.storage}'
]

// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceGroup().name : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var keyVaultPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var dfsPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')

// Networking related variables
var vnetNameLower = 'vnet-${baseName}'
var privateEndpointSubnetName = 'snet-${baseName}-pe'
var hostSubnetName = 'snet-${baseName}-host'
var containerSubnetName = 'snet-${baseName}-container'
var networkSecurityGroupName = 'nsg-${baseName}'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'

// Azure Storage account related variables
var storageAccountName = 'st1${baseName}'
var defaultContainerName = 'container001'

// Azure Databricks related variables
var databricksWorkspaceName = 'dbw-${baseName}'

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
    baseName: baseName
    vnetName: vnetNameLower
    peSubnetName: privateEndpointSubnetName
    hostSubnetName: hostSubnetName
    containerSubnetName: containerSubnetName
    networkSecurityGroupName: networkSecurityGroupName
    vnetAddressPrefix: vnetAddressPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
    hostSubnetAddressPrefix: hostSubnetAddressPrefix
    containerSubnetAddressPrefix: containerSubnetAddressPrefix
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
  name: 'storageDeploy'
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

module db 'databricks.bicep' = {
  name: 'databricksDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    databricksWorkspaceName: databricksWorkspaceName
    vnetName: network.outputs.outVnetName
    hostSubnetName: network.outputs.outHostSubnetName
    containerSubnetName: network.outputs.outContainerSubnetName
    tags: tags
  }
  dependsOn: [
    storage
    keyVault
  ]
}

output outVirtualNetworkName string = network.outputs.outVnetName
output outPrivateEndpointSubnetName string = network.outputs.outPrivateEndpointSubnetName
output outHostSubnetName string = network.outputs.outHostSubnetName
output outContainerSubnetName string = network.outputs.outContainerSubnetName
output outKeyVaultName string = keyVault.outputs.outKeyVaultName
output outStorageAccountName string = storage.outputs.outStorageAccountName
output outStorageFilesysName string = storage.outputs.outStorageFilesysName
output outDatabricksWorkspaceName string = db.outputs.outDatabricksWorkspaceName
output outDatabricksStorageAccountName string = db.outputs.outDatabricksStorageAccountName
