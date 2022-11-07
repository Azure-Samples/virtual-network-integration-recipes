@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The id of the virtual network for virtual network integration.')
param virtualNetworkId string

@description('The id of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointId string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointName string

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure Key Vault in which to create secrets related to the Event Hub.')
param keyVaultName string = ''

@description('The name of the Key Vault secret corresponding to the Event Hub connection string.')
param keyVaultConnectionStringSecretName string = ''

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZone string = 'new'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: 'evhns-${resourceBaseName}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }

  resource eventHub 'eventhubs' = {
    name: 'evh-${resourceBaseName}'
    properties: {
      partitionCount: 1
      messageRetentionInDays: 1
    }
  }

  resource eventHubVirtualNetworkRule 'networkRuleSets' = {
    name: 'default'
    properties: {
      defaultAction: 'Deny'
      ipRules: []
      publicNetworkAccess: 'Disabled'
    }
  }
}

resource eventHubPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-evh'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: eventHubNamespace.id
        name: 'plsc-${resourceBaseName}-evh'
        properties: {
          privateLinkServiceId: eventHubNamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }

  resource eventHubPrivateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'eventHubPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: newOrExistingDnsZone == 'new' ? newEventHubPrivateDnsZone.id : existingEventHubPrivateDnsZone.id
          }
        }
      ]
    }
  }
}

// TODO: ENABLE FOR A DIFFERENT SUBSCRIPTION?!
resource existingEventHubPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.servicebus.windows.net'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newEventHubPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.servicebus.windows.net'
  location: 'Global'
}

module eventHubPrivateDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-servicebus-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newEventHubPrivateDnsZone.name : existingEventHubPrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

// Azure Bicep currently (as of February 2022) does not support a secure output mechanism for Bicep templates or modules.
// Please refer to https://github.com/Azure/bicep/issues/2163 for additional information.
// 
// The Azure Bicep linter rightfully warns that Bicep modules/templates should not output
// secrets (see https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter-rule-outputs-should-not-contain-secrets).
// 
// In an attempt to work around the lack of a secure output mechanism, this module adopts an approach to
// set the secret (the Event Hub connection string) into Key Vault.  A reference to Key Vault is optionally
// provided.  If provided, the secret is added to Key Vault, and the secret URI is set as output.  Doing so
// allows a consuming template to use the Key Vault secret (instead of directly using the Event Hub connection string).

resource eventHubNamespaceAuthRule 'Microsoft.EventHub/namespaces/authorizationRules@2021-11-01' existing = {
  name: 'evhns-${resourceBaseName}/RootManageSharedAccessKey'
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if (!empty(keyVaultName) && !empty(keyVaultConnectionStringSecretName)) {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = if (!empty(keyVaultName) && !empty(keyVaultConnectionStringSecretName)) {
  name: keyVaultConnectionStringSecretName
  parent: keyVault
  properties: {
    value: eventHubNamespaceAuthRule.listKeys().primaryConnectionString
  }
}

output eventHubNamespaceName string = eventHubNamespace.name
output eventHubName string = eventHubNamespace::eventHub.name

output eventHubConnectionStringSecretUriWithVersion string = secret.properties.secretUriWithVersion
