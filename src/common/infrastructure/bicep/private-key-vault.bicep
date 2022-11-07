@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The id of the virtual network for virtual network integration.')
param virtualNetworkId string

@description('The id of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointId string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointName string

@description('Tenant Id of the key vault resource.')
param keyVaultTenantId string = subscription().tenantId

@description('Name of the key vault resource.')
param keyVaultName string

@description('Sets the identities which have access to the key vault. See https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies?tabs=bicep')
param keyVaultAccessPolicies array

@description('The default action when no rule from networkAcls.ipRules and from networkAcls.virtualNetworkRules match.')
@allowed([
  'Deny'
  'Allow'
])
param keyVaultNetworkAclsDefaultAction string = 'Deny'

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZone string = 'new'

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: keyVaultTenantId
    accessPolicies: keyVaultAccessPolicies
    networkAcls: {
      bypass: 'None'
      defaultAction: keyVaultNetworkAclsDefaultAction
      virtualNetworkRules: []
    }
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-kv'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: keyVault.id
        name: 'plsc-${resourceBaseName}-kv'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }

  resource keyVaultPrivateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'keyVaultPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: newOrExistingDnsZone == 'new' ? newKeyVaultPrivateDnsZone.id : existingKeyVaultPrivateDnsZone.id
          }
        }
      ]
    }
  }
}

resource existingKeyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.vaultcore.azure.net'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newKeyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.vaultcore.azure.net'
  location: 'Global'
}

module keyVaultPrivateDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-keyvault-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newKeyVaultPrivateDnsZone.name : existingKeyVaultPrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

output keyVaultName string = keyVault.name
