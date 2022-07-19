# Azure VM scale set encryption preview

Welcome to the VM scale set Azure Disk Encryption preview.

> **Warning**
> This content is deprecated. Please refer to the [official VMSS documentation](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview).

## Caveats
- No Linux OS disk encryption in the current preview.
- VMSS VM reimage and image upgrade operations not supported in current preview. Do not use in production environments where you might need to upgrade or change your OS image in an encrypted scale set.
- VMSS encryption is supported only for scale sets created with __managed disks__, and not supported for native (or unmanaged) disk scale sets.

## Opt-in to ADE-VMSS preview: 
```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName "UnifiedDiskEncryption"
# Wait 10 minutes until the state as 'Registered' when you run the following command:
Get-AzureRmProviderFeature -ProviderNamespace "Microsoft.Compute" -FeatureName "UnifiedDiskEncryption"
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
```

## Supported regions
VMSS encryption preview is now available in all public Azure regions.

### Using Templates
1. Create a KeyVault in the same subscription and region as the VMSS
2. Set 'EnabledForDiskEncryption' access policy using PS cmdlet:
```
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDiskEncryption
```

### Example templates
1.	Windows:
- Create a Windows VM ScaleSet and enable encryption: [201-encrypt-running-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-vmss-windows)
- Enable encryption on a running windows VM ScaleSet: [201-encrypt-vmss-windows-jumpbox](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-vmss-windows-jumpbox)
- Disable encryption on a running windows VM ScaleSet: [201-decrypt-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-decrypt-vmss-windows)
2.	Linux:
- Create a Linux VM ScaleSet and enable encryption: [201-encrypt-running-vmss-linux](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-vmss-linux)
- Enable encryption on a running Linux VM ScaleSet: [201-encrypt-vmss-linux-jumpbox](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-vmss-linux-jumpbox)
- Disable encryption on a running Linux VM ScaleSet: [201-decrypt-vmss-linux](https://github.com/Azure/azure-quickstart-templates/tree/master/201-decrypt-vmss-linux)


## PowerShell cmdlets for VMSS Encryption
|CommandType     |Name                                               |Version    |Source         |
|----------------|---------------------------------------------------|-----------|---------------|
|Alias           |Get-AzureRmVmssDiskEncryptionStatus                |3.4.0      |AzureRM.Compute|
|Alias           |Get-AzureRmVmssVMDiskEncryptionStatus              |3.4.0      |AzureRM.Compute|
|Cmdlet          |Disable-AzureRmVmssDiskEncryption                  |3.4.0      |AzureRM.Compute|
|Cmdlet          |Get-AzureRmVmssDiskEncryption                      |3.4.0      |AzureRM.Compute|
|Cmdlet          |Get-AzureRmVmssVMDiskEncryption                    |3.4.0      |AzureRM.Compute|
|Cmdlet          |Set-AzureRmVmssDiskEncryptionExtension             |3.4.0      |AzureRM.Compute|

## CLI examples
- Install [latest Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) which has the new encryption commands. 

```
# create VMSS
az vmss create -g <resourceGroupName> -n <VMSS name> --instance-count 1 --image Win2016Datacenter --admin-username <username> --admin-password <password>"
# Enable encryption
az vmss encryption enable -g yugangw2 -n yugangw2-wins --disk-encryption-keyvault <KeyVaultResourceId>
# Update VMSS instances
az vmss update-instances -g <resourceGroupName> -n <VMSS name> --instance-ids * 
# Show encryption status
az vmss encryption show -g <resourceGroupName> -n <VMSS name>
# Disable encryption (For Windows VMSS only)
az vmss encryption disable -g <resourceGroupName> -n <VMSS name>
```
- [End to end batch file example for Linux scale set data disk encryption](https://gist.githubusercontent.com/ejarvi/7766dad1475d5f7078544ffbb449f29b/raw/03e5d990b798f62cf188706221ba6c0c7c2efb3f/enable-linux-vmss.bat) (creates resource group, VMSS, mounts a 5GB data disk, encrypts) 

