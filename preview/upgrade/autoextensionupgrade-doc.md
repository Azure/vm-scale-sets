# Azure VM scale set automatic extension upgrades

Automatic extension upgrade is a preview feature for Azure VM scale sets which automatically upgrades all VM extensions to the lastest type handler version as the version becomes available in the platform.

Automatic extension upgrade has the following characteristics:
- Once configured, the latest extension type handler patches published by extension publishers are automatically applied to the scale set without user intervention.
- If autoUpgradeMinorVersion is set to true, new minor versions of the extension type handler are also automatically applied to the scale set without user intervention.
- Upgrades batches of instances in a rolling manner each time a new version is published by the publisher.
- Integrates with application health probe (optional, but highly recommended for safety).
- Works for all extensions.
- Works for all VM sizes.
- Works for all VM images (platform and custom).


## Preview notes 
- While in preview, automatic extension upgrades have no SLA or guarantees. It is recommended to not enable them on production critical workloads during preview.
- Portal experience coming soon.

## Application Health

Automatic extension upgrades have the same application health model as [automatic OS upgrades](./autoosupgrade-doc.md).

## How to configure automatic extension updates

Please provide us with your subscription ID, and we can enroll the scale sets in your subscription to use automatic extension updates. All scale sets in the subscription will be enrolled.


## Checking the status of an automatic extension upgrade

To check the status of the most recent extension upgrade performed on your scale set using Azure PowerShell (4.4.1 or later):

```powershell
Get-AzureRmVmssRollingUpgrade -ResourceGroupName rgname -VMScaleSetName vmssname
```

To check the status using Azure CLI (2.0.20 or later):

```azure-cli
az vmss rolling-upgrade get-latest --name vmssname --resource-group rgname
```

### REST API
GET on `/subscriptions/subscription_id/resourceGroups/resource_group/providers/Microsoft.Compute/virtualMachineScaleSets/scaleset_name/rollingUpgrades/latest?api-version=2017-12-01`

## Manually triggering an extension rolling upgrade

To manually trigger an extension rolling upgrade, you can do a POST on `/subscription/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/{resourceName}/ExtensionRollingUpgrade?api-version=2017-12-01`
