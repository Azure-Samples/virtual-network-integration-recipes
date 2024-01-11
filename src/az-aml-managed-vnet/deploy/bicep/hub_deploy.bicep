param virtualMachines_hub_vm_name string 
param virtualNetworks_hub_vnet_name string 
param networkInterfaces_hub_vm_name string 
param publicIPAddresses_hub_vm_ip_name string 
param bastionHosts_hub_vnet_Bastion_name string 
param networkSecurityGroups_hub_vm_nsg_name string 
param privateEndpoints_pe_to_managedvnet_name string 
param publicIPAddresses_hub_vnet_bastion_name string 
param schedules_shutdown_computevm_hub_vm_name string  
param privateDnsZones_privatelink_api_azureml_ms_name string 
param privateDnsZones_privatelink_notebooks_azure_net_name string 
param networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name string 
param privateDnsZones_privatelink_blob_core_windows_net_name string 
param privateDnsZones_privatelink_file_core_windows_net_name string 
param privateEndpoints_pe_managedvnet_storageaccount_file_name string 
param networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name string 
param storageAccounts_mlwspocstoraged_externalid string = '/subscriptions/06600e5d-08f4-4cad-b7ba-2c397f811d11/resourceGroups/yogiren/providers/Microsoft.Storage/storageAccounts/mlwspocstoraged'
param workspaces_mlws_poc_externalid string = '/subscriptions/06600e5d-08f4-4cad-b7ba-2c397f811d11/resourceGroups/yogiren/providers/Microsoft.MachineLearningServices/workspaces/mlws_poc'

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name
  location: 'australiaeast'
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowGatewayManager.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'Allow GatewayManager'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2702
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowHttpsInBound'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowHttpsInBound.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'Allow HTTPs'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2703
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowSshRdpOutbound.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowAzureCloudOutbound.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowCorpnet'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowCorpnet.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'CSS Governance Security Rule.  Allow Corpnet inbound.  https://aka.ms/casg'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'CorpNetPublic'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2700
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSAW'
        id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowSAW.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'CSS Governance Security Rule.  Allow SAW inbound.  https://aka.ms/casg'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'CorpNetSaw'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2701
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_resource 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name
  location: 'australiaeast'
  properties: {
    securityRules: [
      {
        name: 'AllowCorpnet'
        id: networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_AllowCorpnet.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'CSS Governance Security Rule.  Allow Corpnet inbound.  https://aka.ms/casg'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'CorpNetPublic'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2700
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSAW'
        id: networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_AllowSAW.id
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          description: 'CSS Governance Security Rule.  Allow SAW inbound.  https://aka.ms/casg'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'CorpNetSaw'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 2701
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource networkSecurityGroups_hub_vm_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroups_hub_vm_nsg_name
  location: 'australiaeast'
  properties: {
    securityRules: []
  }
}

resource privateDnsZones_privatelink_api_azureml_ms_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_api_azureml_ms_name
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 4
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
    provisioningState: 'Succeeded'
  }
}

resource privateDnsZones_privatelink_blob_core_windows_net_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_blob_core_windows_net_name
  location: 'global'
  tags: {
    pe_to_managedvnet_blobstorage: ''
  }
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 1
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
    provisioningState: 'Succeeded'
  }
}

resource privateDnsZones_privatelink_file_core_windows_net_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_file_core_windows_net_name
  location: 'global'
  tags: {
    pe_to_managedvnet_filestorage: ''
  }
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 2
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
    provisioningState: 'Succeeded'
  }
}

resource privateDnsZones_privatelink_notebooks_azure_net_name_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZones_privatelink_notebooks_azure_net_name
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
    numberOfRecordSets: 2
    numberOfVirtualNetworkLinks: 1
    numberOfVirtualNetworkLinksWithRegistration: 0
    provisioningState: 'Succeeded'
  }
}

resource publicIPAddresses_hub_vnet_bastion_name_resource 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPAddresses_hub_vnet_bastion_name
  location: 'australiaeast'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '20.245.156.188'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

resource publicIPAddresses_hub_vm_ip_name_resource 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPAddresses_hub_vm_ip_name
  location: 'australiaeast'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '104.45.212.204'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource virtualMachines_hub_vm_name_resource 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachines_hub_vm_name
  location: 'australiaeast'
  tags: {
    Version: '20230516'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachines_hub_vm_name}_disk1_fb8371d362704d8e92a5376e19249090'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          id: resourceId('Microsoft.Compute/disks', '${virtualMachines_hub_vm_name}_disk1_fb8371d362704d8e92a5376e19249090')
        }
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: virtualMachines_hub_vm_name
      adminUsername: '${virtualMachines_hub_vm_name}-admin'
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_hub_vm665_name_resource.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client'
  }
}

