targetScope = 'subscription'

@description('The Azure region for the deployment of specified resources.')
param location string = deployment().location

@description('The base name to be appended to all provisioned resources.')
@minLength(3)
@maxLength(13)
param resourceBaseName string = uniqueString(subscription().subscriptionId)

@description('The name of the resource group to deploy most of the recipe resources.')
param resourceGroupName string = 'rg-adbrcpi-bicep'

// Resource group to create ADB Private DNS Zone to support Back-end private link connection
@description('The name of the resource group for creating databricks private DNS Zone to support Back-end private link connection.')
param adbPrivateDnsZoneResourceGroupName string = '${resourceGroupName}-dns'

@description('The IP address prefix for the Azure Databricks workspace virtual network')
param workspaceVnetAddressPrefix string = '10.11.0.0/16'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param workspaceBackendPrivateEndpointSubnetAddressPrefix string = '10.11.0.0/24'

@description('The IP address prefix for the container subnet of Azure Databricks.')
param workspaceContainerSubnetAddressPrefix string = '10.11.1.0/24'

@description('The IP address prefix for the host subnet of Azure Databricks.')
param workspaceHostSubnetAddressPrefix string = '10.11.2.0/24'

@description('The IP address prefix for the Transit virtual network')
param transitVnetAddressPrefix string = '10.12.0.0/16'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param transitPrivateEndpointSubnetAddressPrefix string = '10.12.0.0/24'

@description('The IP address prefix for the virtual network subnet used for AzureBastionSubnet subnet.')
param transitBastionSubnetAddressPrefix string =  '10.12.1.0/24'

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZones string = 'new'

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroupName

