@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the Azure Data Factory.')
param azureDataFactoryName string

@description('The name of the Azure Key Vault.')
param keyVaultName string

@description('The name of the storage account.')
param storageAccountName string

@description('The name of the Azure SQL Server.')
param sqlServerName string

@description('The name of the Azure SQL database.')
param sqlDatabaseName string

@description('The name of the managed private endpoint for accessing storage account.')
param mpeStorageName string

@description('The name of the managed private endpoint for accessing key vault.')
param mpeKeyVaultName string

@description('The name of the managed private endpoint for accessing sql database.')
param mpeSqlServerName string

@description('The name of the linked service to storage account.')
param lsStorageName string

@description('The name of the linked service to key vault.')
param lsSqlDatabaseName string

@description('The name of the linked service to sql database.')
param lsKeyVaultName string

@description('The username of the SQL database admin.')
param sqlAdminUsername string

@description('The password of the SQL database admin.')
@secure()
param sqlAdminPassword string 

var vaultUri = 'https://${keyVault.name}${environment().suffixes.keyvaultDns}'
var storageUri = 'https://${storage.name}.dfs.${environment().suffixes.storage}'
var azureSqlDatabaseConnectionString = 'integrated security=False;encrypt=True;connection timeout=30;data source=${sqlServerName}.database.windows.net;initial catalog=${sqlDatabaseName};user id=${sqlAdminUsername};Password=${sqlAdminPassword}'

// https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var adfRoleAssignmentId = guid(resourceGroup().id, storageBlobDataContributorRoleId)

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource sqlServer 'Microsoft.Sql/servers@2020-02-02-preview' existing = {
  name: sqlServerName
}

resource sqlDb 'Microsoft.Sql/servers/databases@2020-08-01-preview' existing = {
  name: sqlDatabaseName
}

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: azureDataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }

  resource vnetManaged 'managedVirtualNetworks' = {
    name: 'default'
    properties: {}
  }

  resource adfRuntime 'integrationRuntimes' = {
    name: 'mir-001'
    properties: {
      type: 'Managed'
      description: 'Managed Azure hosted intergartion runtime'
      typeProperties: {
        computeProperties: {
          location: location
          dataFlowProperties: {
            computeType: 'General'
            coreCount: 8
            timeToLive: 10
            cleanup: false
          }
        }
      }
      managedVirtualNetwork: {
        referenceName: vnetManaged.name
        type: 'ManagedVirtualNetworkReference'
      }
    }
  }
}

resource mpeStorage 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: adf::vnetManaged
  name: mpeStorageName
  properties: {
    privateLinkResourceId: storage.id
    groupId: 'dfs'
  }
}
  
resource mpeKeyvault 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: adf::vnetManaged
  name: mpeKeyVaultName
  properties: {
    privateLinkResourceId: keyVault.id
    groupId: 'vault'
  }
} 

resource mpeSqlServer 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: adf::vnetManaged
  name: mpeSqlServerName
  properties: {
    privateLinkResourceId: sqlServer.id
    groupId: 'sqlServer'
  }
}

resource lsStorage 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: adf
  name: lsStorageName
  properties: {
    description: 'Linked service to ADLS2'
    type: 'AzureBlobFS'
    typeProperties: {
      url: storageUri
    }
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: adf::adfRuntime.name
    }
  }
}

resource lsKeyvault 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: adf
  name: lsKeyVaultName
  properties: {
    description: 'Linked service to Key Vault'
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: vaultUri
    }
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: adf::adfRuntime.name
    }
  }
}

resource lsSqlDb 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: adf
  name: lsSqlDatabaseName
  properties: {
    description: 'Linked service to SQL DB'
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: azureSqlDatabaseConnectionString
    }
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: adf::adfRuntime.name
    }
  }
}

// Please note the usage of feature "#disable-next-line" to suppress warning "BCP081".
// BCP081: Resource type "Microsoft.Authorization/roleAssignments@2021-04-01-preview" does not have types available.
#disable-next-line BCP081
resource adfStorageBlobDataContributorRoleAssigment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: adfRoleAssignmentId
  properties: {
    principalId: adf.identity.principalId
    roleDefinitionId: storageBlobDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
  scope: storage
}

resource kvAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: adf.identity.principalId
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

output outAzureDataFactoryName string = adf.name
output outMpeStorageAccountName string = mpeStorage.name
output outMpeKeyVaultName string = mpeKeyvault.name
output outMpeSqlServerName string = mpeSqlServer.name
