# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false

  # Enable for private clusters
  public_network_access_enabled = !var.private_cluster_enabled
  network_rule_bypass_option    = "AzureServices"

  tags = var.tags
}

# Private endpoint for Container Registry (if private cluster)
resource "azurerm_private_endpoint" "acr" {
  count = var.private_cluster_enabled ? 1 : 0

  name                = "pe-${var.registry_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.registry_name}"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

# Private DNS Zone for Container Registry
resource "azurerm_private_dns_zone" "acr" {
  count = var.private_cluster_enabled ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.private_cluster_enabled ? 1 : 0

  name                  = "vnet-acr-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private DNS A Record for Container Registry
resource "azurerm_private_dns_a_record" "acr" {
  count = var.private_cluster_enabled ? 1 : 0

  name                = var.registry_name
  zone_name           = azurerm_private_dns_zone.acr[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address]
  tags                = var.tags
}
