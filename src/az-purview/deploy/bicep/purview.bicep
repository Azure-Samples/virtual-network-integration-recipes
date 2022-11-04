@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param baseName string

@description('The name of the virtual network.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetName string

@description('The name of the Azure Purview account.')
param purviewAccountName string

@description('The name of the Azure Purview storage account.')
param storageAccountName string

@description('The name of the key vault.')
param keyVaultName string

@description('The Private DNS Zone id for registering purview namespace private endpoints.')
param namespacePrivateDnsZoneId string

@description('The Private DNS Zone id for registering purview portal private endpoints.')
param portalPrivateDnsZoneId string

@description('The Private DNS Zone id for registering purview account endpoints.')
param accountPrivateDnsZoneId string

@description('The Private DNS Zone id for registering purview blob storage private endpoints.')
param blobPrivateDnsZoneId string

@description('The Private DNS Zone id for registering purview queue storage private endpoints.')
param queuePrivateDnsZoneId string

var purviewSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
var purviewEventhubNs = purview.properties.managedResources.eventHubNamespace
var purviewStor = purview.properties.managedResources.storageAccount
// https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var roleStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

var purviewPrivateEndpointNames = [
  'account'
  'portal'
  'namespace'
  'blob'
  'queue'
]

var mapPurviewPrivateEndpointToDns = {
  account: {
    dnsName: accountPrivateDnsZoneId
  }
  portal: {
    dnsName: portalPrivateDnsZoneId
  }
  namespace: {
    dnsName: namespacePrivateDnsZoneId
  }
  blob: {
    dnsName: blobPrivateDnsZoneId
  }
  queue: {
    dnsName: queuePrivateDnsZoneId
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

// Please note the usage of feature "#disable-next-line" to suppress warning "BCP073".
// BCP073: The property "friendlyName" is read-only. Expressions cannot be assigned to read-only properties.
resource purview 'Microsoft.Purview/accounts@2021-07-01' = {
  name:purviewAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    cloudConnectors: {}
    #disable-next-line BCP073
    friendlyName: purviewAccountName
    publicNetworkAccess: 'Disabled'
    managedResourceGroupName: 'mrg-pview-${baseName}'
  }
}

// Azure Purview "Private Endpoints" and "Private DNSZoneGroups" (A Record)
resource purviewPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = [for peName in purviewPrivateEndpointNames: {
  name: 'pe-pview-${peName}-${baseName}'
  location: location
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: 'plsc-pview-${peName}-${baseName}'
        properties: {
          groupIds: [
            '${peName}'
          ]
          privateLinkServiceId: (peName == 'namespace') ? purviewEventhubNs: (peName == 'blob' || peName == 'queue') ? purviewStor : purview.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: purviewSubnetId
    }
  }
}]

resource purviewDnsZonesGroups'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = [for (peName, index) in purviewPrivateEndpointNames: {
  parent: purviewPrivateEndpoint[index]
  name: 'pviewPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: mapPurviewPrivateEndpointToDns[peName].dnsName
        }
      }
    ]
  }
}]

// Grant Storage access to Purview MSI
// Please note the usage of feature "#disable-next-line" to suppress warning "BCP081".
// BCP081: Resource type "Microsoft.Authorization/roleAssignments@2021-04-01-preview" does not have types available.
#disable-next-line BCP081
resource storageRoleAssignment1 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', storage.name))
  properties: {
    principalId: purview.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleStorageBlobDataContributor)
    principalType: 'ServicePrincipal'
  }
  scope: storage
}

// Grant Key Vault access to Purview MSI
resource keyvaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyvault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: purview.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output outPurviewAccountName string = purview.name
output outPurviewCatalogUri  string = purview.properties.endpoints.catalog
