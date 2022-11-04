@description('The username to use for the virtual machine.')
@secure()
param adminUserName string

@description('The password to use for the virtual machine.')
@secure()
param adminPassword string

@description('Azure region for the virtual machine and related resources.')
param location string = resourceGroup().location

@description('The Azure resource ID which uniquely identifies the subnet used for the virtual machine.')
param vmSubnetId string

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

// NOTE: Keeping virtual machine name shorter to comply with Azure's 15 character limit for Windows VM names.
var virtualMachineName = 'vm${resourceBaseName}'

// NOTE: The schedule name must be of the format 'shutdown-computevm-<VIRTUAL-MACHINE-NAME>'.
var windowsVmScheduleName = 'shutdown-computevm-${virtualMachineName}'

var nicName = 'nic-${resourceBaseName}'

var aadLoginExtensionName = 'AADLoginForWindows'

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: vmSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPip.id
            properties: {
              deleteOption: 'Delete'
            }
          }
        }
      }
    ]
  }
}

resource vmPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-${resourceBaseName}-vm'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource windowsVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: windowsVmScheduleName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'UTC'
    notificationSettings: {
      status: 'Disabled'
    }
    targetResourceId: windowsVM.id
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4ds_v5'
    }
    licenseType: 'Windows_Client'
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUserName
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }

  resource ex 'extensions' = {
    name: aadLoginExtensionName
    location: location
    properties: {
      publisher: 'Microsoft.Azure.ActiveDirectory'
      autoUpgradeMinorVersion: true
      type: aadLoginExtensionName
      typeHandlerVersion: '1.0'
    }
  }
}

output vmId string = windowsVM.id
