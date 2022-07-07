# Azure VM scale set automatic OS upgrades

Automatic OS image upgrade is a preview feature for Azure VM scale sets which automatically upgrades all VMs to the latest OS image.

Automatic OS upgrade has the following characteristics:
- Once configured, the latest OS image published by image publishers is automatically applied to the scale set without user intervention.
- Upgrades batches of instances in a rolling manner each time a new platform image is published by the publisher.
- Integrates with application health probe (optional, but highly recommended for safety).
- Works for all VM sizes.
- Works for Windows and Linux platform images.
- You can opt out of automatic upgrades at any time (OS Upgrades can be initiated manually as well).
- The OS Disk of a VM is replaced with the new OS Disk created with latest image version. Configured extensions and custom data scripts are run, while persisted data disks are retained.


## Preview notes 
- While in preview, automatic OS upgrades only support 3 OS SKUs (see below), and have no SLA or guarantees. It is recommended to not enable them on production critical workloads during preview.
- Support for scale sets in Service Fabric clusters is coming soon.
- Azure disk encryption (currently in preview) is __not__ currently supported with VM scale set automatic OS upgrade.
- Portal experience coming soon.

## Registering to use Automatic OS Upgrade
You can register for the automated OS upgrade feature by running these Azure PowerShell commands:

```powershell
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName AutoOSUpgradePreview

# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
```

To use application health probes (recommended), register for application health feature by running these Azure PowerShell commands:

```powershell
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Network -FeatureName AllowVmssHealthProbe

# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network
```

## Supported OS images

Only OS platform images are currently supported (i.e. not custom images you created yourself). The _version_ property must be set to _latest_.

The following SKUs are currently supported (more will be added):
	
| Publisher               | Offer         |  Sku                                  | Version  |
|-------------------------|---------------|---------------------------------------|----------|
| MicrosoftWindowsServer  | WindowsServer | 2012-R2-Datacenter                    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter                       | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter-gensecond             | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter-gs                    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter-smalldisk             | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter-with-containers       | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2016-Datacenter-with-containers-gs    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter                       | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-core                  | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-core-with-containers  | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-gensecond             | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-gs                    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-smalldisk             | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-with-containers       | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2019-Datacenter-with-containers-gs    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter                       | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-smalldisk             | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-azure-edition         | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-core                  | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-core-smalldisk        | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-g2                    | latest   |
| MicrosoftWindowsServer  | WindowsServer | 2022-Datacenter-smalldisk-g2          | latest   |
| Canonical               | UbuntuServer  | 20.04-LTS                             | latest   |
| Canonical               | UbuntuServer  | 20.04-LTS-Gen2                        | latest   |
| Canonical               | UbuntuServer  | 18.04-LTS                             | latest   |
| Canonical               | UbuntuServer  | 18.04-LTS-Gen2                        | latest   |
| MicrosoftCblMariner     | Cbl-Mariner   | cbl-mariner-1                         | latest   |
| MicrosoftCblMariner     | Cbl-Mariner   | 1-Gen2                                | latest   |
| MicrosoftCblMariner     | Cbl-Mariner   | cbl-mariner-2                         | latest   |
| MicrosoftCblMariner     | Cbl-Mariner   | cbl-mariner-2-Gen2                    | latest   |


## Application Health

During an OS Upgrade, VM instances in a scale set are upgraded one batch at a time. The upgrade should continue only if the customer application is healthy on the upgraded VM instances. Therefore it is recommended that the application provide health signals to the scale set OS Upgrade engine. By default, during OS Upgrades the platform considers VM power state and extension provisioning State to determine if a VM instance is healthy after an upgrade. During the OS Upgrade of a VM instance, the OS Disk on a VM instance is replaced with a new disk based on latest image version. After the OS Upgrade has completed, the configured extensions are run on these VMs. Only when all the extensions on a VM are successfully provisioned, is the application considered healthy. 

