# Azure VM scale set automatic OS upgrades

Automatic OS image upgrade is a new preview feature for Azure VM scale sets which supports automatic upgrade of VM images across a scale set.

Automatic OS upgrade has the following characteristics:
- Once configured, the latest OS image provided by publishers is automatically applied to the scale set.
- Upgrades instances in a rolling manner one batch at a time each time a new platform image is provided by the publisher.
- Integrates with application health probe (optional but highly recommended).
- Works for all VM and scale set sizes.
- Works for Windows and Linux platform images.
- You can opt out of automatic upgrades at any time


## Preview notes 
- While in preview, automatic OS upgrades only support 3 OS skus (see below), and have no SLA or guarantees. We would love to get your feedback, but do not use for production critical workloads.
- Support for scale sets in Service Fabric clusters is coming soon.
- Azure autoscale is __not__ currently supported with VM scale set automatic OS upgrade.
- Portal experience coming soon.

## Pre-requisites
Automatic OS upgrades are offered when the following conditions are met:

	The OS image is a platform Image only with Version = _latest_.
    
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



## Enforcing an OS image upgrade policy across your subscription
For safe upgrades it is highly recommended to enforce an upgrade policy, which includes an application health probe, across your subscription. You can do this by applying apply the following ARM policy to your subscription, which will reject deployments that do not have automated OS image upgrade settings configured:
```
# ravi TBD
```

## Getting started
You can register for the automated OS upgrade feature by running these Azure PowerShell commands:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName AutoOSUpgradePreview
# Wait 10 minutes until state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
```

## How to configure auto-updates

- Ensure automaticOSUpgrade is set to true. 
- Syntax
```
"upgradePolicy": {
    "mode": "Rolling", // Must be "Rolling" for manual upgrades; can be anything for automatic OS upgrades
    "automaticOSUpgrade": "true" or "false",
	  "rollingUpgradePolicy": {
		  "maxBatchInstancePercent": 20,
		  "maxUnhealthyInstancePercent": 20,
		  "maxUnhealthyUpgradedInstancePercent": 5,
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
The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.
The default value for this parameter is 20.

__maxUnhealthyUpgradedInstancePercent__ – 
The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state. This check will happen after each batch is upgraded. If this percentage is ever exceeded, the rolling update aborts.
The default value for this parameter is 20.

## Adding a load-balancer probe for determining health of the rolling upgrade
Before the VMSS can be created or moved into rolling upgrade mode, a load-balancer probe used to determine VM instance health must be added.

As a best practice, a new load-balancer probe should be created explicitly for VMSS health. The same endpoint for an existing HTTP probe or TCP probe may be used, but a health probe may require different behavior than that of a traditional load-balancer probe. For example, a traditional load-balancer probe may return unhealthy if the load on the instance is too high, whereas that may not be appropriate for determining the instance health during a rolling upgrade. The probe should also be set up to have a high probing rate.

The load-balancer probe can be referenced in the networkProfile of the VMSS and can be associated with either an internal or public facing load-balancer:
```
"networkProfile": {
  "healthProbe" : {
    "id": "[concat(variables('lbId'), '/probes/', variables('sshProbeName'))]"
  },
  "networkInterfaceConfigurations":
  ...
```
A load-balancer probe is not required for automatic OS upgrades, but it is highly recommended.

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
