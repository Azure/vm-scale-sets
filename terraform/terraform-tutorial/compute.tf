resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss_terraform_tutorial" {
  name                        = "vmss-tf"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku_name                    = "Standard_D2s_v4"
  instances                   = var.num_instances
  platform_fault_domain_count = 1         # Must be 1 to allow us to specify zones
  zones                       =  ["1"] # Zones required to lookup zone in the startup script
  single_placement_group      = false
  # tags                        = var.tags
  
  user_data_base64 = base64encode(file("user-data.sh"))
  os_profile {

    linux_configuration {
      admin_username = "azureuser"
      admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
      }
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS-gen2"
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "nic"
    primary                       = true
    enable_accelerated_networking = false

    ip_configuration {
      name      = "ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
      public_ip_address {
        name = "vmsspip"
        sku_name = "Standard_Regional"
        version = "IPv4"
      }
    }
  }


#   automatic_instance_repair {
#     enabled      = true
#     grace_period = "PT30M"
#   }

#   identity {
#     type         = "UserAssigned"
#     identity_ids = [var.instance_identity]
#   }

#   extension {
#     name                 = "${var.worker_group_name}-health"
#     publisher            = "Microsoft.ManagedServices"
#     type                 = "ApplicationHealthLinux"
#     type_handler_version = "1.0"
#     settings = jsonencode({
#       "protocol"    = "http"
#       "port"        = 8080
#       "requestPath" = "/health"
#     })
#   }

  boot_diagnostics {
    storage_account_uri = ""
  }

  # Prevent terraform
  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}


variable "num_instances" {
  description = "Number of instances for the worker"
  type        = number
  default     = 3
}