resource schedules_shutdown_computevm_hub_vm_name_resource 'microsoft.devtestlab/schedules@2018-09-15' = {
  name: schedules_shutdown_computevm_hub_vm_name
  location: 'australiaeast'
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'UTC'
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'admin@MngEnvMCAP455457.onmicrosoft.com'
      notificationLocale: 'en'
    }
    targetResourceId: virtualMachines_hub_vm_name_resource.id
  }
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowAzureCloudOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowAzureCloudOutbound'
  properties: {
    protocol: 'TCP'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'AzureCloud'
    access: 'Allow'
    priority: 110
    direction: 'Outbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowCorpnet 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowCorpnet'
  properties: {
    description: 'CSS Governance Security Rule.  Allow Corpnet inbound.  https://aka.ms/casg'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'CorpNetPublic'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2700
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_AllowCorpnet 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name}/AllowCorpnet'
  properties: {
    description: 'CSS Governance Security Rule.  Allow Corpnet inbound.  https://aka.ms/casg'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'CorpNetPublic'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2700
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowGatewayManager 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowGatewayManager'
  properties: {
    description: 'Allow GatewayManager'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'GatewayManager'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2702
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowHttpsInBound 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowHttpsInBound'
  properties: {
    description: 'Allow HTTPs'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2703
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowSAW 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowSAW'
  properties: {
    description: 'CSS Governance Security Rule.  Allow SAW inbound.  https://aka.ms/casg'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'CorpNetSaw'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2701
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_AllowSAW 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name}/AllowSAW'
  properties: {
    description: 'CSS Governance Security Rule.  Allow SAW inbound.  https://aka.ms/casg'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'CorpNetSaw'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 2701
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_resource
  ]
}

resource networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_AllowSshRdpOutbound 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: '${networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name}/AllowSshRdpOutbound'
  properties: {
    protocol: '*'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 100
    direction: 'Outbound'
    sourcePortRanges: []
    destinationPortRanges: [
      '22'
      '3389'
    ]
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
  dependsOn: [
    networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource
  ]
}

resource privateDnsZones_privatelink_api_azureml_ms_name_419b3a2c_288c_4391_9f1e_236c0b6e471b_inference_australiaeast 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_api_azureml_ms_name_resource
  name: '*.419b3a2c-288c-4391-9f1e-236c0b6e471b.inference.australiaeast'
  properties: {
    metadata: {
      creator: 'created by private endpoint pe_to_managedvnet with resource guid 4963c503-c8dc-4933-854e-ad8aede94e27'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.0.6'
      }
    ]
  }
}

resource privateDnsZones_privatelink_api_azureml_ms_name_419b3a2c_288c_4391_9f1e_236c0b6e471b_workspace_australiaeast 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_api_azureml_ms_name_resource
  name: '419b3a2c-288c-4391-9f1e-236c0b6e471b.workspace.australiaeast'
  properties: {
    metadata: {
      creator: 'created by private endpoint pe_to_managedvnet with resource guid 4963c503-c8dc-4933-854e-ad8aede94e27'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.0.4'
      }
    ]
  }
}

resource privateDnsZones_privatelink_api_azureml_ms_name_419b3a2c_288c_4391_9f1e_236c0b6e471b_workspace_australiaeast_cert 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_api_azureml_ms_name_resource
  name: '419b3a2c-288c-4391-9f1e-236c0b6e471b.workspace.australiaeast.cert'
  properties: {
    metadata: {
      creator: 'created by private endpoint pe_to_managedvnet with resource guid 4963c503-c8dc-4933-854e-ad8aede94e27'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.0.4'
      }
    ]
  }
}

resource privateDnsZones_privatelink_notebooks_azure_net_name_ml_mlwspoc_australiaeast_419b3a2c_288c_4391_9f1e_236c0b6e471b_australiaeast 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_notebooks_azure_net_name_resource
  name: 'ml-mlwspoc-australiaeast-419b3a2c-288c-4391-9f1e-236c0b6e471b.australiaeast'
  properties: {
    metadata: {
      creator: 'created by private endpoint pe_to_managedvnet with resource guid 4963c503-c8dc-4933-854e-ad8aede94e27'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.0.5'
      }
    ]
  }
}

