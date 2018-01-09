# Azure VM Scale Sets attach-detach disk preview
Last update 1/9/2017

Welcome to the Azure scale set attach-detach disk preview. This feature makes it possible to attach and detach Managed Disks to and from individual scale set virtual machines. Before this feature, you could only define scale set attached disks centrally in the scale set model, and that definition would apply to all VMs. Now you can do a PUT on an individual VM and attach a disk, or remove that disk and attach it to another VM (as long as there is no LUN collision with the central model). 

This is a significant feature for scale sets. For the first time VMs in a set can be assigned an independant model definition using a PUT. Previously the VMSS VM model was always inherited from the central scale set model. This means VMs in scale sets more closely resemble independent VMs, which makes it easier for applications to make use of the scaling feature of scale sets without compromising the functionality of individual VMs.

Demo video: [Azure scale sets - VM attach/detach disk preview](https://www.youtube.com/watch?v=ROFyVc5cAho).

## Attach-Detach REST API description

To attach or detach a disk to or from an individual VM using the Azure REST API:

1. Create an Azure Managed Disk. You can do this in the portal or using CLI or PowerShell.
2. Get the model view of the VM you want to attach it to. See [Get the model view of a VM](https://docs.microsoft.com/en-us/rest/api/compute/virtualmachinescalesets/get-the-model-view-of-a-vm).
3. Update the model view with a reference to the managed disk (or remove the existing reference if you are detaching). See example JSON body below.
4. PUT the updated model to the VM resource URI as shown below.


### Request

| Method | Request URI |
|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| PUT    | https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Compute/VirtualMachineScaleSets/{vmScaleSet}/virtualMachines/{vmInstanceId}?api-version={apiVersion} |

| Parameter      | Description                                     |
|----------------|-------------------------------------------------|
| subscriptionId | Identifier of your subscription.                |
| resourceGroup  | Resource group that will contain the scale set. |
| vmScaleSet     | Name of the scale set.                          |
| vmInstanceId   | Instance ID of the VM in the scale set.         |
| apiVersion     | 2017-12-01 or later.                            |

### Example JSON body which includes an attached disk

Here is an example VM model that has one OS disk and two data disks attached:

1. Lun 0, create option Empty – internal disk.
2. Lun 1, create option Attach – external disk that was attached using this API.

```
{
    "instanceId": "1",
    "tags": {
        "key": "value"
    },
    "sku": {
        "name": "Standard_A1",
        "tier": "Standard",
        "capacity": 10
    },
    "properties": {
        "latestModelApplied": true,
        "storageProfile": {
            "osDisk": {
                "osType": "Windows",
                "name": "OSDiskName",
                "creationOption": "FromImage",
                "vhd": {
                    "uri": "https://mystorage1.blob.core.windows.net/container/mydisk.vhd"
                },
                "caching": "ReadWrite”,    
            },
            "dataDisks": {
                {
                    "lun": 0,
                    "createOption": "Empty",
                    "caching": "None",
                    "managedDisk": {
                        "storageAccountType": "Standard_LRS"
                    },
                    "diskSizeGB": 100
                },
                {
                    "lun": 1,
                    "createOption": "Attach",
                    "caching": "None",
                    "managedDisk": {
                        "storageAccountType": "Standard_LRS",
                        "id": "/subscriptions/{sub-id}/resourceGroups/{resource-group}/providers/Microsoft.Compute/disks/{disk-name}"
                    },
                    "diskSizeGB": 100
                }
            }
        },
        "osProfile": {
            "computerName": "mycomputer1",
            "adminUsername": "username1",
            "adminPassword": "*********",
            "secrets": [
                {
                    "sourceVault": {
                        "id": "/subscriptions/{sub-id}/resourceGroups/myrg1/providers/Microsoft.KeyVault/vaults/mykeyvault1"
                    },
                    "vaultCertificates": [
                        {
                            "certificateUrl": "https://mykeyvault1.vault.azure.net/secrets/{secret-name}/{secret-version}",
                            "certificateStore": "certificateStoreName"
                        }
                    ]
                }
            ],
            "linuxConfiguration": {
                "ssh": {
                    "publicKeys": [
                        {
                            "path": "path",
                            "keyData": "publickey"
                        }
                    ]
                },
            },
            "windowsConfiguration": {
                "provisionVMAgent": "true",
                "winRM": {
                    "listeners": [
                        {
                            "protocol": "https",
                            "certificateUrl": "https://mykeyvault1.vault.azure.net/secrets/{secret-name}/{secret-version}"
                        }
                    ]
                },
                "additionalUnattendContent": {
                    "pass": "oobesystem",
                    "component": "Microsoft-Windows-Shell-Setup",
                    "settingName": "FirstLogonCommands",
                    "content": "<XML unattend content>"
                },
                "enableAutomaticUpdates": true,
            }    
      "secrets": [
                {
                    "sourceVault": {
                        "id": "/subscriptions/{sub-id}/resourceGroups/myrg1/providers/Microsoft.KeyVault/vaults/myvault1"
                    }    
       "vaultCertificates": [
                        {
                            "certificateUrl": "https://mykeyvault1.vault.azure.net/secrets/{secret-name}/{secret-version}",
                            "certificateStore": "certificateStoreName"
                        }
                    ]
                }
            ]
        },
        "networkProfile": {
            "networkInterfaces": [
                {
                    "id": "/subscriptions/s1/resourceGroups/g1/providers/Microsoft.Compute/virtualMachineScaleSets/ss1/virtualMachines/1/networkInterfaces/nicconfig1",
                }
            ]
        }
    }    
  "resources": {
        "extensions": [
            {
                "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
                "name": "MyCustomScriptExtension",
                "location": "East US",
                "tags": {
                    "key": "value"
                },
                "properties": {
                    "publisher": "Microsoft.Compute",
                    "type": "CustomScript",
                    "typeHandlerVersion": "1.2",
                    "id": "/subscriptions/subid/resourceGroups/resourceGroupName/providers/Microsoft.Compute/VirtualMachineScaleSets/vms01/extensions/MyCustomScriptExtension",
                    "settings": {
                        "commandToExecute": "powershell.exe-Filescript1.ps1",
                        "fileUris": [
                            "uri1"
                        ]
                    },
                    "provisioningState": "creating"
                }
            }
        ]    
    "provisioningState": "Succeeded",
    }    
  "name": "{vmssname}_{instanceId}",
    "type": "Microsoft.Compute/virtualMachineScaleSets/virtualMachines",
    "location": "East US"
}
```
#### Attach
Suppose you want to add another disk at lun 3, with a resource id: _/subscriptions/{sub-id}/resourceGroups/{resource-group}/providers/Microsoft.Compute/disks/diskexample1_

The dataDisks section of the VM model would be updated to look like this, and used as the body for a PUT call to the VM URI:
```
"dataDisks": {
    {
        "lun": 0,
        "createOption": "Empty",
        "caching": "None",
        "managedDisk": {
            "storageAccountType": "Standard_LRS"
        },
        "diskSizeGB": 100
    },
    {
        "lun": 1,
        "createOption": "Attach",
        "caching": "None",
        "managedDisk": {
            "storageAccountType": "Standard_LRS",
            "id": "/subscriptions/{sub-id}/resourceGroups/{resource-group}/providers/Microsoft.Compute/disks/{disk-name}"
        },
        "diskSizeGB": 100
    },
    {
        "lun": 3,
        "createOption": "Attach",
        "caching": "None",
        "managedDisk": {
            "storageAccountType": "Standard_LRS",
            "id": "/subscriptions/{sub-id}/resourceGroups/{resource-group}/providers/Microsoft.Compute/disks/diskexample1"
        }
    }
}
```
#### Detach
Suppose you want to detach the disks that were attached at lun 1 and above. In this case the dataDisks section of the model would be updated like this, followed by a PUT:
```
"dataDisks": {
    {
        "lun": 0,
        "createOption": "Empty",
        "caching": "None",
        "managedDisk": {
            "storageAccountType": "Standard_LRS"
        },
        "diskSizeGB": 100
    }
}
```
### Programming example using Python and the REST API
This example, using the [azurerm](https://pypi.python.org/pypi/azurerm) Python REST wrapper library is used in the video demo above: [vmssvmdisk.py](https://github.com/gbowerman/azurerm/blob/master/examples/vmssvmdisk.py). Note you need to create a Service Principal in order to run this.

This example uses the same library, and can run in the Azure Cloud Shell without requiring a Service Principal - it gets an authentication token from the CLI cache: [vmssvmdisk_cliauth.py](https://github.com/gbowerman/azurerm/blob/master/examples/vmssvmdisk_cliauth.py). Remember these examples only work for scale sets and managed disks in the supported regions.

### Running the example in the Cloud Shell
```
# Install the required Python library and download the example program:
pip install –user azurerm
curl https://raw.githubusercontent.com/gbowerman/azurerm/master/examples/vmssdisk_cliauth.py > vmssdisk.py

# Attach a managed disk called diskfloat in resource group myrg to VM id 1, lun 2, 
# in a scale set called myvmss
python vmssdisk.py -n myvmss -g myrg -o attach -i 1 -l 2 --diskname diskfloat
# detach the disk from lun 2 of VM ID 1 (note you can only detach disks from individual VMs 
# that you attached to individual VMs)
python vmssdisk.py -n myvmss -g myrg -o detach -i 1 -l 2
```
