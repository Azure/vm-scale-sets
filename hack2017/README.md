# Hackathon 2017 - RDS + Azure VMSS 
## Autoscale your Remote Desktop Session Hosts with Azure-native capabilities 

Last update: 7/24/17

Location for files related to the OneWeek Hackathon 2017 [RDS + Azure VMSS - Autoscale your Remote Desktop Session Hosts with Azure-native capabilities](https://garagehackbox.azurewebsites.net/hackathons/1074/projects/67089) project.

Initially the files in the project are for VMs in Availability sets.

- Converted azuredeploy.json to use scale sets.

- Currently in progress: testing

### Deploy template with one extension - join domain

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fhack2017%2Fazuredeploy-joindomain.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Deploy template with one extension - join domain and sessionhost

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fhack2017%2Fazuredeploy-rdshdsc.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>






