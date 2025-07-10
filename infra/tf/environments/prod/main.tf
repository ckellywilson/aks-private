provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment                   = var.environment
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  vnet_address_space            = var.vnet_address_space
  aks_subnet_address_prefix     = var.aks_subnet_address_prefix
  bastion_subnet_address_prefix = var.bastion_subnet_address_prefix
  acr_pe_subnet_address_prefix  = var.acr_pe_subnet_address_prefix
  jumpbox_subnet_address_prefix = var.jumpbox_subnet_address_prefix
  enable_bastion                = var.enable_bastion
  enable_jumpbox                = var.enable_jumpbox
  jumpbox_admin_ssh_public_key  = var.jumpbox_admin_ssh_public_key
  tags                          = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment                  = var.environment
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  log_analytics_workspace_name = var.log_analytics_workspace_name
  monitoring_level             = var.monitoring_level
  tags                         = var.tags
}

# ACR Module
module "acr" {
  source = "../../modules/acr"

  environment                   = var.environment
  acr_name                      = var.acr_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  public_network_access_enabled = var.acr_public_network_access_enabled
  private_endpoint_subnet_id    = module.networking.acr_pe_subnet_id
  vnet_id                       = module.networking.vnet_id
  tags                          = var.tags
}

# AKS Module
module "aks" {
  source = "../../modules/aks"

  environment                     = var.environment
  cluster_name                    = var.cluster_name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  aks_subnet_id                   = module.networking.aks_subnet_id
  vnet_id                         = module.networking.vnet_id
  enable_private_cluster          = var.enable_private_cluster
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  log_analytics_workspace_id      = module.monitoring.log_analytics_workspace_id
  acr_id                          = module.acr.acr_id
  tags                            = var.tags

  depends_on = [
    module.networking,
    module.monitoring,
    module.acr
  ]
}

# Ingress Module - Deploy ingress-nginx controller for production
module "ingress" {
  source = "../../modules/ingress"

  environment                   = var.environment
  enable_internal_load_balancer = var.enable_internal_load_balancer
  ingress_replica_count         = var.ingress_replica_count
  cpu_requests                  = var.ingress_cpu_requests
  memory_requests               = var.ingress_memory_requests
  cpu_limits                    = var.ingress_cpu_limits
  memory_limits                 = var.ingress_memory_limits
  enable_metrics                = var.ingress_enable_metrics
  enable_prometheus_rule        = var.ingress_enable_prometheus_rule
  subnet_name                   = var.ingress_subnet_name
  enable_cert_manager           = var.enable_cert_manager
  letsencrypt_email             = var.letsencrypt_email
  enable_azure_key_vault_csi    = var.enable_azure_key_vault_csi
  tags                          = var.tags

  depends_on = [
    module.aks
  ]
}
