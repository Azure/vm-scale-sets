# Azure VM scale set Availability Zones preview

Last update: 10/5/2017.

Preview site for onboarding scale sets to the Azure Availability Zones preview. For more information about Availability Zones, go here: [Overview of Availability Zones in Azure (Preview)](https://docs.microsoft.com/en-us/azure/availability-zones/az-overview).


![Zone redundant VM scale set diagram](./img/zone_redundant_vmss.png)

Note: Availabliity Zones are initially available only in these regions: **West Europe** & **East US 2** 

### Single zone
A _zonal_ scale set is a scale set that is pinned to a single Availability Zone. Zonal scale sets are currently available in public preview.

What does pinning a scale set to a single zone give you that a regular (regional) scale set does not?

Pinning a scale set to a zone enables you to create multiple scale sets, each pinned to different zones, and therefore guarantee they are on physically isolated hardware.

### Example zonal scale set
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fzones%2Fsinglezone.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Zone redundant
A _zone-redundant_ scale set is a scale set that is spread across more than one availablity zone.

You can sign up to the zone redundant scale set preview here: [https://aka.ms/xzonevmss](https://aka.ms/xzonevmss)

Note: This template will not work unless your Azure subscription has special feature flags enabled.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fzones%2Fmultizone.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


### Zone redundant load balancer (Load Balancer 'Standard')
Zonal and zone redudnant scale sets works with the new Load Balancer 'Standard SKU'. See [Azure Load Balancer Standard overview (Preview)](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-standard-overview) for more info.

Load Balancer 'Standard' is currently available in the following regions (AZ supporting regions in bold): 
**East US 2**, Central US, North Europe, West Central US, **West Europe**, Southeast Asia.

Here is an example which also relies on the _VM Scale Sets manually triggered rolling image upgrade_ preview. It uses a Load Balancer 'Standard' sku to provide an applicaiton health probe.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fzonesmanualrolling.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

The new load balancer can also load balance between scale sets of up to 1000 VMs, and multiple scale sets.

### Notes
The VMs are evenly distributed between the zones.

If a zone goes down, there isn’t automatic scale-out. You’d have to do that manually (or link it to autoscale settings like CPU etc.).

There is a VMSS setting:

_zoneBalance_: 
- True if you want VMs strictly evenly distribution across zones. 
- False if you doesn’t need strictly even distribution. VMs will be allocated to good zones if there is a zone outage when creating/scaling out. Default value: true.

If you had this set to False and scaled out, you’d be able to get back up to original capacity using other zones. 

