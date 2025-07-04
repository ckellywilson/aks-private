# User-assigned managed identity for AKS cluster
resource "azurerm_user_assigned_identity" "cluster" {
  name                = "uai-${var.cluster_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# User-assigned managed identity for kubelet
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "uai-${var.cluster_name}-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Role assignment for cluster identity - Network Contributor on the resource group
resource "azurerm_role_assignment" "cluster_network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
}

# Role assignment for kubelet identity - Managed Identity Operator
resource "azurerm_role_assignment" "kubelet_managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
}

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}
