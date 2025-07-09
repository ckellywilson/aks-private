# Current client configuration
data "azurerm_client_config" "current" {}

# User Assigned Identity for AKS cluster
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Private DNS Zone for AKS (private clusters only)
resource "azurerm_private_dns_zone" "aks" {
  count               = var.enable_private_cluster ? 1 : 0
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link private DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  count                 = var.enable_private_cluster ? 1 : 0
  name                  = "${var.cluster_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Private cluster configuration
  private_cluster_enabled             = var.enable_private_cluster
  private_dns_zone_id                 = var.enable_private_cluster ? azurerm_private_dns_zone.aks[0].id : null
  private_cluster_public_fqdn_enabled = false

  # API server access profile for public clusters
  dynamic "api_server_access_profile" {
    for_each = !var.enable_private_cluster && length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Default node pool (system)
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.enable_auto_scaling ? null : var.system_node_pool.node_count
    min_count                    = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.min_count : null
    max_count                    = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.max_count : null
    zones                        = var.system_node_pool.availability_zones
    vnet_subnet_id               = var.aks_subnet_id
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network configuration
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy != "none" ? var.network_policy : null
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
    load_balancer_sku = "standard"
  }

  # Azure AD integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_integration ? [1] : []
    content {
      tenant_id              = data.azurerm_client_config.current.tenant_id
      admin_group_object_ids = [] # Add admin group IDs as needed
      azure_rbac_enabled     = true
    }
  }

  # Monitoring and logging
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Auto scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                         = "random"
    max_graceful_termination_sec     = "600"
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
    empty_bulk_delete_max            = "10"
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  # Workload identity (recommended for modern workloads)
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.aks
  ]
}

# User node pools
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  zones                 = each.value.availability_zones
  vnet_subnet_id        = var.aks_subnet_id
  node_taints           = each.value.node_taints
  node_labels           = each.value.node_labels

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}

# Role assignments
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.acr_id != "" ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Private DNS Zone Contributor role for private clusters
resource "azurerm_role_assignment" "aks_private_dns_zone_contributor" {
  count                = var.enable_private_cluster ? 1 : 0
  scope                = azurerm_private_dns_zone.aks[0].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
