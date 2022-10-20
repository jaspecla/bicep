// @description('Username for the Virtual Machine.')
// param adminUsername string

// @description('Password for the Virtual Machine.')
// @minLength(12)
// @secure()
// param adminPassword string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'simple-vm'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = '${vmName}-nic'
var networkSecurityGroupName = 'default-NSG'

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

@description('The name of the resource group containing non-managed deployment resources, not the place where this file will deploy resources.')
param deploymentResourceGroupName string = 'Deployment'

@description('The name of the pre-existing disk resource (in the deployment resourced group) to use as the OS Disk.')
param vmOsDiskName string = 'windows-dev-machine-disk'

resource vmOsDisk 'Microsoft.Compute/disks@2022-07-02' existing = {
  scope: resourceGroup(deploymentResourceGroupName)
  name: vmOsDiskName
}


resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    // osProfile: {
    //   computerName: vmName
    //   adminUsername: adminUsername
    //   adminPassword: adminPassword
    // }
    storageProfile: {
      osDisk: {
        createOption: 'Attach'
        deleteOption: 'Detach'
        managedDisk: {
          id: vmOsDisk.id
        }
        osType: 'Windows'
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
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}
