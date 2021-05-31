// Location for all resources.
param location string = resourceGroup().location

// Name of the VNET.
param virtualNetworkName string = 'vNet'

var addressPrefix = '10.0.0.0/16'
var subnetList  = [
  {
    name: 'web'
    addr: '10.0.1.0/24'
    nsgId: nsg.id
  }
  {
    name: 'biz'
    addr: '10.0.2.0/24'
    nsgId: nsg.id
  }
  {
    name: 'data'
    addr: '10.0.3.0/24'
    nsgId: nsg.id
  }
  {
    name: 'mgmt'
    addr: '10.0.0.128/25'
    nsgId: nsg.id
  }
  {
    name: 'appgateway'
    addr: '10.0.4.0/25'
    nsgId: appgwnsg.id
  }
]

var nsgName = '${virtualNetworkName}NSG'

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'RDP'
        properties: {
          priority: 1050
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 1100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: 1200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

resource appgwnsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'appgwnsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-appgw-v2'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets:[for subnet in subnetList: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addr
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        serviceEndpoints:[
          {
            service: 'Microsoft.KeyVault'
          }
        ]
        networkSecurityGroup:{
          id: subnet.nsgId
        }
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetSubnetArray array = vnet.properties.subnets

