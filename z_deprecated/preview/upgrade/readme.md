# Azure VM scale set automatic upgrade and rolling upgrade preview

> **Warning**
> This content is deprecated. Please refer to the [official VMSS documentation](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview).

Last update: 12/13/17.

You need to register for the automated OS upgrade feature in order to use it:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName AutoOSUpgradePreview
# Wait 10 minutes until state transitions to 'Registered'
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute

```

## Notes 
- Do not use for production workloads while in preview - no SLA or guarantees.
- Initially automatic OS upgrades only support 3 OS skus (see below)
- Autoscale is not yet supported, and will fail when auto or rolling upgrade is configured.

## Pre-requisites
Automatic OS upgrades are offered when the following conditions are met:

	The OS image is a platform Image only with Version = _latest_.
    
    The following SKUs during the intial preview (more will be added):
```
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2012-R2-Datacenter
		Version: latest
		
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2016-Datacenter
		Version: latest

		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2016-Datacenter-smalldisk
		Version: latest

		Publisher: Canonical
		Offer: UbuntuServer
		Sku: 16.04-LTS
		Version: latest
```

## When automatic upgrade happens
- Automatic OS upgrades are triggered when the publisher for your OS sku releases a new image version.

## Enforcing an OS image upgrade policy across your subscription
For safe upgrades it is highly recommended to enforce an upgrade policy, which includes an application health probe, across your subscription. You can do this by applying apply the following ARM policy to your subscription, which will reject deployments that do not have automated OS image upgrade settings configured:
```
{
  "if": {
    "anyOf": [
      {
        "field": "Microsoft.Compute/VirtualMachineScaleSets/properties.upgradePolicy.automaticOSUpgrade",
        "exists": "False"
      },
      {
        "field": "Microsoft.Compute/VirtualMachineScaleSets/properties.upgradePolicy.automaticOSUpgrade",
        "equals": "False"
      },
      {
        "field": "Microsoft.Compute/VirtualMachineScaleSets/properties.virtualMachineProfile.networkProfile.healthProbe.id",
        "exists": "False"
      }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}
```

## How to configure auto-updates

- Sign up for the limited preview 

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

## How to manually trigger a rolling upgrade

1) Make a post request to `/subscriptions/<subId>/resourceGroups/<rgName>/Microsoft.Compute/virtualMachineScaleSets/<vmssName>/osRollingUpgrade` 
Calls to this API will only change the OS disks of your machine if there is a new OS to update your VMs to, and it will conform to the rolling upgrade policies you specify in the rollingUpgradePolicy section of the vmss configuration.

2) Change the OS version in your VMSS.

Note: you can have the OS version set to "latest" in your VMSS properties. However a manually triggered rolling upgrade will only take place after a newer version of the corresponding OS image has been published.

CRP API version is 2017-03-30

## How to manually trigger a rolling reimage
Sometimes you may want to just re-set your existing scale set to factory settings. For example you have a stateless app and want to trigger the VMs extensions to re-run. As part of this preview, you can trigger a rolling reimage of a scale set with the following REST API call: `/virtualMachineScaleSet/<scaleSetName>/osRollingUpgrade?forceReimage=true`

## Manual rolling upgrade FAQ

Q. When a particular batch of VMs is picked for upgrade. Does this model ensure the existing HTTP connections are allowed to drain, and no new HTTP requests will be routed to the VMs in this batch, till deployment is complete? 

A. The next batch does not start upgrading until the previous batch has completed being upgraded, and no new connections will be sent to VMs failing the health probe. However, there is currently no way to drain the existing connections to the VMs that are taken down by a rolling upgrade.

## Example templates

### Automatic rolling upgrades - Ubuntu 16.04-LTS

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fautoupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Automatic rolling upgrades - Ubuntu 17.10-DAILY for testing

Note: You need a special feature flag on your subscription to use the daily build with automatic updates.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fdailyupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Manual rolling upgrades

Note: You need to self-register for this:
```
Register-AzureRmProviderFeature -FeatureName AllowVmssHealthProbe -ProviderNamespace Microsoft.Network
```

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fmanualupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Zone redundant manual rolling upgrades (limited preview - requires flag on subscription)

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fzonesmanualrolling.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Example automatic rolling upgrade status

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
