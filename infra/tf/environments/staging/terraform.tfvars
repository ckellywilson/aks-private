# Staging Environment Configuration
environment                  = "staging"
location                     = "East US"
resource_group_name          = "rg-aks-multi-env-staging-eastus"
cluster_name                 = "aks-multi-env-staging"
acr_name                     = "acrmultienvstaging"
log_analytics_workspace_name = "law-aks-multi-env-staging"

# Staging-specific Configuration
enable_private_cluster            = true
api_server_authorized_ip_ranges   = []
acr_public_network_access_enabled = false
monitoring_level                  = "enhanced"

# Tags
tags = {
  Environment = "staging"
  Project     = "aks-multi-env"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
