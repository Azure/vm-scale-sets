// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

package main

import (
	"context"
	"log"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore"
	"github.com/Azure/azure-sdk-for-go/sdk/azcore/to"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/compute/armcompute"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/network/armnetwork"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/resources/armresources"
)

var (
	subscriptionID     string
	location           = "westus3"
	resourceGroupName  = "vmss-flex-sample"
	virtualNetworkName = "vnet"
	subnetName         = "default"
	vmScaleSetName     = "myvmss"
	vmScaleSetCapacity = int64(5)
	forceDeleteEnabled = true
)

func main() {
	subscriptionID = os.Getenv("AZURE_SUBSCRIPTION_ID")
	if len(subscriptionID) == 0 {
		log.Fatal("AZURE_SUBSCRIPTION_ID is not set.")
	}

	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		log.Fatal(err)
	}
	ctx := context.Background()

	resourceGroup, err := createResourceGroup(ctx, cred)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("resources group:", *resourceGroup.ID)

	virtualNetwork, err := createVirtualNetwork(ctx, cred)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("virtual network:", *virtualNetwork.ID)

	subnet, err := createSubnet(ctx, cred)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("subnet:", *subnet.ID)

	vmss, err := createVMSS(ctx, cred, *subnet.ID)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("virtual machine scale sets:", *vmss.ID)

	// vmss, err = getVMSS(ctx, cred)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// log.Println("virtual machine scale sets:", *vmss.ID)

	instances, err := vmssInstances(ctx, cred, *vmss)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Original instance count", len(instances))
	log.Println("Original virtual machine scale sets instances:", instances)

	//delete half of the instances
	delcount := int(*vmss.SKU.Capacity) / 2
	log.Println("Deleting half of the instances. Count:", delcount)

	deleteVmssInstances(ctx, cred, *vmss, instances[:delcount])

	vmss, err = getVMSS(ctx, cred)
	if err != nil {
		log.Fatal(err)
	}

	instances, err = vmssInstances(ctx, cred, *vmss)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("After delete instance count", len(instances))
	log.Println("Remaining virtual machine scale sets instances:", instances)

	keepResource := os.Getenv("KEEP_RESOURCE")
	if len(keepResource) == 0 {
		log.Println("CLEANUP. Deleting resource group: ", resourceGroupName)
		err := cleanup(ctx, cred)
		if err != nil {
			log.Fatal(err)
		}
		log.Println("cleaned up successfully.")
	}
}

func createVirtualNetwork(ctx context.Context, cred azcore.TokenCredential) (*armnetwork.VirtualNetwork, error) {
	virtualNetworkClient, err := armnetwork.NewVirtualNetworksClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}

	pollerResp, err := virtualNetworkClient.BeginCreateOrUpdate(
		ctx,
		resourceGroupName,
		virtualNetworkName,
		armnetwork.VirtualNetwork{
			Location: to.Ptr(location),
			Properties: &armnetwork.VirtualNetworkPropertiesFormat{
				AddressSpace: &armnetwork.AddressSpace{
					AddressPrefixes: []*string{
						to.Ptr("10.1.0.0/16"),
					},
				},
			},
		},
		nil)

	if err != nil {
		return nil, err
	}

	resp, err := pollerResp.PollUntilDone(ctx, nil)
	if err != nil {
		return nil, err
	}
	return &resp.VirtualNetwork, nil
}

func createSubnet(ctx context.Context, cred azcore.TokenCredential) (*armnetwork.Subnet, error) {
	subnetsClient, err := armnetwork.NewSubnetsClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}

	pollerResp, err := subnetsClient.BeginCreateOrUpdate(
		ctx,
		resourceGroupName,
		virtualNetworkName,
		subnetName,
		armnetwork.Subnet{
			Properties: &armnetwork.SubnetPropertiesFormat{
				AddressPrefix: to.Ptr("10.1.0.0/24"),
			},
		},
		nil)

	if err != nil {
		return nil, err
	}

	resp, err := pollerResp.PollUntilDone(ctx, nil)
	if err != nil {
		return nil, err
	}
	return &resp.Subnet, nil
}