@description('The ID of the Azure subscription containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneSubscriptionId string = subscription().subscriptionId

@description('Parameter to specify the preference about Azure Databricks web authentication workspace.')
@allowed([
  'createNew'
  'useNew'
  'useExisting'
])
param webAuthWorkspacePreference string = 'createNew'

@description('The IP address prefix for the VNet if "webAuthWorkspacePreference" is set to "CreateNew".')
param webAuthWorkspaceVnetAddressPrefix string = '10.179.0.0/16'

@description('The IP address prefix for the container subnet if "webAuthWorkspacePreference" is set to "CreateNew".')
param webAuthWorkspaceContainerSubnetAddressPrefix string = '10.179.0.0/24'

@description('The IP address prefix for the host subnet if "webAuthWorkspacePreference" is set to "CreateNew".')
param webAuthWorkspaceHostSubnetAddressPrefix string = '10.179.1.0/24'

@description('The resource id of the Azure Databricks workspace to be used for web authentication if "webAuthWorkspacePreference" is set to "useExisting".')
param existingWebAuthWorkspaceId string = ''

// General/Common variables
// Ensure that a user-provided value is lowercase.
var baseName = toLower(resourceBaseName)
var tags = {
  baseName : baseName
}

// Private DNS Zone variables for workspace VNet
var workspacePrivateDnsZoneNames = [
  'privatelink.azuredatabricks.net'
  'privatelink.dfs.${environment().suffixes.storage}'
]

// Private DNS Zone variables for transit VNet
var transitPrivateDnsZoneNames = [
  'privatelink.vaultcore.azure.net'
  'privatelink.azuredatabricks.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.dfs.${environment().suffixes.storage}'
]


// Defining Private DNS Zones resource group and subscription id
var calcDnsZoneResourceGroupName = (newOrExistingDnsZones == 'new') ? resourceBaseName : dnsZoneResourceGroupName
var calcDnsZoneSubscriptionId = (newOrExistingDnsZones == 'new') ? subscription().subscriptionId : dnsZoneSubscriptionId

// Getting the Ids for existing or newly created Private DNS Zones
var databricksWorkspacePrivateDnsZoneId = resourceId(subscription().subscriptionId, adbPrivateDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
var dfsWorkspacePrivateDnsZoneId = resourceId(subscription().subscriptionId, adbPrivateDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')

var keyVaultTransitPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
var databricksTransitPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
var dfsTransitPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.dfs.${environment().suffixes.storage}')
var blobTransitPrivateDnsZoneId = resourceId(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.${environment().suffixes.storage}')

// Networking related variables
var workspaceVnetName = 'vnet-databricks-${baseName}'
var worspacePrivatenEndpointSubnetName = 'snet-pe-${baseName}'
var workspaceHostSubnetName = 'snet-host-${baseName}'
var workspaceContainerSubnetName = 'snet-container-${baseName}'
var workspaceNetworkSecurityGroupName = 'nsg-${baseName}'
var transitVnetName = 'vnet-transit-${baseName}'
var transitAzureBastionSubnetName = 'AzureBastionSubnet'
var transitPrivateEndpointSubnetName = 'snet-pe-${baseName}'
var webAuthWorkspaceVnetName = 'vnet-databricks-webauth-${baseName}'
var webAuthWorkspaceHostSubnetName = 'snet-host-${baseName}'
var webAuthWorkspaceContainerSubnetName = 'snet-container-${baseName}'
var webAuthWorkspaceNetworkSecurityGroupName = 'nsg-databricks-webauth-${baseName}'

// Azure Key Vault related variables
var keyVaultName = 'kv-${baseName}'
var keyVaultPrivateEndpointName = 'pe-kv-vault-${baseName}'
var keyVaultPrivateEndpointDnsZoneGroupName = 'dzg-kv-vault-${baseName}'

// Azure Storage account related variables
var storageAccountName = 'st1${baseName}'
var defaultContainerName = 'container001'
var storageDfsPrivateEndpointName = 'pe-st-dfs-${baseName}'
var storageBlobPrivateEndpointName = 'pe-st-blob-${baseName}'
var storageDfsPrivateEndpointDnsZoneGroupName = 'dzg-st-dfs-${baseName}'
var storageBlobPrivateEndpointDnsZoneGroupName = 'dzg-st-blob-${baseName}'

// Azure Databricks related variables
var databricksMainWorkspaceName = 'adb-main-${baseName}'
var databricksMainWorkspaceManagedResourceGroupName = 'mrg-${databricksMainWorkspaceName}'
var databricksWebAuthWorkspaceName = 'adb-webauth-DO-NOT-DELETE-${location}'
var databricksWebAuthManagedResourceGroupName = 'mrg-${databricksWebAuthWorkspaceName}'
var adbBackendApiPrivateEndpointName = 'pe-adb-backend-api-${baseName}'
var adbFrontendApiPrivateEndpointName = 'pe-adb-frontend-api-${baseName}'
var adbBrowserAuthPrivateEndpointName = 'pe-adb-browser-auth-${baseName}'
var adbBackendApiPrivateEndpointDnsZoneGroupName = 'dzg-adb-backend-api-${baseName}'
var adbFrontendApiPrivateEndpointDnsZoneGroupName = 'dzg-adb-frontend-api-${baseName}'
var adbBrowserAuthPrivateEndpointDnsZoneGroupName = 'dzg-adb-browser-auth-${baseName}'

resource rgMain 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

resource rgDatabricksDnsZone 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: adbPrivateDnsZoneResourceGroupName
  location: location
  tags: tags
}

module workspacePrivateDnsZone '../../../common/infrastructure/bicep/private-dns-zones.bicep' = {
  name: 'workspacePrivateDnsZoneDeploy'
  scope: rgDatabricksDnsZone
  params: {
    privateDnsNames: workspacePrivateDnsZoneNames
    tags: tags
  }
  dependsOn: [
    rgMain
  ]
}

module transitPrivateDnsZone '../../../common/infrastructure/bicep/private-dns-zones.bicep' = if (newOrExistingDnsZones == 'new') {
  name: 'transitDnsZoneDeploy'
  scope: rgMain
  params: {
    privateDnsNames: transitPrivateDnsZoneNames
    tags: tags
  }
}

module network 'network.bicep' = {
  name: 'networkDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    workspaceVnetName: workspaceVnetName
    workspaceVnetAddressPrefix: workspaceVnetAddressPrefix
    workspaceHostSubnetName: workspaceHostSubnetName
    workspaceHostSubnetAddressPrefix: workspaceHostSubnetAddressPrefix
    workspaceContainerSubnetName: workspaceContainerSubnetName
    workspaceContainerSubnetAddressPrefix: workspaceContainerSubnetAddressPrefix
    workspaceBackendPrivateEndpointSubnetName: worspacePrivatenEndpointSubnetName
    workspaceBackendPrivateEndpointSubnetAddressPrefix: workspaceBackendPrivateEndpointSubnetAddressPrefix
    workspaceNetworkSecurityGroupName: workspaceNetworkSecurityGroupName
    transitVnetName: transitVnetName
    transitVnetAddressPrefix: transitVnetAddressPrefix
    transitPrivateEndpointSubnetName: transitPrivateEndpointSubnetName
    transitPrivateEndpointSubnetAddressPrefix: transitPrivateEndpointSubnetAddressPrefix
    transitBastionSubnetName: transitAzureBastionSubnetName
    transitBastionSubnetAddressPrefix: transitBastionSubnetAddressPrefix
    tags: tags
  }
}

module privateDnsZoneWorkspaceVnetLink'../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = [ for (names, i) in workspacePrivateDnsZoneNames: {
  name: 'privateDnsZoneWorkspaceVnetLinkDeploy-${i}'
  scope: rgDatabricksDnsZone
  params: {
    privateDnsZoneName: names
    vnetId: network.outputs.outWorkspaceVnetId
    vnetLinkName: '${network.outputs.outWorkspaceVnetName}-link'
  }
  dependsOn: [
    workspacePrivateDnsZone
    network
  ]
}]

