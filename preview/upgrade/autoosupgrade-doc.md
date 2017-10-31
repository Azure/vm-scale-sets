# Azure VM scale set automatic OS upgrades

Automatic OS image upgrade is a new preview feature for Azure VM scale sets which automatically upgrades all VMs to the latest OS image.

Automatic OS upgrade has the following characteristics:
- Once configured, the latest OS image published by image publishers is automatically applied to the scale set without user intervention.
- Upgrades batches of instances in a rolling manner each time a new platform image is published by the publisher.
- Integrates with application health probe (optional, but highly recommended for safety).
- Works for all VM sizes.
- Works for Windows and Linux platform images.
- You can opt out of automatic upgrades at any time (OS Upgrades can be initiated manually as well).
- The OS Disk of a VM is replaced with the new OS Disk created with latest image version. Configured extensions and custom data scripts are run, while persisted data disks are retained.


## Preview notes 
- While in preview, automatic OS upgrades only support 3 OS SKUs (see below), and have no SLA or guarantees. We would love to get your feedback, but it is recommended to not enable them on production critical workloads during preview.
- Support for scale sets in Service Fabric clusters is coming soon.
- Azure autoscale is __not__ currently supported with VM scale set automatic OS upgrade.
- Azure disk encryption (currently in preview) is __not__ currently supported with VM scale set automatic OS upgrade.
- Portal experience coming soon.

## Pre-requisites
Automatic OS upgrades may be enabled when the following conditions are met:

	The OS image is a platform Image, and in the VMSS model the Version = _latest_.
    
    The following SKUs are currently supported (more will be added):
	
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2012-R2-Datacenter
		Version: latest
		
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2016-Datacenter
		Version: latest

		Publisher: Canonical
		Offer: UbuntuServer
		Sku: 16.04-LTS
		Version: latest


## Application Health

During an OS Upgrade, VM instances in a VMSS are upgraded one batch at a time. The upgrade should continue only if the customer application is healthy on the upgraded VM instances. Therefore it is recommended that the application provide health signals to the VMSS OS Upgrade engine. By default, during OS Upgrades the platform considers VM Powerstate and Extension Provisioning State to determine if a VM instance is healthy after an upgrade. During the OS Upgrade of a VM instance, the OS Disk on a VM instance is replaced with a new disk based on latest image version. After the OS Upgrade has completed, the configured extensions are run on these VMs. Only when all the extensions on a VM have Provision Success state, is the application considered healthy. 

A VMSS can can optionally be configured with Application Health Probes to provide the platform with accurate information on the ongoing state of the application. Application Health Probes are Custom Load Balancer Probes which are used as a health signal. The customer application on a VMSS VM instance can respond to external HTTP or TCP requests indicating whether it is healthy. For more documentation on how Custom Load Balancer Probes work <a href='https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-custom-probe-overview'>follow this link</a>. An Application Health Probe is not required for automatic OS upgrades, but it is highly recommended.


### Configuring a Custom Load Balancer Probe as Application Health Probe on a VMSS


As a best practice, a new load-balancer probe should be created explicitly for VMSS health. The same endpoint for an existing HTTP probe or TCP probe may be used, but a health probe may require different behavior than that of a traditional load-balancer probe. For example, a traditional load-balancer probe may return unhealthy if the load on the instance is too high, whereas that may not be appropriate for determining the instance health during an automatic OS upgrade. The probe should also be set up to have a high probing rate. < Sean: Nathan, what is the restriction that we enforce here?>

The load-balancer probe can be referenced in the networkProfile of the VMSS and can be associated with either an internal or public facing load-balancer:
```
"networkProfile": {
  "healthProbe" : {
    "id": "[concat(variables('lbId'), '/probes/', variables('sshProbeName'))]"
  },
  "networkInterfaceConfigurations":
  ...
```
### 

## Registering to use Automatic OS Upgrade
You can register for the automated OS upgrade feature by running these Azure PowerShell commands:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName AutoOSUpgradePreview
# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
```

To use application health probes, register for application health feature by running these Azure PowerShell commands:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Network -FeatureName AllowVmssHealthProbe
# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network
```

