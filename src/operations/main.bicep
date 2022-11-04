@description('Azure region for the virtual network.')
param location string = resourceGroup().location

@description('The name for the Azure virtual network to be created.')
param virtualNetworkName string

@description('The name of the virtual network subnet in which an Azure VM will be placed.')
param subnetVmName string = 'snet-vm'

@description('The name of the virtual network subnet in which the Azure DevOps self-hosted agent will be placed.')
param subnetAzDoAgentName string = 'snet-agent'

@description('The virtual network IP space to use for the new virutal network.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('The IP space to use for the subnet containing the virtual machine(s).')
param subnetVmAddressPrefix string = '10.0.1.0/24'

@description('The IP space to use for the subnet container the Azure DevOps self-hosted agent(s).')
param subnetAzDoAgentPrefix string = '10.0.2.0/24'

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The administrative username to use for the virtual machine')
param vmAdminUsername string

@description('The administrative password to use for the virtual machine.')
@secure()
param vmAdminPassword string

@description('The name of the Azure Storage account used for Terraform state storage.')
param terraformStateStorageAccountName string

@description('The name of the Azure Container Registry.')
param acrName string = 'cr${uniqueString(resourceGroup().id)}'

var nsgName = 'nsg-${resourceBaseName}'
var terraformStateContainerName = 'tfstate'

var privateDnsNames = [
  'privatelink.azurewebsites.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.servicebus.windows.net'
  'privatelink.sql.azuresynapse.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.azuresynapse.net'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink${environment().suffixes.sqlServerHostname}'
  'privatelink.dfs.${environment().suffixes.storage}'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
]

// Virtual Network

resource vmNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${nsgName}-vm'
  location: location
  properties: {
    securityRules: []
  }
}

resource azdoAgentNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${nsgName}-agent'
  location: location
  properties: {
    securityRules: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetVmName
        properties: {
          addressPrefix: subnetVmAddressPrefix
          networkSecurityGroup: {
            id: vmNsg.id
          }
          delegations: []
        }
      }
      {
        name: subnetAzDoAgentName
        properties: {
          addressPrefix: subnetAzDoAgentPrefix
          networkSecurityGroup: {
            id: azdoAgentNsg.id
          }
          delegations: [
            {
              name: 'acidelegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }

  resource vmSubnet 'subnets' existing = {
    name: subnetVmName
  }

  resource agentSubnet 'subnets' existing = {
    name: subnetAzDoAgentName
  }
}

// Virtual Machine

module jumpboxVm '../common/infrastructure/bicep/windows-vm.bicep' = {
  name: 'jumpboxVmDeploy'
  params: {
    location: location
    resourceBaseName: resourceBaseName
    adminUserName: vmAdminUsername
    adminPassword: vmAdminPassword
    vmSubnetId: virtualNetwork::vmSubnet.id
  }
}

// Storage Account

resource terraformStateStorage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: terraformStateStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}

  resource blob 'blobServices' = {
    name: 'default'
    resource container 'containers' = {
      name: terraformStateContainerName
    }
  }
}

// Azure Container Registry

resource azureContainerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Private DNS Zones

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for dnsName in privateDnsNames: {
  name: dnsName
  location: 'Global'
}]

resource dnsZoneVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (item, index) in privateDnsNames: {
  parent: privateDnsZones[index]
  name: virtualNetwork.name
  location: 'Global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}]

output vmId string = jumpboxVm.outputs.vmId
output azureContainerRegistryName string = azureContainerRegistry.name
