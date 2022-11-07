@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Web App to provision.')
param webAppName string

@description('Azure App Service SKU.')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P1v3'
  'P2v2'
  'P2v3'
  'P3v2'
  'P3v3'
])
param skuName string = 'P1v3'

@description('Specify the Azure Resource Manager ID of the virtual network and subnet to be joined by regional vnet integration.')
param virtualNetworkSubnetId string = ''

@description('Set to true to cause all outbound traffic to be routed into the virtual network (traffic subjet to NSGs and UDRs). Set to false to route only private (RFC1918) traffic into the virtual network.')
param vnetRouteAllEnabled bool = false

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

resource webAppPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: 'plan-${resourceBaseName}'
  location: location
  kind: 'app'
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {}
}

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    httpsOnly: true
    serverFarmId: webAppPlan.id

    // Specify a virtual network subnet resource ID to enable regional virtual network integration.
    virtualNetworkSubnetId: empty(virtualNetworkSubnetId) ? null : virtualNetworkSubnetId
    siteConfig: {
      vnetRouteAllEnabled: vnetRouteAllEnabled
    }
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource config 'config' = {
    name: 'web'
    properties: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      remoteDebuggingEnabled: false
    }
  }
}

output webAppName string = webApp.name
output webAppTenantId string = webApp.identity.tenantId
output webAppPrincipalId string = webApp.identity.principalId
output webAppId string = webApp.id
output webAppPlanName string = webAppPlan.name
output defaultHostname string = webApp.properties.defaultHostName
