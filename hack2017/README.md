# Hackathon 2017 - RDS + Azure VMSS 
## Autoscale your Remote Desktop Session Hosts with Azure-native capabilities 

Last update: 10/20/17

Location for files related to the OneWeek Hackathon 2017 [RDS + Azure VMSS - Autoscale your Remote Desktop Session Hosts with Azure-native capabilities](https://garagehackbox.azurewebsites.net/hackathons/1074/projects/67089) project.

The purpose of this project is to convert an Azure RDS solution, which was based VMs in Availability sets, to use VM scale sets for the host VMs. This makes the solution much easier to scale. Manual scaling can be as simple as moving the scale slider bar in the Azure portal, and auto-scaling solutions can be integrated.


- Currently in progress: PowerShell autoscale script.

### Deploy scale set with one extension - join domain and sessionhost

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fhack2017%2Fazuredeploy-rdshdsc.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Deploy scale set join domain and sessionhost, and set up CPU based autoscale (scale-out only)

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fhack2017%2Fazuredeploy-rds-autoscale.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>






