@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Function App to provision.')
param azureFunctionAppName string

@description('Specifies the OS used for the Azure Function hosting plan.')
@allowed([
  'Windows'
  'Linux'
])
param functionPlanOS string = 'Windows'

@description('Specifies if the Azure Function app is accessible via HTTPS only.')
param httpsOnly bool = false

@description('Set to true to cause all outbound traffic to be routed into the virtual network (traffic subjet to NSGs and UDRs). Set to false to route only private (RFC1918) traffic into the virtual network.')
param vnetRouteAllEnabled bool = false

@description('Specify the Azure Resource Manager ID of the virtual network and subnet to be joined by regional vnet integration.')
param virtualNetworkSubnetId string = ''

@description('The built-in runtime stack to be used for a Linux-based Azure Function. This value is ignore if a Windows-based Azure Function hosting plan is used. Get the full list by executing the "az webapp list-runtimes --linux" command.')
param linuxRuntime string = 'DOTNET|6.0'

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

// The term "reserved" is used by ARM to indicate if the hosting plan is a Linux or Windows-based plan.
// A value of true indicated Linux, while a value of false indicates Windows.
// See https://docs.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?tabs=json#appserviceplanproperties-object.
var isReserved = (functionPlanOS == 'Linux') ? true : false

resource azureFunctionPlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: 'plan-${resourceBaseName}'
  location: location
  kind: 'elastic'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    size: 'EP1'
  }
  properties: {
    maximumElasticWorkerCount: 20
    reserved: isReserved
  }
}

resource azureFunction 'Microsoft.Web/sites@2020-12-01' = {
  name: azureFunctionAppName
  location: location
  kind: isReserved ? 'functionapp,linux' : 'functionapp'
  properties: {
    httpsOnly: httpsOnly
    serverFarmId: azureFunctionPlan.id
    reserved: isReserved

    // Specify a virtual network subnet resource ID to enable regional virtual network integration.
    virtualNetworkSubnetId: empty(virtualNetworkSubnetId) ? null : virtualNetworkSubnetId

    siteConfig: {
      vnetRouteAllEnabled: vnetRouteAllEnabled
      functionsRuntimeScaleMonitoringEnabled: true
      linuxFxVersion: isReserved ? linuxRuntime : null
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
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
    }
  }
}

output azureFunctionAppName string = azureFunction.name
output azureFunctionTenantId string = azureFunction.identity.tenantId
output azureFunctionPrincipalId string = azureFunction.identity.principalId
output azureFunctionId string = azureFunction.id
