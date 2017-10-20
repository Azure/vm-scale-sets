$resource_group = 'zroll'
$vmss_name = 'zroll'
$location = 'eastus2'

# get a list of VMSS VMs - note the -InstanceView argument is not working in list mode
$vmss_vms = Get-AzureRmVmssVM -ResourceGroupName $resource_group -VMScaleSetName $vmss_name

ForEach ($vm in $vmss_vms) 
{
    Write-Host 'Processing instance: ' $vm.InstanceID
    $vm_instance_view = Get-AzureRmVmssVM -ResourceGroupName $resource_group -VMScaleSetName $vmss_name -InstanceId $vm.InstanceID -InstanceView
    Write-Host $vm_instance_view.Statuses[1].Code
}