A scale set can optionally be configured with Application Health Probes to provide the platform with accurate information on the ongoing state of the application. Application Health Probes are Custom Load Balancer Probes which are used as a health signal. The application running on a scale set VM instance can respond to external HTTP or TCP requests indicating whether it is healthy. For more documentation on how Custom Load Balancer Probes work refer to (Understand load balancer probes)[https://docs.microsoft.com/azure/load-balancer/load-balancer-custom-probe-overview]. An Application Health Probe is not required for automatic OS upgrades, but it is highly recommended.

Note: if the scale set is configured to use multiple placement groups, probes using a Standard Load Balancer will need to be used[https://docs.microsoft.com/azure/load-balancer/load-balancer-standard-overview].

### Configuring a Custom Load Balancer Probe as Application Health Probe on a scale set

As a best practice, a new load-balancer probe should be created explicitly for scale set health. The same endpoint for an existing HTTP probe or TCP probe may be used, but a health probe may require different behavior than that of a traditional load-balancer probe. For example, a traditional load balancer probe may return unhealthy if the load on the instance is too high, whereas that may not be appropriate for determining the instance health during an automatic OS upgrade. The probe should also be set up to have a high probing rate of less than 2 minutes.

The load-balancer probe can be referenced in the networkProfile of the scale set and can be associated with either an internal or public facing load-balancer:

```json
"networkProfile": {
  "healthProbe" : {
    "id": "[concat(variables('lbId'), '/probes/', variables('sshProbeName'))]"
  },
  "networkInterfaceConfigurations":
  ...
```

## Enforcing an OS image upgrade policy across your subscription
For safe upgrades, it is highly recommended to enforce an upgrade policy, which can include require application health probes, across your subscription. You can do this by applying the following ARM policy to your subscription, which will reject deployments that do not have automated OS image upgrade settings configured:

1. Get builtin ARM policy definition:

```powershell
$policyDefinition = Get-AzureRmPolicyDefinition -Id "/providers/Microsoft.Authorization/policyDefinitions/465f0161-0087-490a-9ad9-ad6217f4f43a"
```

2. Assign policy to a subscription:

```powershell
New-AzureRmPolicyAssignment -Name "Enforce automatic OS upgrades with app health checks" -Scope "/subscriptions/<SubscriptionId>" -PolicyDefinition $policyDefinition
```

## How to configure auto-updates

- Ensure the automaticOSUpgrade property is set to true in the scale set model definition.
- To set this property using PowerShell (4.4.1 or later):

```powershell
$rgname = myresourcegroup
$vmssname = myvmss
$vmss = Get-AzureRmVMss -ResourceGroupName $rgname -VmScaleSetName $vmssname
$vmss.UpgradePolicy.AutomaticOSUpgrade = $true
Update-AzureRmVmss -ResourceGroupName $rgname -VMScaleSetName $vmssname -VirtualMachineScaleSet $vmss
```

- To set this property using Azure CLI (2.0.20 or later):

```azure-cli
rgname="myresourcegroup"
vmssname="myvmss"
az vmss update --name $vmssname --resource-group $rgname --set upgradePolicy.AutomaticOSUpgrade=true
```

## Checking the status of an automatic OS upgrade

To check the status of the most recent OS upgrade performed on your scale set using Azure PowerShell (4.4.1 or later):

```powershell
Get-AzureRmVmssRollingUpgrade -ResourceGroupName rgname -VMScaleSetName vmssname
```

To check the status using Azure CLI (2.0.20 or later):

```azure-cli
az vmss rolling-upgrade get-latest --name vmssname --resource-group rgname
```

### REST API
GET on `/subscriptions/subscription_id/resourceGroups/resource_group/providers/Microsoft.Compute/virtualMachineScaleSets/scaleset_name/rollingUpgrades/latest?api-version=2017-03-30`

### Example upgrade status output
```json
{
  "properties": {
    "policy": {
      "maxBatchInstancePercent": 20,
      "maxUnhealthyInstancePercent": 5,
      "maxUnhealthyUpgradedInstancePercent": 5,
      "pauseTimeBetweenBatches": "PT0S"
    },
    "runningStatus": {
      "code": "Completed",
      "startTime": "2017-06-16T03:40:14.0924763+00:00",
      "lastAction": "Start",
      "lastActionTime": "2017-06-22T08:45:43.1838042+00:00"
    },
    "progress": {
      "successfulInstanceCount": 3,
      "failedInstanceCount": 0,
      "inprogressInstanceCount": 0,
      "pendingInstanceCount": 0
    }
  },
  "type": "Microsoft.Compute/virtualMachineScaleSets/rollingUpgrades",
  "location": "southcentralus"
}
```

## Automatic OS Upgrade Execution

Expanding on the description in the Application Health section, scale set OS Upgrades execute following steps:

1) If more than 20% of instances are Unhealthy, stop the upgrade; otherwise proceed.
2) Identify the next batch of VM instances to upgrade, with a batch having maximum 20% of total instance count.
3) Upgrade the OS of the next batch of VM instances.
4) If more than 20% of upgraded instances are Unhealthy, stop the upgrade; otherwise proceed.
5) If the customer has configured Application Health Probes, the upgrade will wait up to 5 minutes for probes to become healthy, then will immediately continue onto the next batch; otherwise, it will wait 30 minutes before moving on to the next batch.
6) If there are remaining instances to upgrade, goto step 1) for the next batch; otherwise the upgrade is complete.

The scale set OS Upgrade Engine checks for the overall VM instance health before upgrading every batch. While upgrading a batch, there may be other concurrent Planned or Unplanned maintenance happening in Azure Datacenters that may impact availbility of your VMs. Hence, it is possible that temporarily more than 20% instances may be down. In such cases, at the end of current batch, the scale set upgrade will stop and retried at a later time.

## Example template

### <a href='https://github.com/Azure/vm-scale-sets/blob/master/preview/upgrade/autoupdate.json'>Automatic rolling upgrades - Ubuntu 16.04-LTS</a>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fautoupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


