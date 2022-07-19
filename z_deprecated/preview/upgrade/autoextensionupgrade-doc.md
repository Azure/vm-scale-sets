# Azure VM scale set automatic extension upgrades

Automatic extension upgrade is a preview feature for Azure VM scale sets which automatically upgrades VM extensions to the lastest type handler version as new become available.

Automatic extension upgrade has the following characteristics during preview:
- Once configured, the latest minor versions are automatically applied to scale set extensions without user intervention, but only to extensions with autoUpgradeMinorVersion set to true.
- Upgrades batches of instances in a rolling manner each time a new version is published by the publisher.
- Service Fabric clusters are not eligible for automatic extension upgrades yet.


## Application Health

Automatic extension upgrades have the same application health model as [automatic OS upgrades](./autoosupgrade-doc.md). However, there is one difference. Automatic OS upgrades use the load balaner health probe as the health signal. Automatic extension upgrades use both the load balancer health probe and the extension provisioning state as the health signal. This means that automatic extension upgrades will stop partway if either the load balancer health probe fails or the extensions on the scale set fail.

## How to configure automatic extension updates

Please provide us with your subscription ID, and we can enroll the scale sets in your subscription to use automatic extension updates. All scale sets in the subscription will be enrolled.


## Checking the status of an automatic extension upgrade

To check the status of the most recent rolling upgrade performed on your scale set using Azure PowerShell (4.4.1 or later):

```powershell
Get-AzureRmVmssRollingUpgrade -ResourceGroupName rgname -VMScaleSetName vmssname
```

To check the status using Azure CLI (2.0.20 or later):

```azure-cli
az vmss rolling-upgrade get-latest --name vmssname --resource-group rgname
```

To check the status using the REST API:

`GET /subscriptions/subscription_id/resourceGroups/resource_group/providers/Microsoft.Compute/virtualMachineScaleSets/scaleset_name/rollingUpgrades/latest?api-version=2017-12-01`

Note that this latest rolling upgrade could be an automatic extension upgrade or an automatic OS upgrade.

## Manually triggering an extension rolling upgrade

To manually trigger an extension rolling upgrade, you can do a POST on `/subscription/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{resourceName}/ExtensionRollingUpgrade?api-version=2017-12-01`. To force the upgrade on all VMs in the scale set, even if it causes health probe or extension failures, add the `forceExtensionUpgrade` query parameter:

POST on `/subscription/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{resourceName}/ExtensionRollingUpgrade?api-version=2017-12-01&forceExtensionUpgrade=true`
