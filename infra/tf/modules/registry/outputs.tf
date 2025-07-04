output "container_registry_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server of the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username of the container registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password of the container registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.private_cluster_enabled ? azurerm_private_endpoint.acr[0].id : null
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = var.private_cluster_enabled ? azurerm_private_dns_zone.acr[0].id : null
}
