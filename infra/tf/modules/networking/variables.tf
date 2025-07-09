variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
}

variable "bastion_subnet_address_prefix" {
  description = "Bastion subnet address prefix (required for staging/prod)"
  type        = string
  default     = ""
}

variable "acr_pe_subnet_address_prefix" {
  description = "ACR private endpoint subnet address prefix (required for staging/prod)"
  type        = string
  default     = ""
}

variable "jumpbox_subnet_address_prefix" {
  description = "Jump box subnet address prefix (optional for prod)"
  type        = string
  default     = ""
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure access"
  type        = bool
  default     = false
}

variable "enable_jumpbox" {
  description = "Enable jump box VM for management"
  type        = bool
  default     = false
}

variable "jumpbox_admin_ssh_public_key" {
  description = "SSH public key for jump box VM admin user"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
