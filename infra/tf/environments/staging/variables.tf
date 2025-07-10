variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-aks-staging-centralus-001"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-staging-centralus-001"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "acraksstagingcentralus001"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "law-aks-staging-centralus-001"
}

# Networking variables
variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.1.1.0/24"
}

variable "bastion_subnet_address_prefix" {
  description = "Bastion subnet address prefix"
  type        = string
  default     = "10.1.2.0/24"
}

variable "acr_pe_subnet_address_prefix" {
  description = "ACR private endpoint subnet address prefix"
  type        = string
  default     = "10.1.3.0/24"
}

variable "jumpbox_subnet_address_prefix" {
  description = "Jump box subnet address prefix"
  type        = string
  default     = "10.1.4.0/24"
}

# Staging-specific variables
variable "enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = true # Staging: private for security
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = [] # Staging: no public access
}

variable "acr_public_network_access_enabled" {
  description = "Enable public network access to ACR"
  type        = bool
  default     = false # Staging: private for security
}

variable "monitoring_level" {
  description = "Monitoring level (basic, enhanced, full)"
  type        = string
  default     = "enhanced" # Staging: enhanced monitoring
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = true # Staging: enable for secure access
}

variable "enable_jumpbox" {
  description = "Enable jump box VM for management"
  type        = bool
  default     = false # Staging: optional
}

variable "jumpbox_admin_ssh_public_key" {
  description = "SSH public key for jump box VM admin user"
  type        = string
  default     = "" # Only needed when jumpbox is enabled
}

# Ingress Controller Configuration - Staging
variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for ingress controller"
  type        = bool
  default     = true # Staging: use internal load balancer for security
}

variable "ingress_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 2 # Staging: 2 replicas for availability
}

variable "ingress_cpu_requests" {
  description = "CPU requests for ingress controller"
  type        = string
  default     = "200m" # Staging: higher than dev
}

variable "ingress_memory_requests" {
  description = "Memory requests for ingress controller"
  type        = string
  default     = "180Mi" # Staging: higher than dev
}

variable "ingress_cpu_limits" {
  description = "CPU limits for ingress controller"
  type        = string
  default     = "500m" # Staging: moderate limits
}

variable "ingress_memory_limits" {
  description = "Memory limits for ingress controller"
  type        = string
  default     = "360Mi" # Staging: moderate limits
}

variable "ingress_enable_metrics" {
  description = "Enable metrics collection for ingress controller"
  type        = bool
  default     = true # Staging: enable metrics for monitoring
}

variable "ingress_enable_prometheus_rule" {
  description = "Enable Prometheus monitoring rules"
  type        = bool
  default     = false # Staging: basic monitoring rules (can be enabled)
}

variable "ingress_subnet_name" {
  description = "Subnet name for internal load balancer"
  type        = string
  default     = "aks-subnet"
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for automatic certificate management"
  type        = bool
  default     = false # Staging: use Azure Key Vault for certificates
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com" # Update with actual email
}

variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = true # Staging: enable for certificate management
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "aks-private"
    ManagedBy   = "Terraform"
    Owner       = "DevOpsTeam"
    Purpose     = "Staging AKS Cluster"
    CostCenter  = "PreProduction"
  }
}
