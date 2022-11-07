@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The IP address prefix for the virtual network')
param virtualNetworkAddressPrefix string = '10.5.0.0/16'

@description('The IP address prefix for the virtual network subnet used for App Service integration.')
param virtualNetworkAppServiceIntegrationSubnetAddressPrefix string = '10.5.1.0/24'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param virtualNetworkPrivateEndpointSubnetAddressPrefix string = '10.5.2.0/24'

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
var keyVaultName = 'kv-${baseName}'
var webAppName = 'app-${baseName}'

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
        tenantId: webApp.outputs.webAppTenantId
        objectId: webApp.outputs.webAppPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

module webApp '../../../common/infrastructure/bicep/web-app.bicep' = {
  name: 'webAppDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    webAppName: webAppName
    virtualNetworkSubnetId: network.outputs.subnetAppServiceIntId
    vnetRouteAllEnabled: true
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  dependsOn: [
    webApp
  ]
  name: '${webAppName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeyKeyVaultSecret.properties.secretUri})'
  }
}

resource webAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
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
          privateLinkServiceId: webApp.outputs.webAppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource existingWebAppPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZones == 'existing') {
  name: 'privatelink.azurewebsites.net'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newWebAppPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZones == 'new') {
  name: 'privatelink.azurewebsites.net'
  location: 'Global'
}

module webAppPrivateDnsZoneLink '../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-webapp-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZones == 'new' ? newWebAppPrivateDnsZone.name : existingWebAppPrivateDnsZone.name
    vnetId: network.outputs.virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

resource webAppPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: webAppPrivateEndpoint
  name: 'webAppPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: newOrExistingDnsZones == 'new' ? newWebAppPrivateDnsZone.id : existingWebAppPrivateDnsZone.id
        }
      }
    ]
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

output webAppName string = webApp.outputs.webAppName
output webAppPlanName string = webApp.outputs.webAppPlanName
output virtualNetworkName string = network.outputs.virtualNetworkName
