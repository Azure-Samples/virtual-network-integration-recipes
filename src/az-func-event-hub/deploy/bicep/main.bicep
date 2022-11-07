@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The IP address prefix for the virtual network')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('The IP address prefix for the virtual network subnet used for App Service integration.')
param virtualNetworkAppServiceIntegrationSubnetAddressPrefix string = '10.1.1.0/24'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param virtualNetworkPrivateEndpointSubnetAddressPrefix string = '10.1.2.0/24'

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZones string = 'new'

// Ensure that a user-provided value is lowercase.
var baseName = empty(resourceBaseName) ? toLower(uniqueString(resourceGroup().id)) : toLower(resourceBaseName)

var vnetName = 'vnet-${baseName}'
var subnetAppServiceIntName = 'snet-${baseName}-ase'
var subnetPrivateEndpointName = 'snet-${baseName}-pe'
var fileShareName = 'fileshare'
var keyVaultName = 'kv-${baseName}'
var azureFunctionAppName = 'func-${baseName}'

module network '../../../common/infrastructure/bicep/network.bicep' = {
  name: 'networkDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    vnetAddressPrefix: virtualNetworkAddressPrefix
    subnetAppServiceIntAddressPrefix: virtualNetworkAppServiceIntegrationSubnetAddressPrefix
    subnetPrivateEndpointAddressPrefix: virtualNetworkPrivateEndpointSubnetAddressPrefix
    virtualNetworkName: vnetName
    subnetAppServiceIntName: subnetAppServiceIntName
    subnetPrivateEndpointName: subnetPrivateEndpointName
    subnetAppServiceIntServiceEndpointTypes: [
      'Microsoft.EventHub'
    ]
  }
}

module eventHub '../../../common/infrastructure/bicep/private-event-hub.bicep' = {
  name: 'eventHubDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    virtualNetworkId: network.outputs.virtualNetworkId
    subnetPrivateEndpointId: network.outputs.subnetPrivateEndpointId
    subnetPrivateEndpointName: subnetPrivateEndpointName
    keyVaultName: keyVault.outputs.keyVaultName
    keyVaultConnectionStringSecretName: 'kvs-${baseName}-evhconn'
    dnsZoneResourceGroupName: dnsZoneResourceGroupName
    newOrExistingDnsZone: newOrExistingDnsZones
  }
}

module applicationInsights '../../../common/infrastructure/bicep/app-insights.bicep' = {
  name: 'appInsightsDeploy'
  params: {
    location: location
    resourceBaseName: baseName
  }
}

module storageAccount '../../../common/infrastructure/bicep/private-storage.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    subnetPrivateEndpointId: network.outputs.subnetPrivateEndpointId
    subnetPrivateEndpointName: subnetPrivateEndpointName
    fileShareName: fileShareName
    virtualNetworkId: network.outputs.virtualNetworkId
    keyVaultConnectionStringSecretName: 'kvs-${baseName}-stconn'
    keyVaultName: keyVault.outputs.keyVaultName
    dnsZoneResourceGroupName: dnsZoneResourceGroupName
    newOrExistingDnsZone: newOrExistingDnsZones
  }
}

module keyVault '../../../common/infrastructure/bicep/private-key-vault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    virtualNetworkId: network.outputs.virtualNetworkId
    subnetPrivateEndpointId: network.outputs.subnetPrivateEndpointId
    subnetPrivateEndpointName: subnetPrivateEndpointName
    dnsZoneResourceGroupName: dnsZoneResourceGroupName
    newOrExistingDnsZone: newOrExistingDnsZones
    keyVaultName: keyVaultName
    keyVaultAccessPolicies: [
      {
        tenantId: azureFunctions.outputs.azureFunctionTenantId
        objectId: azureFunctions.outputs.azureFunctionPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

module azureFunctions '../../../common/infrastructure/bicep/azure-functions.bicep' = {
  name: 'azureFunctionsDeploy'
  params: {
    location: location
    virtualNetworkSubnetId: network.outputs.subnetAppServiceIntId
    vnetRouteAllEnabled: true
    resourceBaseName: baseName
    azureFunctionAppName: azureFunctionAppName
  }
}

resource appInsightsInstrumentationKeyKeyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/kvs-${baseName}-aikey'
  dependsOn: [
    keyVault
  ]
  properties: {
    value: applicationInsights.outputs.instrumentationKey
  }
}

resource additionalAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  name: '${azureFunctionAppName}/appsettings'
  dependsOn: [
    keyVault
    azureFunctions
  ]
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageAccount.outputs.storageAccountConnectionStringSecretUriWithVersion})'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeyKeyVaultSecret.properties.secretUriWithVersion})'
    EventHubConnectionString: '@Microsoft.KeyVault(SecretUri=${eventHub.outputs.eventHubConnectionStringSecretUriWithVersion})'
    EventHubName: eventHub.outputs.eventHubName
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageAccount.outputs.storageAccountConnectionStringSecretUriWithVersion})'
    WEBSITE_CONTENTSHARE: fileShareName
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTOVERVNET: '1'
    WEBSITE_SKIP_CONTENTSHARE_VALIDATION: '1'
    'AzureWebJobs.Tester.Disabled': true
  }
}

output functionAppName string = azureFunctions.outputs.azureFunctionAppName
output virtualNetworkName string = network.outputs.virtualNetworkName
