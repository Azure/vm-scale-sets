Param(
    [string]$resourceGroup,
    [string]$vmssName,
    [int]$startCount = 1
)

# variable to track the number of started instances
$count = 0
$id_string = ''

# get a list of VMSS VMs - note the -InstanceView argument is not working in list mode
$vmss_vms = Get-AzureRmVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName

ForEach ($vm in $vmss_vms) {
    Write-Host 'Processing instance:' $vm.InstanceID
    $vm_instance_view = Get-AzureRmVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName -InstanceId $vm.InstanceID -InstanceView
    # Write-Host $vm_instance_view.Statuses[1].Code
    if ($vm_instance_view.Statuses[1].Code -eq 'PowerState/deallocated') {
        if ($count -gt 0) {
            $id_string += ','
        }
        $id_string += $vm.InstanceID -as [string]
        $count++
    }
    if ($count -eq $startCount) {
        break
    }
}
if ($count -gt 0) {
    Write-Host 'Starting' $count 'instance(s):' $id_string
    Invoke-Expression -Command "start-azurermvmss -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName -InstanceId $id_string"
}
else {
    Write-Host 'No deallocated instances found in scale set:' $vmssName
}