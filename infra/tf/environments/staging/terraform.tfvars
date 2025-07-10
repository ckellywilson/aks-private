# Staging Environment Configuration
environment                  = "staging"
location                     = "Central US"
resource_group_name          = "rg-aks-multi-env-staging-centralus"
cluster_name                 = "aks-multi-env-staging"
acr_name                     = "acrmultienvstaging"
log_analytics_workspace_name = "law-aks-multi-env-staging"

# Staging-specific Configuration
enable_private_cluster            = true
api_server_authorized_ip_ranges   = []
acr_public_network_access_enabled = false
monitoring_level                  = "enhanced"

# Ingress Controller Settings - Staging
enable_internal_load_balancer  = true    # Internal load balancer for security
ingress_replica_count          = 2       # 2 replicas for availability
ingress_cpu_requests           = "200m"  # Higher resources than dev
ingress_memory_requests        = "180Mi" # Higher resources than dev
ingress_cpu_limits             = "500m"  # Moderate limits for staging
ingress_memory_limits          = "360Mi" # Moderate limits for staging
ingress_enable_metrics         = true    # Enable metrics for monitoring
ingress_enable_prometheus_rule = false   # Basic monitoring (can be enabled)
ingress_subnet_name            = "aks-subnet"
enable_cert_manager            = false               # Use Azure Key Vault for certificates
letsencrypt_email              = "admin@example.com" # Update with actual email
enable_azure_key_vault_csi     = true                # Enable for certificate management

# Tags
tags = {
  Environment = "staging"
  Project     = "aks-multi-env"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
