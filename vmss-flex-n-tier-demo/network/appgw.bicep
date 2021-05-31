param appGwName string = 'myAppGw'
param location string = resourceGroup().location
param appGwSubnetId string

var appGwSku = 'Standard_v2'

var appGwPIPName = '${appGwName}-PIP'
var appGwMinCapacty = 0
var appGwMaxCapacity = 10

resource appGwPIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: appGwPIPName
  location: location
  sku:{
    tier: 'Regional'
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion:'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}
resource appgw 'Microsoft.Network/applicationGateways@2020-08-01' = {
  name: appGwName
  location: location

  properties: {
    sku:{
      name: appGwSku
      tier: appGwSku
    }
    gatewayIPConfigurations: [
      {
        name: '${appGwName}IpConfig'
        properties:{
          subnet:{
            id: appGwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: '${appGwName}FrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwPIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools:[
      {
        name: 'bepool01'
        properties:{
          backendAddresses:[]
          
        }
      }
      
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpsettings01'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    httpListeners:[
      {
        name: '${appGwName}httplistener01'
        properties:{
          frontendIPConfiguration:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appGwName)}/frontendIPConfigurations/${appGwName}FrontendIp'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGwName)}/frontendPorts/port_80'
          }
          protocol: 'Http'
        }
      }
      
    ]
    requestRoutingRules: [
      {
        name: 'routingRules01'
        properties: {
          ruleType: 'Basic'
          httpListener:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appGwName)}/httpListeners/${appGwName}httplistener01'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGwName)}/backendAddressPools/bepool01'
          }
          backendHttpSettings: {
            id:  '${resourceId('Microsoft.Network/applicationGateways', appGwName)}/backendHttpSettingsCollection/httpsettings01'
          }
        }
      }
      
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: appGwMinCapacty
      maxCapacity: appGwMaxCapacity
    }
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}
output appGwId  string = appgw.id
output appGwBackendPoolArray array = appgw.properties.backendAddressPools
output appGwPublicIPAddress string = appGwPIP.properties.ipAddress

