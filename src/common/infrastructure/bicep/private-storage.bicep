@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The id of the virtual network for virtual network integration.')
param virtualNetworkId string

@description('The id of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointId string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetPrivateEndpointName string

@description('The name of the storage account file share.')
param fileShareName string

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure Key Vault in which to create secrets related to the Azure Storage account.')
param keyVaultName string = ''

@description('The name of the Key Vault secret corresponding to the Azure Storage account connection string.')
param keyVaultConnectionStringSecretName string = ''

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZone string = 'new'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'storage${resourceBaseName}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }

  resource service 'fileServices' = {
    name: 'default'

    resource share 'shares' = {
      name: fileShareName
    }
  }
}

// -- Private Endpoints --
resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-file'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: storageAccount.id
        name: 'plsc-${resourceBaseName}-file'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-blob'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: storageAccount.id
        name: 'plsc-${resourceBaseName}-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-table'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: storageAccount.id
        name: 'plsc-${resourceBaseName}-table'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource storageQueuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${resourceBaseName}-queue'
  location: location
  properties: {
    subnet: {
      id: subnetPrivateEndpointId
      name: subnetPrivateEndpointName
    }
    privateLinkServiceConnections: [
      {
        id: storageAccount.id
        name: 'plsc-${resourceBaseName}-queue'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource existingStorageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.file.${environment().suffixes.storage}'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource existingStorageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource existingStorageTablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.table.${environment().suffixes.storage}'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource existingStorageQueuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZone == 'existing') {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newStorageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'Global'
}

resource newStorageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'Global'
}

resource newStorageTablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'Global'
}

resource newStorageQueuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZone == 'new') {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'Global'
}

// -- Private DNS Zone Links --
module storageFileDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-storage-file-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newStorageFilePrivateDnsZone.name : existingStorageFilePrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

module storageBlobDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-storage-blob-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newStorageBlobPrivateDnsZone.name : existingStorageBlobPrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

module storageTableDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-storage-table-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newStorageTablePrivateDnsZone.name : existingStorageTablePrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

module storageQueueDnsZoneLink 'dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-storage-queue-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZone == 'new' ? newStorageQueuePrivateDnsZone.name : existingStorageQueuePrivateDnsZone.name
    vnetId: virtualNetworkId
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

// -- Private DNS Zone Groups --
resource storageFilePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageFilePrivateEndpoint
  name: 'filePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: newOrExistingDnsZone == 'new' ? newStorageFilePrivateDnsZone.id : existingStorageFilePrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageBlobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageBlobPrivateEndpoint
  name: 'blobPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: newOrExistingDnsZone == 'new' ? newStorageBlobPrivateDnsZone.id : existingStorageBlobPrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageTablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageTablePrivateEndpoint
  name: 'tablePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: newOrExistingDnsZone == 'new' ? newStorageTablePrivateDnsZone.id : existingStorageTablePrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageQueuePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageQueuePrivateEndpoint
  name: 'queuePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: newOrExistingDnsZone == 'new' ? newStorageQueuePrivateDnsZone.id : existingStorageQueuePrivateDnsZone.id
        }
      }
    ]
  }
}

// Azure Bicep currently (as of February 2022) does not support a secure output mechanism for Bicep templates or modules.
// Please refer to https://github.com/Azure/bicep/issues/2163 for additional information.
// 
// The Azure Bicep linter rightfully warns that Bicep modules/templates should not output
// secrets (see https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/linter-rule-outputs-should-not-contain-secrets).
// 
// In an attempt to work around the lack of a secure output mechanism, this module adopts an approach to
// set the secret (the Azure Storage connection string) into Key Vault.  A reference to Key Vault is optionally
// provided.  If provided, the secret is added to Key Vault, and the secret URI is set as output.  Doing so
// allows a consuming template to use the Key Vault secret (instead of directly using the Azure Storage connection string).

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if (!empty(keyVaultName) && !empty(keyVaultConnectionStringSecretName)) {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = if (!empty(keyVaultName) && !empty(keyVaultConnectionStringSecretName)) {
  name: keyVaultConnectionStringSecretName
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name

output storageAccountConnectionStringSecretUriWithVersion string = secret.properties.secretUriWithVersion
