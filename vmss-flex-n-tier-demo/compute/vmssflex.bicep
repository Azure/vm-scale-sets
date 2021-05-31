param vmssname string = 'myVmssFlex'
param region string = resourceGroup().location
param zones array = []

param vmSize string = 'Standard_DS1_v2'
@allowed([
  1
  2
  3
  5
])
param platformFaultDomainCount int = 1
@maxValue(500)
param vmCount int = 3

param subnetId string
param lbBackendPoolArray array = []
param appGwBackendPoolArray array = []

@allowed([
  'Regular'
  'Spot'
])
param priority string = 'Regular'
@allowed([
  'Deallocate'
  'Delete'
  ''
])
param spotEvictionPolicy string = ''
param spotBillingProfile object = {
  
}

param adminUsername string = 'azureuser'
@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string = 'password'
param adminPasswordOrKey string = '6yEV9YmJkuG8fvYjj^k84'

var networkApiVersion = '2020-11-01'
// This launches a simple node app that returns the contents of IMDS. It also exposes /health for application health. https://github.com/fitzgeraldsteele/azure-sig-aib-vmss-demo/blob/master/cloud-init/cloud-init.sample.yml
var imdsCustomDataBase64 = 'I2Nsb3VkLWNvbmZpZwpwYWNrYWdlX3VwZ3JhZGU6IHRydWUKcGFja2FnZXM6CiAgLSBuZ2lueAogIC0gbm9kZWpzCiAgLSBucG0Kd3JpdGVfZmlsZXM6CiAgLSBvd25lcjogd3d3LWRhdGE6d3d3LWRhdGEKICAgIHBhdGg6IC9ldGMvbmdpbngvc2l0ZXMtYXZhaWxhYmxlL2RlZmF1bHQKICAgIGNvbnRlbnQ6IHwKICAgICAgc2VydmVyIHsKICAgICAgICBsaXN0ZW4gODA7CiAgICAgICAgbG9jYXRpb24gLyB7CiAgICAgICAgICBwcm94eV9wYXNzIGh0dHA6Ly9sb2NhbGhvc3Q6MzAwMDsKICAgICAgICAgIHByb3h5X2h0dHBfdmVyc2lvbiAxLjE7CiAgICAgICAgICBwcm94eV9zZXRfaGVhZGVyIFVwZ3JhZGUgJGh0dHBfdXBncmFkZTsKICAgICAgICAgIHByb3h5X3NldF9oZWFkZXIgQ29ubmVjdGlvbiBrZWVwLWFsaXZlOwogICAgICAgICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgICAgICAgcHJveHlfY2FjaGVfYnlwYXNzICRodHRwX3VwZ3JhZGU7CiAgICAgICAgfQogICAgICB9CiAgLSBvd25lcjogYXp1cmV1c2VyOmF6dXJldXNlcgogICAgcGF0aDogL2hvbWUvYXp1cmV1c2VyL215YXBwL2luZGV4LmpzCiAgICBjb250ZW50OiB8CiAgICAgIHZhciBleHByZXNzID0gcmVxdWlyZSgnZXhwcmVzcycpCiAgICAgIHZhciBhcHAgPSBleHByZXNzKCkKICAgICAgdmFyIG9zID0gcmVxdWlyZSgnb3MnKTsKICAgICAgYXBwLmdldCgnLycsIGZ1bmN0aW9uIChyZXEsIHJlcykgewogICAgICAgIGNvbnN0IHJlcXVlc3QgPSByZXF1aXJlKCdyZXF1ZXN0Jyk7CiAgICAgICAgY29uc3Qgb3B0aW9ucyA9IHsKICAgICAgICAgIHVybDogJ2h0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbWV0YWRhdGEvaW5zdGFuY2U/YXBpLXZlcnNpb249MjAxOS0wMy0xMScsCiAgICAgICAgICBoZWFkZXJzOiB7CiAgICAgICAgICAgICdNZXRhZGF0YSc6ICd0cnVlJwogICAgICAgICAgfQogICAgICAgIH07CiAgICAgICAgcmVxdWVzdChvcHRpb25zLCBmdW5jdGlvbiAoZXJyb3IsIHJlc3BvbnNlLCBib2R5KSB7CiAgICAgICAgICBpZiAoIWVycm9yICYmIHJlc3BvbnNlLnN0YXR1c0NvZGUgPT0gMjAwKSB7CiAgICAgICAgICAgIHZhciBtZXRhZGF0YU9iaiA9IEpTT04ucGFyc2UoYm9keSkKICAgICAgICAgICAgbGV0IGVqcyA9IHJlcXVpcmUoJ2VqcycpLAogICAgICAgICAgICAgIGh0bWwgPSBlanMucmVuZGVyKAogICAgICAgICAgICAgICAgJzxoMj48JT0gbWV0YWRhdGFPYmouY29tcHV0ZS5uYW1lICU+PC9oMj4gXAogICAgICAgICAgICAgICAgICA8cD5OYW1lOiA8JT0gbWV0YWRhdGFPYmouY29tcHV0ZS5uYW1lICU+PC9wPiBcCiAgICAgICAgICAgICAgICAgIDxwPlByaXZhdGUgSVAgQWRkcmVzczogPCU9IG1ldGFkYXRhT2JqLm5ldHdvcmsuaW50ZXJmYWNlWzBdLmlwdjQuaXBBZGRyZXNzWzBdLnByaXZhdGVJcEFkZHJlc3MgJT48L3A+IFwKICAgICAgICAgICAgICAgICAgPHA+UmVzb3VyY2UgaWQ6IDwlPSBtZXRhZGF0YU9iai5jb21wdXRlLnJlc291cmNlSWQgJT48L3A+IFwKICAgICAgICAgICAgICAgICAgPHA+U2NhbGUgc2V0IG5hbWU6IDwlPSBtZXRhZGF0YU9iai5jb21wdXRlLnZtU2NhbGVTZXROYW1lICU+PC9wPjwvcD4gXAogICAgICAgICAgICAgICAgICA8cD48cHJlPjwlPSAgSlNPTi5zdHJpbmdpZnkobWV0YWRhdGFPYmosIG51bGwsIDIpICU+PC9wcmU+PC9wPicsCiAgICAgICAgICAgICAgICAgIHsgbWV0YWRhdGFPYmo6IG1ldGFkYXRhT2JqIH0KICAgICAgICAgICAgICApCiAgICAgICAgICAgIHJlcy5zZW5kKGh0bWwpCiAgICAgICAgICB9CiAgICAgICAgICBlbHNlIHsKICAgICAgICAgICAgY29uc29sZS5sb2coIkVycm9yICIgKyByZXNwb25zZS5zdGF0dXNDb2RlKQogICAgICAgICAgfQogICAgICAgIH0pCiAgICAgIH0pCiAgICAgIGFwcC5nZXQoJy9tZXRhJywgZnVuY3Rpb24gKHJlcSwgcmVzKSB7CiAgICAgICAgY29uc3QgcmVxdWVzdCA9IHJlcXVpcmUoJ3JlcXVlc3QnKTsKICAgICAgICBjb25zdCBvcHRpb25zID0gewogICAgICAgICAgdXJsOiAnaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9tZXRhZGF0YS9pbnN0YW5jZT9hcGktdmVyc2lvbj0yMDE5LTAzLTExJywKICAgICAgICAgIGhlYWRlcnM6IHsKICAgICAgICAgICAgJ01ldGFkYXRhJzogJ3RydWUnCiAgICAgICAgICB9CiAgICAgICAgfTsKICAgICAgICByZXF1ZXN0KG9wdGlvbnMsIGZ1bmN0aW9uIChlcnJvciwgcmVzcG9uc2UsIGJvZHkpIHsKICAgICAgICAgIGlmICghZXJyb3IgJiYgcmVzcG9uc2Uuc3RhdHVzQ29kZSA9PSAyMDApIHsKICAgICAgICAgICAgcmVzLnNldCgnQ29udGVudC1UeXBlJywgJ2FwcGxpY2F0aW9uL2pzb24nKTsKICAgICAgICAgICAgcmVzLnNlbmQoYm9keSkKICAgICAgICAgIH0KICAgICAgICAgIGVsc2UgewogICAgICAgICAgICBjb25zb2xlLmxvZygiRXJyb3IgIiArIHJlc3BvbnNlLnN0YXR1c0NvZGUpCiAgICAgICAgICB9CiAgICAgICAgfSkKICAgICAgfSkKICAgICAgYXBwLmdldCgnL2hlYWx0aCcsIGZ1bmN0aW9uIChyZXEsIHJlcykgewogICAgICAgIHJlcy5zZW5kKCdQT05HIScpCiAgICAgIH0pCiAgICAgIGFwcC5saXN0ZW4oMzAwMCwgZnVuY3Rpb24gKCkgewogICAgICAgIGNvbnNvbGUubG9nKCdIZWxsbyB3b3JsZCBhcHAgbGlzdGVuaW5nIG9uIHBvcnQgMzAwMCEnKQogICAgICB9KQpydW5jbWQ6CiAgLSBzZXJ2aWNlIG5naW54IHJlc3RhcnQKICAtIGNkICIvaG9tZS9henVyZXVzZXIvbXlhcHAiCiAgLSBucG0gaW5pdAogIC0gbnBtIGluc3RhbGwgZXhwcmVzcyAteQogIC0gbnBtIGluc3RhbGwgbm9kZW1vbiAteQogIC0gbnBtIGluc3RhbGwgZWpzIC15CiAgLSBub2RlanMgaW5kZXguanM='
var linuxConfiguration = {
  disablePasswordAuthentication: true
  provisionVMAgent: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: '${adminPasswordOrKey}'
      }
    ]
  }
}

