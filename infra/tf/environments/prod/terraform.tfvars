# Production Environment Configuration
environment                  = "prod"
location                     = "Central US"
resource_group_name          = "rg-aks-multi-env-prod-centralus"
cluster_name                 = "aks-multi-env-prod"
acr_name                     = "acrmultienvprod"
log_analytics_workspace_name = "law-aks-multi-env-prod"

# Networking Configuration
vnet_address_space            = ["10.2.0.0/16"]
aks_subnet_address_prefix     = "10.2.1.0/24"
bastion_subnet_address_prefix = "10.2.2.0/24"
acr_pe_subnet_address_prefix  = "10.2.3.0/24"
jumpbox_subnet_address_prefix = "10.2.4.0/24"

# Production-specific Configuration
enable_private_cluster            = true
api_server_authorized_ip_ranges   = []
acr_public_network_access_enabled = false
monitoring_level                  = "full"
enable_bastion                    = true
enable_jumpbox                    = true

# Tags
tags = {
  Environment = "production"
  Project     = "aks-multi-env"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
  CostCenter  = "production"
  Criticality = "high"
}
