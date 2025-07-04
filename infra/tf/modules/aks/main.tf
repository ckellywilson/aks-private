# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                    = var.cluster_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  node_resource_group     = var.cluster_resource_group_name
  dns_prefix              = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id     = var.private_dns_zone_id
  sku_tier                = "Standard"

  tags = var.tags

  # System node pool
  default_node_pool {
    name            = "system"
    node_count      = var.system_node_count
    vm_size         = var.system_vm_size
    type            = "VirtualMachineScaleSets"
    vnet_subnet_id  = var.subnet_id
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
    max_pods        = 110

    tags = var.tags
  }

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [var.cluster_identity_id]
  }

  kubelet_identity {
    client_id                 = var.kubelet_identity_client_id
    object_id                 = var.kubelet_identity_principal_id
    user_assigned_identity_id = var.kubelet_identity_id
  }

  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
  }

  # Azure Monitor for containers
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Azure Policy add-on
  azure_policy_enabled = var.enable_azure_policy

  # Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # OIDC Issuer
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Maintenance window
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
  }

  depends_on = [
    azurerm_role_assignment.cluster_acr_pull
  ]
}

# User node pool for application workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size

  # Auto-scaling configuration
  auto_scaling_enabled = true
  min_count            = var.user_min_count
  max_count            = var.user_max_count

  vnet_subnet_id  = var.subnet_id
  os_disk_size_gb = 128
  os_disk_type    = "Managed"
  max_pods        = 110
  mode            = "User"

  tags = var.tags
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "cluster_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_principal_id

  skip_service_principal_aad_check = true
}

# Role assignment for cluster identity - Network Contributor on subnet
resource "azurerm_role_assignment" "cluster_subnet_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.cluster_identity_principal_id

  skip_service_principal_aad_check = true
}
