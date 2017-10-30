# Azure VM scale set encryption preview

Welcome to the VM scale set Azure Disk Encryption preview.

Status (10/30/2017): VMSS disk encryption is a preview feature which requires self-registration in order to use (see below).

## Caveats
- No Linux OS disk encryption in the current preview.
- VMSS VM reimage and upgrade operations not supported in current preview.

## Opt-in to ADE-VMSS preview: 
```
Register-AzureRmProviderFeature -FeatureName UnifiedDiskEncryption -ProviderNamespace Microsoft.Compute  
```

## Supported regions
VMSS encryption preview is now available in all public Azure regions.

### Using Templates
1. Create a KeyVault in the same subscription and region as the VMSS
2. Set 'EnabledForDiskEncryption' access policy using PS cmdlet:
```
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDiskEncryption
```

### Windows VMSS (withOUT AAD dependency):
- Create a Windows VM ScaleSet and enable encryption: [201-encrypt-vmss-windows-jumpbox](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-vmss-windows-jumpbox)
- Enable encryption on a running windows VM ScaleSet : [201-encrypt-running-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-vmss-windows)
- Disable encryption on a running windows VM ScaleSet: [201-decrypt-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-decrypt-vmss-windows)

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
- [End to end batch file example for Linux VMSS Data disk encryption](https://gist.githubusercontent.com/ejarvi/7766dad1475d5f7078544ffbb449f29b/raw/03e5d990b798f62cf188706221ba6c0c7c2efb3f/enable-linux-vmss.bat) (creates resource group, VMSS, mounts a 5GB data disk, encrypts) 