func getVMSS(ctx context.Context, cred azcore.TokenCredential) (*armcompute.VirtualMachineScaleSet, error) {
	// Get an Azure client
	client, err := armcompute.NewVirtualMachineScaleSetsClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}

	resp, err := client.Get(ctx, resourceGroupName, vmScaleSetName, nil)

	// Get the virtual machine scale set
	return &resp.VirtualMachineScaleSet, err
}

func vmssInstances(ctx context.Context, cred azcore.TokenCredential, vmss armcompute.VirtualMachineScaleSet) ([]string, error) {
	// Create a new Azure Virtual Machine Scale Set client
	vmssVmClient, err := armcompute.NewVirtualMachineScaleSetVMsClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}
	// Get the list of instances in the vmss
	listPager := vmssVmClient.NewListPager(resourceGroupName, *vmss.Name, nil)

	// Create a slice to hold the names of the first two instances
	var names []string
	capacity := int(*vmss.SKU.Capacity)

	// Loop through the first two instances and add their names to the slice
	for i := 0; i < capacity; {

		instances, err := listPager.NextPage(ctx)
		if err != nil {
			return nil, err
		}

		for _, instance := range instances.Value {

			names = append(names, *instance.Name)
			//fmt.Println("instance name:", *instance.Name)
			i++
		}
	}

	return names, nil
}

func deleteVmssInstances(ctx context.Context, cred azcore.TokenCredential, vmss armcompute.VirtualMachineScaleSet, names []string) error {
	// Create a new Azure Virtual Machine Scale Set client
	vmssClient, err := armcompute.NewVirtualMachineScaleSetsClient(subscriptionID, cred, nil)
	if err != nil {
		return err
	}

	log.Println("Deleting instances: ", names)
	// Create a slice of instance IDs
	var instanceIDs []string
	// for _, name := range names {
	// 	instanceIDs = append(instanceIDs, name)
	// }
	instanceIDs = append(instanceIDs, names...)

	// Convert the instance IDs slice to a slice of pointers to strings
	var instanceIDPointers []*string
	for _, id := range instanceIDs {
		idCopy := id
		instanceIDPointers = append(instanceIDPointers, &idCopy)
	}

	// Convert the instance IDs to a VirtualMachineScaleSetVMInstanceRequiredIDs struct
	requiredIDs := armcompute.VirtualMachineScaleSetVMInstanceRequiredIDs{
		InstanceIDs: instanceIDPointers,
	}

	enableForceDelete := armcompute.VirtualMachineScaleSetsClientBeginDeleteInstancesOptions{
		ForceDeletion: &forceDeleteEnabled,
	}

	// Delete the instances with the specified IDs
	future, err := vmssClient.BeginDeleteInstances(ctx, resourceGroupName, *vmss.Name, requiredIDs, &enableForceDelete)
	if err != nil {
		log.Fatal(err)
		return err
	}

	// Wait for the operation to complete
	_, err = future.PollUntilDone(ctx, nil)
	if err != nil {
		return err
	}

	return nil
}