resource privateDnsZones_privatelink_file_core_windows_net_name_mlwspocstoraged4813c4856 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_file_core_windows_net_name_resource
  name: 'mlwspocstoraged4813c4856'
  properties: {
    metadata: {
      creator: 'created by private endpoint pe_managedvnet_storageaccount_file with resource guid 3d51d363-0b9a-45fa-b19a-bb20cb1f13ea'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.0.8'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_api_azureml_ms_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_api_azureml_ms_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_blob_core_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_blob_core_windows_net_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_file_core_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_file_core_windows_net_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_notebooks_azure_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_notebooks_azure_net_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource privateEndpoints_pe_managedvnet_storageaccount_file_name_resource 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpoints_pe_managedvnet_storageaccount_file_name
  location: 'australiaeast'
  tags: {
    pe_to_managedvnet_filestorage: ''
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoints_pe_managedvnet_storageaccount_file_name
        id: '${privateEndpoints_pe_managedvnet_storageaccount_file_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_pe_managedvnet_storageaccount_file_name}'
        properties: {
          privateLinkServiceId: storageAccounts_mlwspocstoraged4813c4856_externalid
          groupIds: [
            'file'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpoints_pe_managedvnet_storageaccount_file_name}-nic'
    subnet: {
      id: virtualNetworks_hub_vnet_name_default.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpoints_pe_to_managedvnet_name_resource 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpoints_pe_to_managedvnet_name
  location: 'australiaeast'
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoints_pe_to_managedvnet_name
        id: '${privateEndpoints_pe_to_managedvnet_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_pe_to_managedvnet_name}'
        properties: {
          privateLinkServiceId: workspaces_mlws_poc_externalid
          groupIds: [
            'amlworkspace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpoints_pe_to_managedvnet_name}-nic'
    subnet: {
      id: virtualNetworks_hub_vnet_name_default.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource bastionHosts_hub_vnet_Bastion_name_resource 'Microsoft.Network/bastionHosts@2023-06-01' = {
  name: bastionHosts_hub_vnet_Bastion_name
  location: 'australiaeast'
  sku: {
    name: 'Basic'
  }
  properties: {
    dnsName: 'bst-55021bc8-81b0-49cf-a522-34f443c7290d.bastion.azure.com'
    scaleUnits: 2
    ipConfigurations: [
      {
        name: 'IpConf'
        id: '${bastionHosts_hub_vnet_Bastion_name_resource.id}/bastionHostIpConfigurations/IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_hub_vnet_bastion_name_resource.id
          }
          subnet: {
            id: virtualNetworks_hub_vnet_name_AzureBastionSubnet.id
          }
        }
      }
    ]
  }
}

resource privateDnsZones_privatelink_api_azureml_ms_name_346zkpdsdmsgk 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones_privatelink_api_azureml_ms_name_resource
  name: '346zkpdsdmsgk'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworks_hub_vnet_name_resource.id
    }
  }
}

resource privateDnsZones_privatelink_blob_core_windows_net_name_346zkpdsdmsgk 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones_privatelink_blob_core_windows_net_name_resource
  name: '346zkpdsdmsgk'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworks_hub_vnet_name_resource.id
    }
  }
}

resource privateDnsZones_privatelink_file_core_windows_net_name_346zkpdsdmsgk 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones_privatelink_file_core_windows_net_name_resource
  name: '346zkpdsdmsgk'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworks_hub_vnet_name_resource.id
    }
  }
}

resource privateDnsZones_privatelink_notebooks_azure_net_name_346zkpdsdmsgk 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones_privatelink_notebooks_azure_net_name_resource
  name: '346zkpdsdmsgk'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworks_hub_vnet_name_resource.id
    }
  }
}

resource privateEndpoints_pe_managedvnet_storageaccount_file_name_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: '${privateEndpoints_pe_managedvnet_storageaccount_file_name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_file_core_windows_net_name_resource.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoints_pe_managedvnet_storageaccount_file_name_resource

  ]
}

resource virtualNetworks_hub_vnet_name_resource 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetworks_hub_vnet_name
  location: 'australiaeast'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: 'default'
        id: virtualNetworks_hub_vnet_name_default.id
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_resource.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        id: virtualNetworks_hub_vnet_name_AzureBastionSubnet.id
        properties: {
          addressPrefix: '10.0.1.0/26'
          networkSecurityGroup: {
            id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource virtualNetworks_hub_vnet_name_AzureBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: '${virtualNetworks_hub_vnet_name}/AzureBastionSubnet'
  properties: {
    addressPrefix: '10.0.1.0/26'
    networkSecurityGroup: {
      id: networkSecurityGroups_hub_vnet_AzureBastionSubnet_nsg_australiaeast_name_resource.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
  dependsOn: [
    virtualNetworks_hub_vnet_name_resource

  ]
}

resource virtualNetworks_hub_vnet_name_default 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: '${virtualNetworks_hub_vnet_name}/default'
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroups_hub_vnet_default_nsg_australiaeast_name_resource.id
    }
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
  dependsOn: [
    virtualNetworks_hub_vnet_name_resource

  ]
}

resource networkInterfaces_hub_vm665_name_resource 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterfaces_hub_vm665_name
  location: 'australiaeast'
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        id: '${networkInterfaces_hub_vm665_name_resource.id}/ipConfigurations/ipconfig1'
        etag: 'W/"5d733dfe-5b2c-45d3-b530-590734769758"'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          provisioningState: 'Succeeded'
          privateIPAddress: '10.0.0.7'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_hub_vm_ip_name_resource.id
            properties: {
              deleteOption: 'Delete'
            }
          }
          subnet: {
            id: virtualNetworks_hub_vnet_name_default.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroups_hub_vm_nsg_name_resource.id
    }
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource privateEndpoints_pe_to_managedvnet_name_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: '${privateEndpoints_pe_to_managedvnet_name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-api-azureml-ms'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_api_azureml_ms_name_resource.id
        }
      }
      {
        name: 'privatelink-notebooks-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_notebooks_azure_net_name_resource.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoints_pe_to_managedvnet_name_resource

  ]
}
