# Azure VM scale set automatic upgrade and rolling upgrade preview

Welcome to the VM scale set automatic OS image update, and manually triggered rolling update preview. 

You can try the rolling upgrade, which is in public preview, now. The automated OS image update preview is currently a limited preview - you won't be able to use this feature unless your Azure subscription is registered to use it.


You can register for the automated OS upgrade feature using this command:
```
Register-AzureRmProviderFeature -FeatureName AutoOSUpgradePreview -ProviderNamespace Microsoft.Compute
```

Note: While in limited preview, automatic OS upgrades only support 3 OS skus (see below), and have no SLA or guarantees. We would love to get your feedback, but do not use for production workloads.

Last update: 10/14/17.

## Pre-requisites
Automatic OS upgrades are offered when the following conditions are met:

	The OS image is a platform Image only with Version = _latest_.
    
    The following SKUs during the intial preview (more will be added):
	
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

	For testing purposes you can use this nightly build during preview as well. This requires a separate feature flag, so please let us know if you plan to use other than the 3 OS versions above:

		Publisher: Canonical
		Offer: UbuntuServer
		Sku: 16.04-DAILY-LTS
		Version: latest


## When automatic upgrade happens
- Automatic OS upgrades are triggered when the publisher for your OS sku releases a new image version.

## How to configure auto-updates

- Sign up for the limited preview 

- Ensure automaticOSUpgrade is set to true. 

- Syntax
```
"upgradePolicy": {
    "mode": "Rolling", // Must be "Rolling" for manual upgrades; can be anything for automatic OS upgrades
    "automaticOSUpgrade": "true" or "false",
	"rollingUpgradePolicy": {
		"maxBatchInstancePercent": 5,
		"maxUnhealthyInstancePercent": 5,
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

A. We do not move onto the next batch until the previous batch has completed being upgraded. 
In order to get the behavior that you are requesting you will need to add a custom health probe for your load balancer, and you need to start reporting unhealthy on your custom health probe when your OS receives a shutdown notification. You need to delay OS shutdown until you are no longer receiving traffic (you have been reporting unhealthy on your health probe for long enough).

There is no in built mechanism, the recommendation is to stop and start traffic using custom load balancer probes.

You are right about health probes not supporting http, although it is my understanding that that feature may be forthcoming (not sure what the product plan is there though)

The health probe need not be you website though, you can create a synthetic API that responds healthy always unless you are undergoing an update, or about to undergo an update or reboot.

There is no in built mechanism for draining, it is up to your app to stop and start traffic using custom loadbalancer probes. E.g. you can create a synthetic API that responds healthy always unless you are undergoing an update, or about to undergo an update or reboot.


## Example templates

### Automatic rolling upgrades - Ubuntu 16.04-LTS

Note: You need to self-register for this:
```
Register-AzureRmProviderFeature -FeatureName AutoOSUpgradePreview -ProviderNamespace Microsoft.Compute
```

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fautoupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Automatic rolling upgrades - Ubuntu 16.04-DAILY-LTS for testing

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
