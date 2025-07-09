output "acr_id" {
  description = "Azure Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Azure Container Registry admin username"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Azure Container Registry admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "Private DNS zone ID for ACR"
  value       = var.private_endpoint_subnet_id != "" ? azurerm_private_dns_zone.acr[0].id : null
}