module privateDnsZoneTransitVnetLink '../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = [ for (names, i) in transitPrivateDnsZoneNames: {
  name: 'privateDnsZoneTransitVnetLinkDeploy-${i}'
  scope: resourceGroup(calcDnsZoneSubscriptionId, calcDnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: names
    vnetId: network.outputs.outTransitVnetId
    vnetLinkName: '${network.outputs.outTransitVnetName}-link'
  }
  dependsOn: [
    transitPrivateDnsZone
    network
  ]
}]

module keyVault 'key-vault.bicep' = {
  name: 'keyVaultDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    keyVaultName: keyVaultName
    tags: tags
  }
}

module storage 'storage.bicep' = {
  name: 'storageDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    storageAccountName: storageAccountName
    defaultContainerName: defaultContainerName
    tags: tags
  }
}

module adb 'databricks-main.bicep' = {
  name: 'databricksDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    databricksWorkspaceName: databricksMainWorkspaceName
    managedResourceGroupName: databricksMainWorkspaceManagedResourceGroupName
    vnetName: network.outputs.outWorkspaceVnetName
    hostSubnetName: network.outputs.outWorkspaceHostSubnetName
    containerSubnetName: network.outputs.outWorkspaceContainerSubnetName
    tags: tags
  }
}

module adbWebAuth 'databricks-web-auth.bicep' = if (webAuthWorkspacePreference == 'createNew') {
  name: 'databricksWebAuthDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    databricksWorkspaceName: databricksWebAuthWorkspaceName
    managedResourceGroupName: databricksWebAuthManagedResourceGroupName
    vnetName: webAuthWorkspaceVnetName
    vnetAddressPrefix: webAuthWorkspaceVnetAddressPrefix
    hostSubnetName: webAuthWorkspaceHostSubnetName
    hostSubnetAddressPrefix: webAuthWorkspaceContainerSubnetAddressPrefix
    containerSubnetName: webAuthWorkspaceContainerSubnetName
    containerSubnetAddressPrefix: webAuthWorkspaceHostSubnetAddressPrefix
    networkSecurityGroupName: webAuthWorkspaceNetworkSecurityGroupName
    tags: tags
  }
}

module adbBackendApiPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'adbBackendApiPrivateEndpointDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: adbBackendApiPrivateEndpointName
    privateEndpointDnsZoneGroupName: adbBackendApiPrivateEndpointDnsZoneGroupName
    privateLinkServiceId: adb.outputs.outDatabricksWorkspaceId
    vnetName: network.outputs.outWorkspaceVnetName
    peSubnetName: network.outputs.outWorkspacePrivateEndpointSubnetName
    subResourceName: 'databricks_ui_api'
    privateDnsZoneId: databricksWorkspacePrivateDnsZoneId
  }
}

module adbFrontendApiPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'adbFrontendApiPrivateEndpointDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: adbFrontendApiPrivateEndpointName
    privateEndpointDnsZoneGroupName: adbFrontendApiPrivateEndpointDnsZoneGroupName
    privateLinkServiceId: adb.outputs.outDatabricksWorkspaceId
    vnetName: network.outputs.outTransitVnetName
    peSubnetName: network.outputs.outTransitPrivateEndpointSubnetName
    subResourceName: 'databricks_ui_api'
    privateDnsZoneId: databricksTransitPrivateDnsZoneId
  }
  dependsOn: [
    adbBackendApiPrivateEndpoint
  ]
}

module adbBrowserAuthPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'adbBrowserAuthPrivateEndpointDeploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: adbBrowserAuthPrivateEndpointName
    privateEndpointDnsZoneGroupName: adbBrowserAuthPrivateEndpointDnsZoneGroupName
    privateLinkServiceId: (webAuthWorkspacePreference == 'createNew') ? adbWebAuth.outputs.outDatabricksWorkspaceId : (webAuthWorkspacePreference == 'useExisting') ? existingWebAuthWorkspaceId : adb.outputs.outDatabricksWorkspaceId
    vnetName: network.outputs.outTransitVnetName
    peSubnetName: network.outputs.outTransitPrivateEndpointSubnetName
    subResourceName: 'browser_authentication'
    privateDnsZoneId: databricksTransitPrivateDnsZoneId
  }
}

// Private Endpoint (dfs) to access ADLS Gen2 Storage account from Workspace VNet
module storageDfsPrivateEndpoint1 'private-endpoint.bicep' = {
  name: 'storageDfsPrivateEndpoint1Deploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: '${storageDfsPrivateEndpointName}-workspace'
    privateEndpointDnsZoneGroupName: '${storageDfsPrivateEndpointDnsZoneGroupName}-workspace'
    privateLinkServiceId: storage.outputs.outStorageAccountResourceId
    vnetName: network.outputs.outWorkspaceVnetName
    peSubnetName: network.outputs.outWorkspacePrivateEndpointSubnetName
    subResourceName: 'dfs'
    privateDnsZoneId: dfsWorkspacePrivateDnsZoneId
  }
}

// Private Endpoints for Azure Storage/Azure KeyVault for User access from transit VNet
module storageBlobPrivateEndpoint2 'private-endpoint.bicep' = {
  name: 'storageBlobPrivateEndpoint2Deploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: '${storageBlobPrivateEndpointName}-transit'
    privateEndpointDnsZoneGroupName: '${storageBlobPrivateEndpointDnsZoneGroupName}-transit'
    privateLinkServiceId: storage.outputs.outStorageAccountResourceId
    vnetName: network.outputs.outTransitVnetName
    peSubnetName: network.outputs.outTransitPrivateEndpointSubnetName
    subResourceName: 'blob'
    privateDnsZoneId: blobTransitPrivateDnsZoneId
  }
}

module storageDfsPrivateEndpoint2 'private-endpoint.bicep' = {
  name: 'storageDfsPrivateEndpoint2Deploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: '${storageDfsPrivateEndpointName}-transit'
    privateEndpointDnsZoneGroupName: '${storageDfsPrivateEndpointDnsZoneGroupName}-transit'
    privateLinkServiceId: storage.outputs.outStorageAccountResourceId
    vnetName: network.outputs.outTransitVnetName
    peSubnetName: network.outputs.outTransitPrivateEndpointSubnetName
    subResourceName: 'dfs'
    privateDnsZoneId: dfsTransitPrivateDnsZoneId
  }
}

module keyVaultPrivateEndpoint2 'private-endpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint2Deploy'
  scope: rgMain
  params: {
    location: rgMain.location
    privateEndpointName: '${keyVaultPrivateEndpointName}-transit'
    privateEndpointDnsZoneGroupName: '${keyVaultPrivateEndpointDnsZoneGroupName}-transit'
    privateLinkServiceId: keyVault.outputs.outKeyVaultResourceId
    vnetName: network.outputs.outTransitVnetName
    peSubnetName: network.outputs.outTransitPrivateEndpointSubnetName
    subResourceName: 'vault'
    privateDnsZoneId: keyVaultTransitPrivateDnsZoneId
  }
}

output outWorkspaceVirtualNetworkName string = network.outputs.outWorkspaceVnetName
output outTransitPrivateEndpointSubnetName string = network.outputs.outTransitPrivateEndpointSubnetName
output outKeyVaultName string = keyVault.outputs.outKeyVaultName
output outStorageAccountName string = storage.outputs.outStorageAccountName
output outStorageFilesysName string = storage.outputs.outStorageFilesysName
output outDatabricksWorkspaceName string = adb.outputs.outDatabricksWorkspaceName
output outDatabricksStorageAccountName string = adb.outputs.outDatabricksStorageAccountName
