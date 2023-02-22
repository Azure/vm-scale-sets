output "lb_endpoint" {
  value = "https://${azurerm_public_ip.example.fqdn}"
}

output "application_endpoint" {
  value = "https://${azurerm_public_ip.example.fqdn}/index.php"
}

output "vmss_name" {
  value = azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tutorial.name
}