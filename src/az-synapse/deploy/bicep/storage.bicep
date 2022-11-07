@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
param baseName string

@description('The array with names of the synapse default and application storage accounts.')
param arrStorageAccountName array

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
param tags object = {
  baseName : baseName
}

var privateSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' =  [for stName in arrStorageAccountName: {
  name: stName
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
    publicNetworkAccess: 'Disabled'
  }
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  tags: tags
}]

resource storageFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = [for (stName, index)  in arrStorageAccountName: {
  name: '${storageAccount[index].name}/default/${defaultContainerName}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}]

// Azure Storage Account "Private Endpoints" and "Private DNSZoneGroups" (A Record)
resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2021-03-01' = [for (stName, index) in arrStorageAccountName: {
  name: 'pe-st-blob${index}-${baseName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-st-blob${stName}-${baseName}'
        properties: {
          privateLinkServiceId: storageAccount[index].id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}]

resource dnsZonesGroupsBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = [for (stName, index) in arrStorageAccountName: {
  parent: privateEndpointBlob[index]
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
}]

resource privateEndpointDfs 'Microsoft.Network/privateEndpoints@2021-03-01' = [for (stName, index) in arrStorageAccountName: {
  name: 'pe-st-dfs${index}-${baseName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-st-dfs${index}-${baseName}'
        properties: {
          privateLinkServiceId: storageAccount[index].id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}]

resource dnsZonesGroupsDfs 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = [for (stName, index) in arrStorageAccountName: {
  parent: privateEndpointDfs[index]
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
}]

output outSynStorageAccountName string = storageAccount[0].name
output outSynStorageFilesysName string = storageFileSystem[0].name

output outMainStorageAccountName string = storageAccount[1].name
output outMainStorageFilesysName string = storageFileSystem[1].name
