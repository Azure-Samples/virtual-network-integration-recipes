@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param baseName string

@description('The name of the storage account.')
param storageAccountName string

@description('The name of the storage account default container.')
param defaultContainerName string

@description('The name of the virtual network for virtual network integration.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetName string

@description('The Private DNS Zone id for registering storage "dfs" private endpoints.')
param dfsPrivateDnsZoneId string

@description('The Private DNS Zone id for registering storage "blob" private endpoints.')
param blobPrivateDnsZoneId string

@description('The tags to be applied to the provisioned resources.')
param tags object

var privateSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
    allowBlobPublicAccess: false
  }
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  tags: tags
}

resource storageFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccount.name}/default/${defaultContainerName}'
  properties: {
    publicAccess: 'None'
  }
}

// Azure Storage Account "Private Endpoints" and "Private DNSZoneGroups" (A Record)
resource storagePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'pe-st-blob-${baseName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-st-blob-${baseName}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }

  resource storagePrivateEndpointBlobARecord 'privateDnsZoneGroups' = {
    name: 'blobPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: blobPrivateDnsZoneId
          }
        }
      ]
    }
  }
}

resource StoragePrivateEndpointDfs 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'pe-st-dfs-${baseName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-st-dfs-${baseName}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }

  resource StoragePrivateEndpointDfsARecord 'privateDnsZoneGroups' = {
    name: 'dfsPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: dfsPrivateDnsZoneId
          }
        }
      ]
    }
  }
}

output outStorageAccountName string = storageAccount.name
output outStorageFilesysName string = storageFileSystem.name
