variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "vnet_name" {
  description = "Name of the existing VNet"
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing subnet"
  type        = string
}

variable "bastion_subnet_name" {
  description = "Name of the Bastion subnet"
  type        = string
}

variable "bastion_name" {
  description = "Name of the Bastion host"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR for the subnet"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Jump VM Configuration
variable "jump_vm_name" {
  description = "Name of the jump VM"
  type        = string
  default     = "vm-jumpbox"
}

variable "jump_vm_size" {
  description = "Size of the jump VM"
  type        = string
  default     = "Standard_B2s"
}

variable "jump_vm_admin_username" {
  description = "Admin username for the jump VM"
  type        = string
  default     = "azureuser"
}

variable "jump_vm_admin_password" {
  description = "Admin password for the jump VM"
  type        = string
  default     = "AKS37921Pass!"
  sensitive   = true
}