resource diagStorageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: 'diagstorage${uniqueString(resourceGroup().id)}'
  location: region
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
}


resource vmssflex 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: '${vmssname}'
  location: '${region}'
  zones: zones
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: vmCount
  }
  properties: {
    orchestrationMode: 'Flexible'
    singlePlacementGroup: false
    platformFaultDomainCount: platformFaultDomainCount

    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'myVm'
        customData: imdsCustomDataBase64
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration) // TODO: workaround for https://github.com/Azure/bicep/issues/449
        // windowsConfiguration: {
        //   timeZone: 'Pacific Standard Time'
        // }
        //licenseType: 'Windows_Server'
      }
      networkProfile: {
        networkApiVersion: networkApiVersion
        networkInterfaceConfigurations: [
          {
            name: '${vmssname}NicConfig01'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              ipConfigurations: [
                {
                  name: '${vmssname}IpConfig'
                  properties: {
                    // publicIPAddressConfiguration: {
                    //   name: '${vmssname}PipConfig'
                    //   properties:{
                    //     publicIPAddressVersion: 'IPv4'
                    //     idleTimeoutInMinutes: 5
                    //   }
                    // }
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                    loadBalancerBackendAddressPools: lbBackendPoolArray
                    applicationGatewayBackendAddressPools: appGwBackendPoolArray
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: diagStorageAccount.properties.primaryEndpoints.blob
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'AppHealthExtension'
            properties: {
              publisher: 'Microsoft.ManagedServices'
              type: 'ApplicationHealthLinux'
              autoUpgradeMinorVersion: true
              typeHandlerVersion: '1.0'
              settings: {
                protocol: 'http'
                port: 80
                requestPath: '/health'
              }
            }
          }
        ]
      }
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          //osType: 'Windows'
          createOption: 'FromImage'
          //deleteOption: 'Delete' // deleteOption will be set to delete by default
          caching: 'ReadWrite'
          diskSizeGB: 256
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        // imageReference: {
        //   publisher: 'MicrosoftWindowsServer'
        //   offer: 'WindowsServer'
        //   sku: '2019-Datacenter'
        //   version: 'latest'
        // }
      }
      // Use spot instances for testing
      priority: priority
      evictionPolicy: spotEvictionPolicy
      billingProfile: spotBillingProfile
      // Enable Terminate notification
      scheduledEventsProfile: {
        terminateNotificationProfile: {
          notBeforeTimeout: 'PT5M'
          enable: true
        }
      }
    }
    automaticRepairsPolicy: {
      enabled: true
      gracePeriod: 'PT30M'
    }   
    // Ultra SSD not yet supported on VMSS Flex level
    // This can be assigned at the individual VM level
    // additionalCapabilities: {
    //   ultraSSDEnabled: false
    // }

    // Managed identity. Only UserAssigned identity can be passed in to VMSS Profile
    // UserAssigned identity must be created before it can be assigned here
    // SystemAssigned identity can be assigned at the individual VM level
    // identity: {
    //   type: 'UserAssigned'
    // }
  }
}

output vmssid string = vmssflex.id
