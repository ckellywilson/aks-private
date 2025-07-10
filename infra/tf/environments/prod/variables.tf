variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-aks-prod-centralus-001"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-prod-centralus-001"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "acraksproducentralus001"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "law-aks-prod-centralus-001"
}

# Networking variables
variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.242.0.0/16"] # Production: dedicated large address space
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.242.0.0/24"
}

variable "bastion_subnet_address_prefix" {
  description = "Bastion subnet address prefix (requires exact name AzureBastionSubnet)"
  type        = string
  default     = "10.242.1.0/24"
}

variable "acr_pe_subnet_address_prefix" {
  description = "ACR private endpoint subnet address prefix"
  type        = string
  default     = "10.242.2.0/24"
}

variable "jumpbox_subnet_address_prefix" {
  description = "Jump box subnet address prefix"
  type        = string
  default     = "10.242.3.0/24"
}

# AKS Configuration
variable "enable_private_cluster" {
  description = "Enable private cluster"
  type        = bool
  default     = true # Production: always private
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = [] # Production: no public access
}

# ACR Configuration
variable "acr_public_network_access_enabled" {
  description = "Enable public network access for ACR"
  type        = bool
  default     = false # Production: private access only
}

# Monitoring Configuration
variable "monitoring_level" {
  description = "Monitoring level (basic, enhanced, full)"
  type        = string
  default     = "full" # Production: comprehensive monitoring
  validation {
    condition     = contains(["basic", "enhanced", "full"], var.monitoring_level)
    error_message = "Monitoring level must be one of: basic, enhanced, full."
  }
}

# Bastion Configuration
variable "enable_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = true # Production: enable for secure access
}

# Jump Box Configuration
variable "enable_jumpbox" {
  description = "Enable jump box VM for management"
  type        = bool
  default     = true # Production: enable for additional management access
}

variable "jumpbox_admin_ssh_public_key" {
  description = "SSH public key for jump box VM admin user"
  type        = string
  default     = "" # Must be provided for production
}

# Ingress Controller Configuration - Production
variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for ingress controller"
  type        = bool
  default     = true # Production: internal load balancer for security
}

variable "ingress_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 3 # Production: 3 replicas for high availability
}

variable "ingress_cpu_requests" {
  description = "CPU requests for ingress controller"
  type        = string
  default     = "500m" # Production: high performance resources
}

variable "ingress_memory_requests" {
  description = "Memory requests for ingress controller"
  type        = string
  default     = "512Mi" # Production: high performance resources
}

variable "ingress_cpu_limits" {
  description = "CPU limits for ingress controller"
  type        = string
  default     = "1000m" # Production: generous limits for performance
}

variable "ingress_memory_limits" {
  description = "Memory limits for ingress controller"
  type        = string
  default     = "1Gi" # Production: generous limits for performance
}

variable "ingress_enable_metrics" {
  description = "Enable metrics collection for ingress controller"
  type        = bool
  default     = true # Production: comprehensive metrics
}

variable "ingress_enable_prometheus_rule" {
  description = "Enable Prometheus monitoring rules"
  type        = bool
  default     = true # Production: full monitoring and alerting
}

variable "ingress_subnet_name" {
  description = "Subnet name for internal load balancer"
  type        = string
  default     = "aks-subnet"
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for automatic certificate management"
  type        = bool
  default     = false # Production: use Azure Key Vault for certificates
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com" # Update with actual email
}

variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = true # Production: enable for secure certificate management
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "aks-private"
    ManagedBy   = "Terraform"
    Owner       = "PlatformTeam"
    Purpose     = "Production AKS Cluster"
    CostCenter  = "Production"
    Compliance  = "Required"
    Backup      = "Required"
  }
}
