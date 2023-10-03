param name string
param sku string
param replicaCount int
param partitionCount int
param hostingMode string
param location string
param publicNetworkAccess string
param vnetName string
param subnetName string
param privateZoneDnsId string
param storageAccountName string
param keyVaultName string
param tags object

var peGroupId = 'searchService'
var privateSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'

// https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

var requestMessage = 'Shared Private Link for Azure Cognitive Search'

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource kevVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource search 'Microsoft.Search/searchServices@2020-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
    publicNetworkAccess: publicNetworkAccess
  }
}

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (publicNetworkAccess == 'Disabled') {
  name: 'pe-search-${peGroupId}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-cog-search-${peGroupId}'
        properties: {
          privateLinkServiceId: search.id
          groupIds: [
            peGroupId
          ]
        }
      }
    ]
  }
}

resource searchPrivateDnsZonesGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (publicNetworkAccess == 'Disabled') {
  parent: searchPrivateEndpoint
  name: 'searchPrivateDnsZonesGroups'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateZoneDnsId
        }
      }
    ]
  }
}

resource roleAssignment1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', storage.name))
  properties: {
    principalId: search.identity.principalId
    roleDefinitionId: storageBlobDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
  scope: storage
}

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: kevVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: search.identity.principalId
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

resource dfsStorageSharedPrivateLink 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2022-09-01' = {
  name: 'spl-search-dfs-${peGroupId}'
  parent: search
  properties: {
    groupId: 'dfs'
    privateLinkResourceId: storage.id
    requestMessage: requestMessage
  }
}

resource blobStorageSharedPrivateLink 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2022-09-01' = {
  name: 'spl-search-blob-${peGroupId}'
  parent: search
  properties: {
    groupId: 'blob'
    privateLinkResourceId: storage.id
    requestMessage: requestMessage
  }
  dependsOn: [
    dfsStorageSharedPrivateLink
  ]
}

resource kvStorageSharedPrivateLink 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2022-09-01' = {
  name: 'spl-search-kv-${peGroupId}'
  parent: search
  properties: {
    groupId: 'vault'
    privateLinkResourceId: kevVault.id
    requestMessage: requestMessage
  }
  dependsOn: [
    blobStorageSharedPrivateLink
  ]
}
