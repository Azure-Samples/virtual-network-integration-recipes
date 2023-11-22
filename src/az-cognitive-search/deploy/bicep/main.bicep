@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The address prefix for the virtual network.')
param vnetAddressPrefix string = '10.16.0.0/16'

@description('The address prefix for the private endpoint subnet.')
param privateEndpointSubnetAddressPrefix string = '10.16.0.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string =  '10.16.1.0/26'

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZones string = 'new'

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The ID of the Azure subscription containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneSubscriptionId string = subscription().subscriptionId

// General/Common variables
// Ensure that a user-provided value is lowercase.
var baseName = toLower(resourceBaseName)
var tags = {
  baseName : baseName
}

// Private DNS Zone variables
var privateDnsNames = [
  'privatelink.search.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.openai.azure.com'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.dfs.${environment().suffixes.storage}'
]

// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceGroup().name : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var cogSearchPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.search.windows.net')
var openAiPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.openai.azure.com')
var keyVaultPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var dfsPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')

// Networking related variables
var vnetName = 'vnet-${baseName}'
var privateEndpointSubnetName = 'snet-${baseName}-pe'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'

// Azure Storage account related variables
var storageAccountName = 'st1${baseName}'
var defaultContainerName = 'container001'

// Azure Cognitive Search related variables
var searchServiceName = 'search-${baseName}'
var searchServiceSku = 'basic' // 'free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'
var searchServiceReplicaCount = 1
var searchServicePartitionCount = 1 // 1, 2, 3, 4, 6, 12 
var searchServiceHostingMode = 'default' // 'default', 'highDensity

// Azure OpenAI related variables
var openAiAccountName = 'openai-${baseName}'
var openAiAccountSku = 'S0'

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
  name: 'storageDeploy'
  scope: resourceGroup()
  params: {
    location: location
    baseName: baseName
    storageAccountName: storageAccountName
    defaultContainerName: defaultContainerName
    dfsPrivateDnsZoneId: dfsPrivateDnsZoneId
    blobPrivateDnsZoneId: blobPrivateDnsZoneId
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

module azureAiSearch 'azure-ai-search.bicep' = {
  name: 'azureAiSearchDeploy'
  scope: resourceGroup()
  params: {
    name: searchServiceName
    sku: searchServiceSku
    replicaCount: searchServiceReplicaCount
    partitionCount: searchServicePartitionCount
    hostingMode: searchServiceHostingMode
    storageAccountName: storage.outputs.outStorageAccountName
    keyVaultName: keyVault.outputs.outKeyVaultName
    location: location
    publicNetworkAccess: 'Disabled'
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    privateZoneDnsId: cogSearchPrivateDnsZoneId
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
    storage
    keyVault
  ]
}

module openaiAccount 'azure-openai.bicep' = {
  name: 'openaiAccountDeploy'
  scope: resourceGroup()
  params: {
    name: openAiAccountName
    sku: openAiAccountSku
    customSubDomainName: openAiAccountName
    location: location
    publicNetworkAccess: 'Disabled'
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    privateZoneDnsId: openAiPrivateDnsZoneId
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

output outKeyVaultName string = keyVault.outputs.outKeyVaultName
output outStorageAccountName string = storage.outputs.outStorageAccountName
output outStorageFilesysName string = storage.outputs.outStorageFilesysName

output azureAiSearchId string = azureAiSearch.outputs.outSearchId
output azureAiSearchName string = azureAiSearch.outputs.outSearchName
output azureAiSearchUrl string = azureAiSearch.outputs.outSearchUrl

output outAzureOpenaiAccountId string = openaiAccount.outputs.outAzureOpenaiAccountId
output outAzureOpenaiAccountName string = openaiAccount.outputs.outAzureOpenaiAccountName
output outAzureOpenaiEndpoint string = openaiAccount.outputs.outAzureOpenaiEndpoint

