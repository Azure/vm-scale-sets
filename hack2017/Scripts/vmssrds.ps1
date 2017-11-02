Param(
    [string]$resourceGroup,
    [string]$vmssName,
    [int]$startCount = 1
  )

# variable to track the number of started instances
$started = 0

# get a list of VMSS VMs - note the -InstanceView argument is not working in list mode
$vmss_vms = Get-AzureRmVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName

ForEach ($vm in $vmss_vms) 
{
    Write-Host 'Processing instance: ' $vm.InstanceID
    $vm_instance_view = Get-AzureRmVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName -InstanceId $vm.InstanceID -InstanceView
    # Write-Host $vm_instance_view.Statuses[1].Code
    if ($vm_instance_view.Statuses[1].Code -eq 'PowerState/deallocated')
    {
        Write-Host 'Starting VM ID:' $vm.InstanceID
        start-azurermvmss -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName -InstanceId $vm.InstanceID
        $started++
    }
    if ($started  -eq $startCount) 
    {
        Write-Host 'Started ' $started ' instances'
        break
    }
}