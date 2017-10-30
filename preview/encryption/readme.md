# Azure VM scale set encryption preview

Welcome to the VM scale set Azure Disk Encryption preview.

Status (10/29/2017): VMSS disk encryption is a preview feature which requires self-registration in order to use (see below).

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

### Windows VMSS:
- Create a Windows VM ScaleSet and enable encryption: [201-encrypt-vmss-windows-jumpbox](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-vmss-windows-jumpbox)
- Enable encryption on a running windows VM ScaleSet : [201-encrypt-running-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-vmss-windows)
- Disable encryption on a running windows VM ScaleSet: [201-decrypt-vmss-windows](https://github.com/Azure/azure-quickstart-templates/tree/master/201-decrypt-vmss-windows)

## PowerShell cmdlets for scale set encryption
|CommandType     |Name                                               |Version    |Source         |
|----------------|---------------------------------------------------|-----------|---------------|
|Alias           |Get-AzureRmVmssDiskEncryptionStatus                |3.4.0      |AzureRM.Compute|
|Alias           |Get-AzureRmVmssVMDiskEncryptionStatus              |3.4.0      |AzureRM.Compute|
|Cmdlet          |Disable-AzureRmVmssDiskEncryption                  |3.4.0      |AzureRM.Compute|
|Cmdlet          |Get-AzureRmVmssDiskEncryption                      |3.4.0      |AzureRM.Compute|
|Cmdlet          |Get-AzureRmVmssVMDiskEncryption                    |3.4.0      |AzureRM.Compute|
|Cmdlet          |Set-AzureRmVmssDiskEncryptionExtension             |3.4.0      |AzureRM.Compute|