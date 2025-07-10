variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-aks-dev-centralus-001"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-dev-centralus-001"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "acraksdevcentralus001"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "law-aks-dev-centralus-001"
}

# Networking variables
variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "bastion_subnet_address_prefix" {
  description = "Bastion subnet address prefix"
  type        = string
  default     = "10.0.2.0/24"
}

variable "acr_pe_subnet_address_prefix" {
  description = "ACR private endpoint subnet address prefix"
  type        = string
  default     = "10.0.3.0/24"
}

variable "jumpbox_subnet_address_prefix" {
  description = "Jump box subnet address prefix"
  type        = string
  default     = "10.0.4.0/24"
}

# Dev-specific variables
variable "enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = false # Dev: allow public access for development
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Dev: open access for development
}

variable "acr_public_network_access_enabled" {
  description = "Enable public network access to ACR"
  type        = bool
  default     = true # Dev: allow public access
}

variable "monitoring_level" {
  description = "Monitoring level (basic, enhanced, full)"
  type        = string
  default     = "basic" # Dev: basic monitoring
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = false # Dev: not needed for development
}

variable "enable_jumpbox" {
  description = "Enable jump box VM for management"
  type        = bool
  default     = false # Dev: not needed for development
}

variable "jumpbox_admin_ssh_public_key" {
  description = "SSH public key for jump box VM admin user"
  type        = string
  default     = "" # Only needed when jumpbox is enabled
}

# Ingress Controller Configuration
variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for ingress controller"
  type        = bool
  default     = false # Dev: public load balancer for easy access
}

variable "ingress_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 1 # Dev: single replica for cost optimization
}

variable "ingress_cpu_requests" {
  description = "CPU requests for ingress controller"
  type        = string
  default     = "100m" # Dev: minimal resources
}

variable "ingress_memory_requests" {
  description = "Memory requests for ingress controller"
  type        = string
  default     = "90Mi" # Dev: minimal resources
}

variable "ingress_cpu_limits" {
  description = "CPU limits for ingress controller"
  type        = string
  default     = "200m" # Dev: low limits for cost control
}

variable "ingress_memory_limits" {
  description = "Memory limits for ingress controller"
  type        = string
  default     = "180Mi" # Dev: low limits for cost control
}

variable "ingress_enable_metrics" {
  description = "Enable metrics collection for ingress controller"
  type        = bool
  default     = true # Dev: enable basic metrics
}

variable "ingress_enable_prometheus_rule" {
  description = "Enable Prometheus monitoring rules"
  type        = bool
  default     = false # Dev: no advanced monitoring rules
}

variable "ingress_subnet_name" {
  description = "Subnet name for internal load balancer"
  type        = string
  default     = "aks-subnet"
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for automatic certificate management"
  type        = bool
  default     = true # Dev: enable Let's Encrypt certificates
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com" # Update with actual email
}

variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = false # Dev: not needed for development
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "aks-private"
    ManagedBy   = "Terraform"
    Owner       = "DevOpsTeam"
    Purpose     = "Development AKS Cluster"
    CostCenter  = "Development"
  }
}
