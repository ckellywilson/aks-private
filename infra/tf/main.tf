locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = "aks-private"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "IT-Infrastructure"
    Purpose     = "Private AKS Cluster"
    Instance    = "001"
  })

  # Resource naming convention
  resource_prefix = "${var.environment}-${var.location_short}"

  # Network configuration
  network_config = {
    subnet_cidr    = var.subnet_cidr
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }
}

# Data sources for existing resources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Identity module
module "identity" {
  source = "./modules/identity"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = var.cluster_name
  tags                = local.common_tags
}

# Networking module
module "networking" {
  source = "./modules/networking"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  vnet_name               = var.vnet_name
  subnet_name             = var.subnet_name
  bastion_subnet_name     = var.bastion_subnet_name
  bastion_name            = var.bastion_name
  subnet_cidr             = var.subnet_cidr
  private_cluster_enabled = var.private_cluster_enabled
  jump_vm_name            = var.jump_vm_name
  jump_vm_size            = var.jump_vm_size
  jump_vm_admin_username  = var.jump_vm_admin_username
  jump_vm_admin_password  = var.jump_vm_admin_password
  tags                    = local.common_tags
}

# Container Registry module
module "registry" {
  source = "./modules/registry"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  registry_name           = var.registry_name
  private_cluster_enabled = var.private_cluster_enabled
  subnet_id               = module.networking.subnet_id
  vnet_id                 = module.networking.vnet_id
  tags                    = local.common_tags
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  log_analytics_workspace_name = var.log_analytics_workspace_name
  tags                         = local.common_tags
}

# AKS module
module "aks" {
  source = "./modules/aks"

  resource_group_name         = azurerm_resource_group.main.name
  cluster_resource_group_name = var.cluster_resource_group_name
  location                    = azurerm_resource_group.main.location
  cluster_name                = var.cluster_name
  kubernetes_version          = var.kubernetes_version

  # Identity
  cluster_identity_id           = module.identity.cluster_identity_id
  cluster_identity_principal_id = module.identity.cluster_identity_principal_id
  kubelet_identity_id           = module.identity.kubelet_identity_id
  kubelet_identity_principal_id = module.identity.kubelet_identity_principal_id
  kubelet_identity_client_id    = module.identity.kubelet_identity_client_id

  # Networking
  subnet_id               = module.networking.subnet_id
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id     = module.networking.private_dns_zone_id

  # Network configuration
  service_cidr   = var.service_cidr
  dns_service_ip = var.dns_service_ip
  network_policy = var.network_policy

  # Node pools
  system_node_count = var.system_node_count
  system_vm_size    = var.system_vm_size
  user_node_count   = var.user_node_count
  user_min_count    = var.user_min_count
  user_max_count    = var.user_max_count
  user_vm_size      = var.user_vm_size

  # Security
  enable_azure_policy        = var.enable_azure_policy
  enable_pod_security_policy = var.enable_pod_security_policy

  # Monitoring
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # Container Registry
  container_registry_id = module.registry.container_registry_id

  tags = local.common_tags
}

# Note: Helm deployments (nginx-ingress and cert-manager) are deployed separately
# Use the deployment scripts in the scripts/ directory to install these add-ons
# after gaining access to the cluster via Azure Bastion
