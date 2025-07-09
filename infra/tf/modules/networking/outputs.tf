output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "AKS subnet name"
  value       = azurerm_subnet.aks.name
}

output "bastion_subnet_id" {
  description = "Bastion subnet ID"
  value       = var.enable_bastion ? azurerm_subnet.bastion[0].id : null
}

output "acr_pe_subnet_id" {
  description = "ACR private endpoint subnet ID"
  value       = var.acr_pe_subnet_address_prefix != "" ? azurerm_subnet.acr_pe[0].id : null
}

output "jumpbox_subnet_id" {
  description = "Jump box subnet ID"
  value       = var.enable_jumpbox ? azurerm_subnet.jumpbox[0].id : null
}

output "jumpbox_private_ip" {
  description = "Jump box private IP address"
  value       = var.enable_jumpbox ? azurerm_network_interface.jumpbox[0].private_ip_address : null
}

output "bastion_fqdn" {
  description = "Bastion host FQDN"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}
