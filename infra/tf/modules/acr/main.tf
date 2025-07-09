# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Network access control
  public_network_access_enabled = var.public_network_access_enabled

  # Private networking for staging/prod
  dynamic "network_rule_set" {
    for_each = var.public_network_access_enabled ? [] : [1]
    content {
      default_action = "Deny"
    }
  }

  tags = var.tags
}

# Private DNS Zone for ACR (staging/prod only)
resource "azurerm_private_dns_zone" "acr" {
  count               = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link private DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count                 = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                  = "${var.environment}-acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# Private Endpoint for ACR (staging/prod only)
resource "azurerm_private_endpoint" "acr" {
  count               = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "${var.environment}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.environment}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }

  tags = var.tags
}
