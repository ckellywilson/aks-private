# Development Environment Configuration
environment = "dev"
location    = "Central US"

# Resource naming
resource_group_name          = "rg-aks-dev-centralus-001"
cluster_name                 = "aks-dev-centralus-001"
acr_name                     = "acraksdevcentralus001"
log_analytics_workspace_name = "law-aks-dev-centralus-001"

# Development-specific settings (public access for easy development)
enable_private_cluster            = false
api_server_authorized_ip_ranges   = ["0.0.0.0/0"]
acr_public_network_access_enabled = true
monitoring_level                  = "basic"

# Development tags
tags = {
  Environment = "dev"
  Project     = "aks-private"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
  Purpose     = "Development AKS Cluster"
  CostCenter  = "Development"
  CreatedDate = "2025-01-09"
  GitRepo     = "aks-private"
}
