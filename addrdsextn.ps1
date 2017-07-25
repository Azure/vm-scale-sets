
$vmssName = rdsvmss
$rg = hackrdsvmss

$vmssConfig = Get-AzureRmVmss -ResourceGroupName $rg -VMScaleSetName $vmssName  

# Setup extension configuration hashtable variable
$customConfig = @{
  "fileUris" = @("https://raw.githubusercontent.com/Azure/vm-scale-sets/master/hack2017/Scripts/joinrds.ps1");
  "commandToExecute" = "PowerShell -ExecutionPolicy Unrestricted .\joinrds.ps1 $connectionBroker $collection >> `"%TEMP%\StartupLog.txt`" 2>&1";
};

# Add the extension to the config
Add-AzureRmVmssExtension -VirtualMachineScaleSet $vmssConfig -Publisher Microsoft.Compute -Type CustomScriptExtension -TypeHandlerVersion 1.8 -Name "customscript" -Setting $customConfig

# Send the new config to Azure
Update-AzureRmVmss -ResourceGroupName $rg -Name $vmssName  -VirtualMachineScaleSet $vmssConfig