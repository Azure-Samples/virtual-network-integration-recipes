@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param baseName string

@description('The name of the virtual network for virtual network integration.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetName string

@description('The name of the Azure Synapse workspace.')
param synWorkspaceName string

@description('The name of the spark (bigdata) pool.')
param synBigDataPoolName string

@description('The name of the sql pool.')
param synSqlPoolName string

@description('The name of the storage account for synapse.')
param synStorageAccountName string

@description('The name of the storage account for application.')
param mainStorageAccountName string

@description('The name of the synapse storage account default container.')
param synStorageFilesysName string

@description('The name of the application storage account default container.')
param mainStorageFilesysName string

@description('The name of the synapse private link hub.')
param privateLinkHubName string

@description('The name of the key vault.')
param keyVaultName string

@description('The username for the synapse SQL admin.')
param synSqlAdminUsername string

@description('The password for the synapse SQL admin.')
@secure()
param synSqlAdminPassword string

@description('The Private DNS Zone id for registering synapse SQL "sql/sql-ondemand" private endpoints.')
param sqlPrivateDnsZoneId string

@description('The Private DNS Zone id for registering synapse SQL "dev" private endpoints.')
param devPrivateDnsZoneId string

@description('The Private DNS Zone id for registering synapse SQL "web" private endpoints.')
param webPrivateDnsZoneId string

@description('The tags to be applied to the provisioned resources.')
param tags object = {
  baseName : baseName
}

var privateSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'

// https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource privateLinkHub 'Microsoft.Synapse/privateLinkHubs@2021-06-01' = {
  name: privateLinkHubName
  tags: tags
  location: location
}

var synapsePrivateEndpointNames = [
  'Sql'
  'SqlOnDemand'
  'Dev'
  'Web'
]

var mapSynapsePrivateEndpointToDns = {
  Sql: {
    dnsZoneId: sqlPrivateDnsZoneId
  }
  SqlOnDemand: {
    dnsZoneId: sqlPrivateDnsZoneId
  }
  Dev: {
    dnsZoneId: devPrivateDnsZoneId
  }
  Web: {
    dnsZoneId: webPrivateDnsZoneId
  }
}

resource synStorage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: synStorageAccountName
}

resource synFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  name: synStorageFilesysName
}

resource mainStorage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: mainStorageAccountName
}

resource mainFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  name: mainStorageFilesysName
}

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synWorkspaceName
  tags: tags
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${synStorage.name}.dfs.${environment().suffixes.storage}'
      filesystem: synFileSystem.name
    }
    publicNetworkAccess: 'Disabled'
    managedVirtualNetwork: 'default'
    managedResourceGroupName: 'mrg-syn-${baseName}'
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: []
      linkedAccessCheckOnTargetResource: true
      preventDataExfiltration: true
    }
    sqlAdministratorLogin: synSqlAdminUsername
    sqlAdministratorLoginPassword: synSqlAdminPassword
  }

  resource managedIdentitySqlControlSettings 'managedIdentitySqlControlSettings@2021-06-01' = {
    name: 'default'
    properties: {
      grantSqlControlToManagedIdentity: {
        desiredState: 'Enabled'
      }
    }
  }
}

resource synapseSqlPool001 'Microsoft.Synapse/workspaces/sqlPools@2021-06-01' = {
  parent: synapseWorkspace
  name: synSqlPoolName
  location: location
  tags: tags
  sku: {
    name: 'DW100c'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    storageAccountType: 'GRS'
  }
}

resource synapseBigDataPool001 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: synBigDataPoolName
  location: location
  tags: tags
  properties: {
    isComputeIsolationEnabled: false
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: 'Small'
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    dynamicExecutorAllocation: {
      enabled: true
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    sparkVersion: '2.4'
    sessionLevelPackagesEnabled: true
    customLibraries: []
    defaultSparkLogFolder: 'logs/'
    sparkEventsFolder: 'events/'
  }
}

// Please note the usage of feature "#disable-next-line" to suppress warning "BCP081".
// BCP081: Resource type "Microsoft.Authorization/roleAssignments@2021-04-01-preview" does not have types available.
#disable-next-line BCP081
resource roleAssignment1 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', synStorage.name))
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: storageBlobDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
  scope: synStorage
}

#disable-next-line BCP081
resource roleAssignment2 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, resourceId('Microsoft.Storage/storageAccounts', mainStorage.name))
  properties: {
    principalId: synapseWorkspace.identity.principalId
    roleDefinitionId: storageBlobDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
  scope: mainStorage
}

// Azure Synapse "Private Endpoints" + "A Record"
resource synapsePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = [for peName in synapsePrivateEndpointNames: {
  name: 'pe-syn-${peName}-${baseName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-syn-${peName}-${baseName}'
        properties: {
          privateLinkServiceId: (peName == 'Web') ? privateLinkHub.id : synapseWorkspace.id
          groupIds: [
            '${peName}'
          ]
        }
      }
    ]
  }
}]

resource synapsePrivateDnsZonesGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = [for (peName, index) in synapsePrivateEndpointNames: {
  parent: synapsePrivateEndpoint[index]
  name: 'syanpsePrivateDnsZonesGroups'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: mapSynapsePrivateEndpointToDns[peName].dnsZoneId
        }
      }
    ]
  }
}]

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: kv
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: synapseWorkspace.identity.principalId
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

output outSynapseWorkspaceName string = synapseWorkspace.name
output outSynapseDefaultStorageAccountName string = synStorage.name
output outSynapseSqlPoolName string = synapseSqlPool001.name
output outSynapseBigdataPoolName string = synapseBigDataPool001.name
