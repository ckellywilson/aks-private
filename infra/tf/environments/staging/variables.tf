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
