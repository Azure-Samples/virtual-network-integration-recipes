@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The name of the virtual network.')
param vnetName string

@description('The name of the virtual network subnet to be used for private endpoints.')
param subnetName string

@description('The name of the Azure SQL Server.')
param sqlServerName string

@description('The name of the Azure SQL database.')
param sqlDatabaseName string

@description('The username of the SQL database admin.')
param sqlAdminUsername string

@description('The password of the SQL database admin.')
param sqlAdminPassword string

@description('The Private DNS Zone id for registering SQL Server private endpoints.')
param sqlPrivateDnsZoneId string

@description('The tags to be applied to the provisioned resources.')
param tags object

var privateSubnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'

resource sqlServer 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
  tags: tags
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
  }
  properties: {
    autoPauseDelay: 60
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    minCapacity: 1
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: 'pe-${sqlServerName}'
  location: location
  properties: {
    subnet: {
      id: privateSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${sqlServerName}'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }

  resource sqlDnsZonesGroups 'privateDnsZoneGroups' = {
    name: 'sqlPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: sqlPrivateDnsZoneId
          }
        }
      ]
    }
  }
}

output outSqlServerName string = sqlServer.name
output outSqlDatabaseName string = sqlDatabase.name
