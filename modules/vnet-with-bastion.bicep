@description('VNet name')
param vnetName string = 'demo-vnet'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Default Subnet Prefix')
param defaultSubnetPrefix string = '10.0.0.0/24'

@description('Default Subnet Name')
param defaultSubnetName string = 'default'

@description('Bastion Subnet Prefix')
param bastionSubnetPrefix string = '10.0.1.0/24'
var bastionSubnetName = 'AzureBastionSubnet'

@description('Bastion Resource Name')
param bastionResourceName string = 'bastion-demo'

@description('Bastion SKU')
@allowed(['Basic', 'Standard'])
param bastionSku string = 'Basic'

@description('Number of Bastion Scale Units')
param bastionScaleUnits int = 2
var numScaleUnits = (bastionSku == 'Standard' ? bastionScaleUnits : 2)

@description('Location for all resources.')
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: defaultSubnetPrefix
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }

  resource defaultSubnet 'subnets' existing = {
    name: defaultSubnetName
  }

  resource bastionSubnet 'subnets' existing = {
    name: bastionSubnetName
  }

}

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: '${bastionResourceName}-publicip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionResourceName
  location: location
  sku: {
    name: bastionSku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'BastionPublicIPConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          subnet: {
            id: vnet::bastionSubnet.id
          }
        }
      }
    ]
    scaleUnits: numScaleUnits
  }
}

output defaultSubnetId string = vnet::defaultSubnet.id