## Enforcing an OS image upgrade policy across your subscription
For safe upgrades, it is highly recommended to enforce an upgrade policy, which can include require application health probes, across your subscription. You can do this by applying the following ARM policy to your subscription, which will reject deployments that do not have automated OS image upgrade settings configured:
```
1. Get builtin ARM policy definition: 
$policyDefinition = Get-AzureRmPolicyDefinition -Id "/providers/Microsoft.Authorization/policyDefinitions/465f0161-0087-490a-9ad9-ad6217f4f43a"

2. Assign policy to a subscription: 
New-AzureRmPolicyAssignment -Name "Enforce automatic OS upgrades with app health checks" -Scope "/subscriptions/<SubscriptionId>" -PolicyDefinition $policyDefinition

```

## How to configure auto-updates

- Ensure the automaticOSUpgrade property is set to true in the VMSS model definition. 

## Automatic OS Upgrade Execution

Expanding on the description in the Application Health section, VMSS OS Upgrades executes following steps:

1) If more than 20% of instances are Unhealthy, stop the upgrade; otherwise proceed.
2) Identify the next batch of VM instances to upgrade, with a batch having maximum 20% of total instance count.
3) Upgrade the OS of the next batch of VM instances.
4) If more than 20% of upgraded instances are Unhealthy, stop the upgrade; otherwise proceed.
5) If the customer has configured Application Health Probes, the upgrade will continue immediately to the next batch; otherwise, it will wait 30 minutes before moving on to the next batch.
6) If there are remaining instances to upgrade, goto step 1) for the next batch; otherwise the upgrade is complete.

The VMSS OS Upgrade Engine checks for the overall VM instance health before upgrading every batch. While upgrading a batch, there may be other concurrent Planned or Unplanned maintenance happening in Azure Datacenters that may impact availbility of your VMs. Hence, it is possible that temporarily more than 20% instances may be down. In such cases, at the end of current batch VMSS will stop the upgrade.

## VMSS Rolling Upgrades

VMSS Automatic OS Upgrades, leverages a Rolling Upgrade Engine underneath, that updates a Batch of VM instances at a time, checks the instance health, and drives the update to completion. It is now possible for the customers to leverage this Rolling Upgrade, to drive their own updates to a VMSS.
<Sean: we need to explain that this configuration is not used during Automatic OS Upgrades, otherwise people may think that these policies override the Automatic OS Upgrade defaults>

- Syntax
```

"upgradePolicy": {
    "mode": "Rolling", // Must be "Rolling" for manual upgrades; can be anything for automatic OS upgrades
    "automaticOSUpgrade": "true" or "false",
	  "rollingUpgradePolicy": {
		  "maxBatchInstancePercent": 20,
		  "maxUnhealthyInstancePercent": 20,
		  "maxUnhealthyUpgradedInstancePercent": 20,
		  "pauseTimeBetweenBatches": "PT0S"
	  }
}
```
### Property descriptions
__maxBatchInstancePercent__ – 
The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch. As this is a maximum, unhealthy instances in previous or future batches can cause the percentage of instances in a batch to decrease to ensure higher reliability.
The default value for this parameter is 20.

__pauseTimeBetweenBatches__ – 
The wait time between completing the update for all virtual machines in one batch and starting the next batch. 
The time duration should be specified in ISO 8601 format for duration (https://en.wikipedia.org/wiki/ISO_8601#Durations)
The default value is 0 seconds (PT0S).

__maxUnhealthyInstancePercent__ -         
The maximum percentage of the total virtual machine instances in the VM Scale Set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.
The default value for this parameter is 20.

__maxUnhealthyUpgradedInstancePercent__ – 
The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state. This check will happen after each batch is upgraded. If this percentage is ever exceeded, the rolling update aborts.
The default value for this parameter is 20.

## Adding a load-balancer probe for determining health of the rolling upgrade
Before the VMSS can be created or moved into rolling upgrade mode, a load-balancer probe used to determine VM instance health must be added to the VM Scale Set in the networkProfile.healthProbe.id property.


## Example templates

### Automatic rolling upgrades - Ubuntu 16.04-LTS

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fautoupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Checking automatic rolling upgrade status

GET on `/subscriptions/subscription_id/resourceGroups/resource_group/providers/Microsoft.Compute/virtualMachineScaleSets/vmss_name/rollingUpgrades/latest?api-version=2017-03-30`

```
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
