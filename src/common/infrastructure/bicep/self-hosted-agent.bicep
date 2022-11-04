@description('The Azure region in which to create the resource group.')
param location string

@description('The name of the image to push to ACR.')
param imageName string = 'selfhostedagent'

@description('The tag of the image to push to ACR.')
param imageTag string = 'latest'

@description('The PAT used to connect to the Azure Dev Ops instance.')
@secure()
param azureDevOpsPersonalAccessToken string

@description('The Azure Dev Ops organization.')
param azureDevOpsOrgName string

@description('The Azure Dev Ops agent pool to deploy agents to.')
param azureDevOpsPoolName string

@description('The number of agents to deploy to the agent pool')
param agentCount int = 5

@description('The existing virtual network to connect to the Azure Container Instance.')
param existingVirtualNetworkName string

@description('The existing virtual network subnet delegated to the Azure Container Instance service.')
param existingAciSubnetName string

@description('The name of the existing Azure Container Registry from which the Azure Container Instance will pull an image.')
param existingAcrName string

resource existingVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: existingVirtualNetworkName

  resource existingAciSubnet 'subnets' existing = {
    name: existingAciSubnetName
  }
}

resource existingAcr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: existingAcrName
}

resource networkProfile 'Microsoft.Network/networkProfiles@2021-02-01' = [for i in range(0, agentCount): {
  name: 'linuxnetprofile${i}'
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'linuxnic${i}'
        properties: {
          ipConfigurations: [
            {
              name: 'linuxnip${i}'
              properties: {
                subnet: {
                  id: existingVnet::existingAciSubnet.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}]

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = [for i in range(0, agentCount): {
  name: 'linuxagent-${i}'
  location: location
  properties: {
    containers: [
      {
        name: 'linuxagent-${i}'
        properties: {
          environmentVariables: [
            {
              name: 'AZP_URL'
              value: 'https://dev.azure.com/${azureDevOpsOrgName}'
            }
            {
              name: 'AZP_POOL'
              value: azureDevOpsPoolName
            }
            {
              name: 'AZP_AGENT_NAME'
              value: 'linuxagent-${i}'
            }
            {
              name: 'AZP_TOKEN'
              secureValue: azureDevOpsPersonalAccessToken
            }
          ]
          image: '${existingAcr.properties.loginServer}/${imageName}:${imageTag}'
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            limits: {
              cpu: 1
              memoryInGB: 4
            }
            requests: {
              cpu: 1
              memoryInGB: 4
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: existingAcr.properties.loginServer
        username: existingAcr.listCredentials().username
        password: existingAcr.listCredentials().passwords[0].value
      }
    ]
    networkProfile: {
      id: networkProfile[i].id
    }
    osType: 'Linux'
    restartPolicy: 'Always'
    sku: 'Standard'
  }
}]
