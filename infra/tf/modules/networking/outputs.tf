output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = azurerm_subnet.main.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = var.private_cluster_enabled ? azurerm_public_ip.bastion[0].ip_address : null
}

output "bastion_id" {
  description = "ID of the Bastion host"
  value       = var.private_cluster_enabled ? azurerm_bastion_host.main[0].id : null
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = var.private_cluster_enabled ? azurerm_private_dns_zone.aks[0].id : null
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = var.private_cluster_enabled ? azurerm_private_dns_zone.aks[0].name : null
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.aks.id
}

# Jump VM outputs
output "jump_vm_id" {
  description = "ID of the jump VM"
  value       = var.private_cluster_enabled ? azurerm_linux_virtual_machine.jump_vm[0].id : null
}

output "jump_vm_name" {
  description = "Name of the jump VM"
  value       = var.private_cluster_enabled ? azurerm_linux_virtual_machine.jump_vm[0].name : null
}

output "jump_vm_private_ip" {
  description = "Private IP address of the jump VM"
  value       = var.private_cluster_enabled ? azurerm_network_interface.jump_vm[0].private_ip_address : null
}

output "jump_vm_admin_username" {
  description = "Admin username for the jump VM"
  value       = var.private_cluster_enabled ? var.jump_vm_admin_username : null
}

output "jump_vm_admin_password" {
  description = "Admin password for the jump VM"
  value       = var.private_cluster_enabled ? var.jump_vm_admin_password : null
  sensitive   = true
}

output "jump_vm_ssh_private_key" {
  description = "SSH private key for the jump VM (store securely)"
  value       = var.private_cluster_enabled ? tls_private_key.jump_vm[0].private_key_pem : null
  sensitive   = true
}

output "jump_vm_ssh_public_key" {
  description = "SSH public key for the jump VM"
  value       = var.private_cluster_enabled ? tls_private_key.jump_vm[0].public_key_openssh : null
}
