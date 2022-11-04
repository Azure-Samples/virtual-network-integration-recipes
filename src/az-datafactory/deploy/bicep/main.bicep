@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The IP address prefix for the virtual network')
param vnetAddressPrefix string = '10.15.0.0/16'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param privateEndpointSubnetAddressPrefix string = '10.15.0.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param bastionSubnetAddressPrefix string =  '10.15.1.0/24'

@description('The username to use for the SQL admin.')
param sqlAdminUsername string

@description('The password to use for the SQL admin.')
@secure()
param sqlAdminPassword string

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
  'privatelink${environment().suffixes.sqlServerHostname}'
]

// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceGroup().name : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var keyVaultPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var sqlPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink${environment().suffixes.sqlServerHostname}')
var dfsPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')

// Networking related variables
var vnetName = 'vnet-${baseName}'
var privateEndpointSubnetName = 'snet-${baseName}-pe'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'

// Azure Storage account related variables
var storageAccountName = 'st${baseName}'
var defaultContainerName = 'container001'

// Azure SQL Server/Database related variables
var sqlServerName = 'sql-${baseName}'
var sqlDatabaseName = 'sql-db-${baseName}'

// Azure Datafactory related variables
var azureDataFactoryName = 'adf-${baseName}'
// Managed private endpoints
var mpeStorageName = 'mpe-st-blob-${baseName}'
var mpeKeyvaultName = 'mpe-kv-vault-${baseName}'
var mpeSqlServerName = 'mpe-sql-server-${baseName}'
// Linked services
var lsStorageName = 'ls-st-blob-${baseName}'
var lsKeyvaultName = 'ls-kv-vault-${baseName}'
var lsSqlDatabaseName = 'ls-sql-db-${baseName}'

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

module sql 'azuresql.bicep' = {
  name: 'AzureSQLDeploy'
  scope: resourceGroup()
  params: {
    location: location
    vnetName: network.outputs.outVnetName
    subnetName: network.outputs.outPrivateEndpointSubnetName
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    sqlPrivateDnsZoneId: sqlPrivateDnsZoneId
    tags: tags
  }
  dependsOn: [
    privateDnsZoneVnetLink
  ]
}

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

module adf 'adf.bicep' = {
  name: 'AdfDeploy'
  scope: resourceGroup()
  params: {
    location: location
    azureDataFactoryName: azureDataFactoryName
    keyVaultName: keyVault.outputs.outKeyVaultName
    storageAccountName: storage.outputs.outStorageAccountName
    sqlServerName: sql.outputs.outSqlServerName
    sqlDatabaseName: sql.outputs.outSqlDatabaseName
    mpeStorageName: mpeStorageName
    mpeKeyVaultName: mpeKeyvaultName
    mpeSqlServerName: mpeSqlServerName
    lsStorageName: lsStorageName
    lsKeyVaultName: lsKeyvaultName
    lsSqlDatabaseName: lsSqlDatabaseName
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
  }
  dependsOn: [
    sql
    storage
    keyVault
  ]
}

output outVirtualNetworkName string = network.outputs.outVnetName
output outPrivateEndpointSubnetName string = network.outputs.outPrivateEndpointSubnetName
output outKeyvaultName string = keyVault.outputs.outKeyVaultName
output outSqlServerName string = sql.outputs.outSqlServerName
output outSqlDatabaseName string = sql.outputs.outSqlDatabaseName
output outStorageAccountName string = storage.outputs.outStorageAccountName
output outAzureDataFactoryName string = adf.outputs.outAzureDataFactoryName
output outMpeStorageAccountName string = adf.outputs.outMpeStorageAccountName
output outMpeKeyVaultName string = adf.outputs.outMpeKeyVaultName
output outMpeSqlServerName string = adf.outputs.outMpeSqlServerName
