@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The IP address prefix for the virtual network')
param virtualNetworkAddressPrefix string = '10.3.0.0/16'

@description('The IP address prefix for the virtual network subnet used for App Service integration.')
param virtualNetworkAppServiceIntegrationSubnetAddressPrefix string = '10.3.1.0/24'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param virtualNetworkPrivateEndpointSubnetAddressPrefix string = '10.3.2.0/24'

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
    virtualNetworkName: vnetName
    vnetAddressPrefix: virtualNetworkAddressPrefix
    subnetAppServiceIntAddressPrefix: virtualNetworkAppServiceIntegrationSubnetAddressPrefix
    subnetPrivateEndpointAddressPrefix: virtualNetworkPrivateEndpointSubnetAddressPrefix
    subnetAppServiceIntName: subnetAppServiceIntName
    subnetPrivateEndpointName: subnetPrivateEndpointName
    subnetAppServiceIntServiceEndpointTypes: []
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
        tenantId: azureFunction.outputs.azureFunctionTenantId
        objectId: azureFunction.outputs.azureFunctionPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

module azureFunction '../../../common/infrastructure/bicep/azure-functions.bicep' = {
  name: 'azureFunctionsDeploy'
  params: {
    location: location
    virtualNetworkSubnetId: network.outputs.subnetAppServiceIntId
    vnetRouteAllEnabled: true
    resourceBaseName: baseName
    azureFunctionAppName: azureFunctionAppName

    // NOTE: The 'functionPlanOS' and 'linuxRuntime' parameters are only needed for a Linux application.
    functionPlanOS: 'Linux'
    linuxRuntime: 'PYTHON|3.8'
  }
}

resource additionalAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  name: '${azureFunctionAppName}/appsettings'
  dependsOn: [
    keyVault
    azureFunction
  ]
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageAccount.outputs.storageAccountConnectionStringSecretUriWithVersion})'
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeyKeyVaultSecret.properties.secretUriWithVersion})'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'python'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageAccount.outputs.storageAccountConnectionStringSecretUriWithVersion})'
    WEBSITE_CONTENTOVERVNET: '1'
    WEBSITE_CONTENTSHARE: fileShareName
    WEBSITE_SKIP_CONTENTSHARE_VALIDATION: '1'
  }
}

resource functionPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${baseName}-sites'
  location: location
  properties: {
    subnet: {
      id: network.outputs.subnetPrivateEndpointId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${baseName}-sites'
        properties: {
          privateLinkServiceId: azureFunction.outputs.azureFunctionId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }

  resource zoneGroup 'privateDnsZoneGroups' = {
    name: 'functionPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: newOrExistingDnsZones == 'new' ? newFunctionPrivateDnsZone.id : existingFunctionPrivateDnsZone.id //existingFunctionPrivateDnsZone.id
          }
        }
      ]
    }
  }
}

// TODO: ENABLE FOR A DIFFERENT SUBSCRIPTION?!
resource existingFunctionPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZones == 'existing') {
  name: 'privatelink.azurewebsites.net'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newFunctionPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZones == 'new') {
  name: 'privatelink.azurewebsites.net'
  location: 'Global'
}

module functionPrivateDnsZoneLink '../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-function-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZones == 'new' ? newFunctionPrivateDnsZone.name : existingFunctionPrivateDnsZone.name //existingFunctionPrivateDnsZone.name
    vnetId: network.outputs.virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
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

output functionAppName string = azureFunction.outputs.azureFunctionAppName
output virtualNetworkName string = network.outputs.virtualNetworkName
