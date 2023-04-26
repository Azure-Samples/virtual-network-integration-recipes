@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the storage account.')
param storageAccountName string

@description('The name of the storage account default container.')
param defaultContainerName string

@description('The tags to be applied to the provisioned resources.')
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
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

  resource storageBlobService 'blobServices@2022-09-01' = {
    name: 'default'

    resource storageFileSystem 'containers@2022-09-01' = {
      name: defaultContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

output outStorageAccountResourceId string = storageAccount.id
output outStorageAccountName string = storageAccount.name
output outStorageFilesysName string = defaultContainerName
