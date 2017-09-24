# Azure VM scale set Availability Zones preview

### Single zone
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fzones%2Fsinglezone.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Multi-Zone

Note: This template will not work unless your Azure subscription has special feature flags enabled.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fzones%2Fmultizone.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

The VMs are evenly distributed between the zones.

If a zone goes down, there isn’t automatic scale-out. You’d have to do that manually (or link it to autoscale settings like CPU etc.).

There is a VMSS setting:

zoneBalance: 
- True if you want VMs strictly evenly distribution across zones. 
- False if you doesn’t need strictly even distribution. VMs will be allocated to good zones if there is a zone outage when creating/scaling out. Default value: true.

If you had this set to False and scaled out, you’d be able to get back up to original capacity using other zones. 