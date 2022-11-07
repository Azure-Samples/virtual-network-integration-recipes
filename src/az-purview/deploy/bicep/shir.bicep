// Parameters
@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = toLower(uniqueString(resourceGroup().id))

@description('The SKU name of the virtual machine scale set.')
param vmssSkuName string = 'Standard_DS2_v2'

@description('The SKU tier of virtual machines in a scale set.')
param vmssSkuTier string = 'Standard'

@description('The SKU capacity of virtual machines in a scale set.')
param vmssSkuCapacity int = 1

@description('The name of the administrator account.')
param administratorUsername string = 'VmssMainUser'

@description('The password of the administrator account.')
@secure()
param administratorPassword string

@description('The authentication key for the purview integration runtime.')
@secure()
param purviewIntegrationRuntimeAuthKey string

// Variables
var baseName = toLower(resourceBaseName) // Ensure that a user-provided value is lowercase.
var vnetName = 'vnet-${baseName}'
var subnetName = 'snet-${baseName}-shir'
var vmssName = 'vm-${baseName}'
var subnetId = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
var loadbalancerName = '${vmssName}-lb'

// Resources
resource loadbalancer001 'Microsoft.Network/loadBalancers@2021-03-01' = {
  name: loadbalancerName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    backendAddressPools: [
      {
        name: '${vmssName}-backendaddresspool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendipconfiguration'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    inboundNatPools: [
      {
        name: '${vmssName}-natpool'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, 'frontendipconfiguration')
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50099
          backendPort: 3389
          idleTimeoutInMinutes: 4
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'proberule'
        properties: {
          loadDistribution: 'Default'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, '${vmssName}-backendaddresspool')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, 'frontendipconfiguration')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, '${vmssName}-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
    ]
    probes: [
      {
        name: '${vmssName}-probe'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource vmss001 'Microsoft.Compute/virtualMachineScaleSets@2021-07-01' = {
  name: vmssName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: vmssSkuName
    tier: vmssSkuTier
    capacity: vmssSkuCapacity
  }
  properties: {
    additionalCapabilities: {}
    automaticRepairsPolicy: {}
    doNotRunExtensionsOnOverprovisionedVMs: true
    overprovision: true
    platformFaultDomainCount: 1
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      priority: 'Regular'
      osProfile: {
        adminUsername: administratorUsername
        adminPassword: administratorPassword
        computerNamePrefix: take(vmssName, 9)
        customData: loadFileAsBase64('../scripts/installSHIRGateway.ps1')
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              dnsSettings: {}
              enableAcceleratedNetworking: false
              enableFpga: false
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${vmssName}-ipconfig'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, '${vmssName}-backendaddresspool')
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadbalancerName, '${vmssName}-natpool')
                      }
                    ]
                    primary: true
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      storageProfile: {
        imageReference: {
          offer: 'WindowsServer'
          publisher: 'MicrosoftWindowsServer'
          sku: '2022-datacenter-azure-edition'
          version: 'latest'
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: '${vmssName}-integrationruntime-shir'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: []
              }
              protectedSettings: {
                commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command "cp c:/azuredata/customdata.bin c:/azuredata/installSHIRGateway.ps1; c:/azuredata/installSHIRGateway.ps1 -gatewayKey "${purviewIntegrationRuntimeAuthKey}"'
              }
            }
          }
        ]
      }
    }
  }
}
