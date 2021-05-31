// Deploy VMSS Flex into a subscription. 
// This will create and deploy resources at subscription scope into Resource Group rgName
// bicep template. Bicep reference: https://aka.ms/bicep
// az deployment sub create -n myflexdeploy -l eastus2euap -f main.vmssflex.bicep --parameters rgName=myResourceGroup vmssName=vmssflex01 vmCount=2
targetScope= 'subscription'

param rgName string = 'vmss-flex-cassandra-demo'
param region string = 'southcentralus'
param appGwName string = 'webAppGateway'
param lbName string = 'biz-lb'

param dataVmssName string = 'data-vmss'
param vmCount int = 3
@allowed([
  1
  2
  3
  5
])
param platformFaultDomainCount int = 1


param sshKeyName string = 'caroldanvers-westus'
param rgSshKeys string = 'mySSHKeys'

var appGwBackendPools = []
var slbBackendPools = []
var vnetName= 'ra-ntier-vnet'

resource deployrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: region
}
module basenetwork './network/basenetwork.bicep' = {
  name: 'basenetwork'
  scope: resourceGroup(deployrg.name)
  params: {
    virtualNetworkName: vnetName
  }
}

module appgw './network/appgw.bicep' = {
  name: 'appgw'
  scope: resourceGroup(deployrg.name)
  params: {
    appGwName: appGwName
    appGwSubnetId: basenetwork.outputs.vnetSubnetArray[4].id
   }
}

module slb './network/slb.bicep' = {
  name: 'slb'
  scope: resourceGroup(deployrg.name)
  params: {
    slbName: lbName
  }
}

module vmssFlexDataTier './compute/vmssflex.bicep' = {
  name: 'data-vmss'
  scope: resourceGroup(deployrg.name)
  params: {
    vmssname: 'data-vmss'
    vmCount: 6
    vmSize: 'Standard_D16s_v4'
    platformFaultDomainCount: 3
    subnetId: basenetwork.outputs.vnetSubnetArray[2].id
    // appGwBackendPoolArray: appgw.outputs.appGwBackendPoolArray
    // lbBackendPoolArray: slbBackendPools
  }
}

module vmssFlexBizTier './compute/vmssflex.bicep' = {
  name: 'biz-vmss'
  scope: resourceGroup(deployrg.name)
  params: {
    vmssname: 'biz-vmss'
    vmCount: 3
    vmSize: 'Standard_D2s_v4'
    platformFaultDomainCount: 1
    subnetId: basenetwork.outputs.vnetSubnetArray[1].id
    lbBackendPoolArray: slb.outputs.slbBackendPoolArray
  }
}

module vmssFlexWebTier './compute/vmssflex.bicep' = {
  name: 'web-vmss'
  scope: resourceGroup(deployrg.name)
  params: {
    vmssname: 'web-vmss'
    vmCount: 3
    vmSize: 'Standard_D2s_v4'
    platformFaultDomainCount: 1
    subnetId: basenetwork.outputs.vnetSubnetArray[0].id
    appGwBackendPoolArray: appgw.outputs.appGwBackendPoolArray
  }
}

// // Enable autoscaling on the VMSS Flex
module autoscaler './compute/vmssautoscale.bicep' = {
  name: 'autoscale'
  scope: resourceGroup(deployrg.name)
  params:{
    vmssId: vmssFlexWebTier.outputs.vmssid
  } 
}






// module sshkey './compute/ssh.bicep' = {
//   name: 'sshkey'
//   scope: resourceGroup('${rgSshKeys}')
//   params: {
//     sshKeyName: sshKeyName
//   }
// }

// module vmss './compute/vmssflex.bicep' = {
//   name: 'vmss-bicep'
//   scope: resourceGroup(deployrg.name)
//   params: {
//     vmssname: vmssName
//     vmCount: vmCount
//     platformFaultDomainCount: platformFaultDomainCount
//     zones: zones
//     subnetId: basenetwork.outputs.vnetSubnetArray[0].id
//     // appGwBackendPoolArray: appgw.outputs.appGwBackendPoolArray
//     // lbBackendPoolArray: slbBackendPools
//   }
// }
// // Enable autoscaling on the VMSS Flex
// module autoscaler './compute/vmssautoscale.bicep' = {
//   name: 'autoscale'
//   scope: resourceGroup(deployrg.name)
//   params:{
//     vmssId: vmss.outputs.vmssid
//   } 
//}

//If you want to add a standalone VM to the scale set
// module vm './flexvm-datadiskloop.bicep' = {
//   name: 'vm-flex'
//   scope: resourceGroup(deployrg.name)
//   params: {
//     vmName: vmName
//     vmssName: vmssName
//     vmSize: 'Standard_DS1_v2'
//     zone: myzone
//     subnetId: basenetwork.outputs.vnetSubnetArray[0].id
//     appGwBackendPoolArray: appGwBackendPools
//     lbBackendPoolArray: slbBackendPools
//     adminUsername: 'fisteele'
//     authenticationType: 'sshPublicKey'
//     adminPasswordOrKey: sshkey.outputs.publickey
//     // authenticationType: 'password'
//     // adminPasswordOrKey: 'DoN0TUs3ThisT3rr!bleP@ssw0rd'
//   }
// }
