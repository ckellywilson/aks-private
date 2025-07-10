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

# Ingress Controller Settings - Development
enable_internal_load_balancer  = false   # Public load balancer for easy access
ingress_replica_count          = 1       # Single replica for cost optimization
ingress_cpu_requests           = "100m"  # Minimal resources for dev
ingress_memory_requests        = "90Mi"  # Minimal resources for dev
ingress_cpu_limits             = "200m"  # Low limits for cost control
ingress_memory_limits          = "180Mi" # Low limits for cost control
ingress_enable_metrics         = true    # Enable basic metrics
ingress_enable_prometheus_rule = false   # No advanced monitoring rules
ingress_subnet_name            = "aks-subnet"
enable_cert_manager            = true                # Enable Let's Encrypt certificates
letsencrypt_email              = "admin@example.com" # Update with actual email
enable_azure_key_vault_csi     = false               # Not needed for development

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
