@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The username to use for the Synapse SQL admin.')
param synSqlAdminUsername string = 'synsqladminuser'

@description('The password to use for the Synapse SQL admin.')
@secure()
param synSqlAdminPassword string

@description('The IP address prefix for the virtual network')
param vnetAddressPrefix string = '10.5.0.0/20'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param privateEndpointSubnetAddressPrefix string = '10.5.0.0/26'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string =  '10.5.1.0/26'

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
  'privatelink.sql.azuresynapse.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.azuresynapse.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.dfs.${environment().suffixes.storage}'
]

// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceGroup().name : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var keyVaultPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var sqlPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.sql.azuresynapse.net')
var devPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dev.azuresynapse.net')
var webPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azuresynapse.net')
var dfsPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')

// Networking related variables
var vnetName = 'vnet-${baseName}'
var privateEndpointSubnetName = 'snet-${baseName}-pe'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'

// Azure Storage account related variables
var arrStorageAccountName = [
  'st1${baseName}'
  'st2${baseName}'
]
var defaultContainerName = 'container001'

// Azure Synapse Analytics related variables
var synWorkspaceName = 'synw-${baseName}'
var synBigDataPoolName = 'synsp001'
var synSqlPoolName = 'syndp001'
var synPrivateLinkHubName = 'synplhub${baseName}'

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
    vnetAddressPrefix: vnetAddressPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
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
    arrStorageAccountName: arrStorageAccountName
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

module synapse 'synapse.bicep' = {
  name: 'SynapseDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    privateLinkHubName: synPrivateLinkHubName
    synWorkspaceName: synWorkspaceName
    synBigDataPoolName: synBigDataPoolName
    synSqlPoolName: synSqlPoolName
    synStorageAccountName: storage.outputs.outSynStorageAccountName
    synStorageFilesysName: storage.outputs.outSynStorageFilesysName
    mainStorageAccountName: storage.outputs.outMainStorageAccountName
    mainStorageFilesysName: storage.outputs.outMainStorageFilesysName
    keyVaultName: keyVault.outputs.outKeyVaultName
    synSqlAdminUsername: synSqlAdminUsername
    synSqlAdminPassword: synSqlAdminPassword
    sqlPrivateDnsZoneId: sqlPrivateDnsZoneId
    devPrivateDnsZoneId: devPrivateDnsZoneId
    webPrivateDnsZoneId: webPrivateDnsZoneId
    tags: tags
  }
  dependsOn: [
    storage
    keyVault
  ]
}

output outVirtualNetworkName string = network.outputs.outVnetName
output outPrivateEndpointSubnetName string = network.outputs.outPrivateEndpointSubnetName
output outKeyVaultName string = keyVault.outputs.outKeyVaultName
output outSynapseWorkspaceName string = synapse.outputs.outSynapseWorkspaceName
output outSynapseDefaultStorageAccountName string = synapse.outputs.outSynapseDefaultStorageAccountName
output outMainStorageAccountName string = storage.outputs.outMainStorageAccountName
output outSynapseSqlPoolName string = synapse.outputs.outSynapseSqlPoolName
output outSynapseBigdataPoolName string = synapse.outputs.outSynapseBigdataPoolName
