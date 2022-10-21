@description('Size of the virtual machine.')
param vmSize string = 'Standard_D4s_v3'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'simple-vm'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = '${vmName}-nic'
var networkSecurityGroupName = '${vmName}-nsg'

@description('Name of the resource group in which to create Networking resources.')
param networkingResourceGroupName string = 'Networking'
module vnet 'modules/vnet-with-bastion.bicep' = {
  name: 'vnetWithBicep'
  scope: resourceGroup(networkingResourceGroupName)
  params: {
    location: location
  }
}

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.outputs.defaultSubnetId
          }
        }
      }
    ]
  }
}

@description('The name of the resource group containing the VM Image Gallery.')
param vmImageGalleryResourceGroup string = 'VM_Images'

@description('The name of the VM Image to use from the gallery')
param vmImageName string = 'computer_gallery_demo/specialized-dev-vm'

@description('The version of the image to use.')
param vmImageVersionName string = '0.0.2'

resource vmImage 'Microsoft.Compute/galleries/images@2022-03-03' existing = {
  scope: resourceGroup(vmImageGalleryResourceGroup)
  name: vmImageName
}

resource vmImageVersion 'Microsoft.Compute/galleries/images/versions@2022-03-03' existing = {
  name: vmImageVersionName
  parent: vmImage
}

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        id: vmImageVersion.id
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: []
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
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}

@description('The email address of the person to alert when the VM is scheduled to shut down.')
param shutDownEmail string

resource shutdownTask 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-simple-vm'
  location: location
  properties: {
    dailyRecurrence: {
      time: '2300'
    }
    notificationSettings: {
      emailRecipient: shutDownEmail
      status: 'Enabled'
      timeInMinutes: 30
    }
    status: 'Enabled'
    targetResourceId: vm.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: 'Eastern Standard Time'
  }
}