func createVMSS(ctx context.Context, cred azcore.TokenCredential, subnetID string) (*armcompute.VirtualMachineScaleSet, error) {
	vmssClient, err := armcompute.NewVirtualMachineScaleSetsClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}

	pollerResp, err := vmssClient.BeginCreateOrUpdate(
		ctx,
		resourceGroupName,
		vmScaleSetName,
		armcompute.VirtualMachineScaleSet{
			Location: to.Ptr(location),
			SKU: &armcompute.SKU{
				Name:     to.Ptr("Standard_D2s_v5"), //armcompute.VirtualMachineSizeTypesBasicA0
				Capacity: to.Ptr(vmScaleSetCapacity),
			},
			Properties: &armcompute.VirtualMachineScaleSetProperties{
				//Overprovision: to.Ptr(false),
				OrchestrationMode:        &armcompute.PossibleOrchestrationModeValues()[0],
				PlatformFaultDomainCount: to.Ptr[int32](1),
				// UpgradePolicy: &armcompute.UpgradePolicy{
				// 	Mode: to.Ptr(armcompute.UpgradeModeManual),
				// 	AutomaticOSUpgradePolicy: &armcompute.AutomaticOSUpgradePolicy{
				// 		EnableAutomaticOSUpgrade: to.Ptr(false),
				// 		DisableAutomaticRollback: to.Ptr(false),
				// 	},
				// },
				VirtualMachineProfile: &armcompute.VirtualMachineScaleSetVMProfile{
					OSProfile: &armcompute.VirtualMachineScaleSetOSProfile{
						ComputerNamePrefix: to.Ptr("vmss"),
						AdminUsername:      to.Ptr("sample-user"),
						AdminPassword:      to.Ptr("Password01!@#"),
					},
					StorageProfile: &armcompute.VirtualMachineScaleSetStorageProfile{
						ImageReference: &armcompute.ImageReference{
							Offer:     to.Ptr("WindowsServer"),
							Publisher: to.Ptr("MicrosoftWindowsServer"),
							SKU:       to.Ptr("2019-Datacenter"),
							Version:   to.Ptr("latest"),
						},
					},
					NetworkProfile: &armcompute.VirtualMachineScaleSetNetworkProfile{
						NetworkAPIVersion: to.Ptr(armcompute.NetworkAPIVersionTwoThousandTwenty1101),
						NetworkInterfaceConfigurations: []*armcompute.VirtualMachineScaleSetNetworkConfiguration{
							{
								Name: to.Ptr(vmScaleSetName),
								Properties: &armcompute.VirtualMachineScaleSetNetworkConfigurationProperties{
									Primary:            to.Ptr(true),
									EnableIPForwarding: to.Ptr(true),
									IPConfigurations: []*armcompute.VirtualMachineScaleSetIPConfiguration{
										{
											Name: to.Ptr(vmScaleSetName),
											Properties: &armcompute.VirtualMachineScaleSetIPConfigurationProperties{
												Subnet: &armcompute.APIEntityReference{
													ID: to.Ptr(subnetID),
												},
												PublicIPAddressConfiguration: &armcompute.VirtualMachineScaleSetPublicIPAddressConfiguration{
													SKU: &armcompute.PublicIPAddressSKU{
														Name: &armcompute.PossiblePublicIPAddressSKUNameValues()[1],
													},
													Name: to.Ptr("vmsspip"),
													Properties: &armcompute.VirtualMachineScaleSetPublicIPAddressConfigurationProperties{
														IdleTimeoutInMinutes: to.Ptr[int32](20),
													},
												},
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
		nil,
	)
	if err != nil {
		return nil, err
	}

	resp, err := pollerResp.PollUntilDone(ctx, nil)
	if err != nil {
		return nil, err
	}
	return &resp.VirtualMachineScaleSet, nil
}

func createResourceGroup(ctx context.Context, cred azcore.TokenCredential) (*armresources.ResourceGroup, error) {
	resourceGroupClient, err := armresources.NewResourceGroupsClient(subscriptionID, cred, nil)
	if err != nil {
		return nil, err
	}

	resourceGroupResp, err := resourceGroupClient.CreateOrUpdate(
		ctx,
		resourceGroupName,
		armresources.ResourceGroup{
			Location: to.Ptr(location),
		},
		nil)
	if err != nil {
		return nil, err
	}
	return &resourceGroupResp.ResourceGroup, nil
}

func cleanup(ctx context.Context, cred azcore.TokenCredential) error {
	resourceGroupClient, err := armresources.NewResourceGroupsClient(subscriptionID, cred, nil)
	if err != nil {
		return err
	}

	pollerResp, err := resourceGroupClient.BeginDelete(ctx, resourceGroupName, nil)
	if err != nil {
		return err
	}

	_, err = pollerResp.PollUntilDone(ctx, nil)
	if err != nil {
		return err
	}
	return nil
}
