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

# Ingress Controller Settings - Production
enable_internal_load_balancer  = true    # Internal load balancer for security
ingress_replica_count          = 3       # High availability with 3 replicas
ingress_cpu_requests           = "500m"  # Higher resources for production
ingress_memory_requests        = "512Mi" # Higher resources for production
ingress_cpu_limits             = "1000m" # Higher limits for production
ingress_memory_limits          = "1Gi"   # Higher limits for production
ingress_enable_metrics         = true    # Enable comprehensive metrics
ingress_enable_prometheus_rule = true    # Enable advanced monitoring rules
ingress_subnet_name            = "aks-subnet"
enable_cert_manager            = true                   # Enable Let's Encrypt certificates
letsencrypt_email              = "admin@yourdomain.com" # Update with actual email
enable_azure_key_vault_csi     = true                   # Enable Azure Key Vault integration

# Tags
tags = {
  Environment = "production"
  Project     = "aks-multi-env"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
  CostCenter  = "production"
  Criticality = "high"
}
