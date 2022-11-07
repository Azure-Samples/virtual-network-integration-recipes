@description('The Azure region in which to create the resource group.')
param location string

@description('The name of the Azure container registry.')
param acrName string

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
