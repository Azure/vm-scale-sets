output "lb_endpoint" {
  value = "http://${azurerm_public_ip.example.fqdn}"
}

output "application_endpoint" {
  value = "http://${azurerm_public_ip.example.fqdn}/index.php"
}

output "ssh_endpoint" {
  value = "ssh azureuser@${azurerm_public_ip.example.ip_address} -p ${var.nat_rule_frontend_port_start}"
}

output "vmss_azure_portal_url" {
  value = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_orchestrated_virtual_machine_scale_set.vmss_terraform_tutorial.id}/overview"
}