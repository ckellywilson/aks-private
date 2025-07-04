# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Central US"
}

variable "location_short" {
  description = "Short name for Azure location"
  type        = string
  default     = "cus"
}

# Resource Naming (Azure best practices: <type>-<workload>-<env>-<region>-<instance>)
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-dev-cus-001"
}

variable "cluster_resource_group_name" {
  description = "Name of the cluster resource group for AKS managed resources"
  type        = string
  default     = "rg-aks-nodes-dev-cus-001"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-cluster-dev-cus-001"
}

variable "registry_name" {
  description = "Name of the container registry"
  type        = string
  default     = "craksdevcus001"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
  default     = "log-aks-dev-cus-001"
}

variable "bastion_name" {
  description = "Name of the Bastion host"
  type        = string
  default     = "bas-aks-dev-cus-001"
}

# Network Infrastructure
variable "vnet_name" {
  description = "Name of the VNet"
  type        = string
  default     = "vnet-aks-dev-cus-001"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "snet-aks-dev-cus-001"
}

variable "bastion_subnet_name" {
  description = "Name of the Bastion subnet"
  type        = string
  default     = "AzureBastionSubnet"
}

# AKS Cluster Configuration
variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = "1.32"

  validation {
    condition     = can(regex("^\\d+\\.\\d+", var.kubernetes_version))
    error_message = "Kubernetes version must be in format 'x.y' (e.g., '1.32')."
  }
}

# System Node Pool Configuration
variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1

  validation {
    condition     = var.system_node_count >= 1 && var.system_node_count <= 5
    error_message = "System node count must be between 1 and 5."
  }
}

variable "system_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

# User Node Pool Configuration
variable "user_node_count" {
  description = "Initial number of nodes in the user node pool"
  type        = number
  default     = 1

  validation {
    condition     = var.user_node_count >= 1 && var.user_node_count <= 10
    error_message = "User node count must be between 1 and 10."
  }
}

variable "user_min_count" {
  description = "Minimum number of nodes in the user node pool"
  type        = number
  default     = 1

  validation {
    condition     = var.user_min_count >= 1 && var.user_min_count <= 10
    error_message = "User minimum count must be between 1 and 10."
  }
}

variable "user_max_count" {
  description = "Maximum number of nodes in the user node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.user_max_count >= 1 && var.user_max_count <= 100
    error_message = "User maximum count must be between 1 and 100."
  }
}

variable "user_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

# Network Configuration
variable "subnet_cidr" {
  description = "CIDR for the subnet"
  type        = string
  default     = "10.240.0.0/16"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid IPv4 CIDR block."
  }
}

variable "dns_service_ip" {
  description = "IP address for DNS service"
  type        = string
  default     = "10.0.0.10"

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IPv4 address."
  }
}

variable "network_policy" {
  description = "Network policy to use (azure, calico, or none)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "none"], var.network_policy)
    error_message = "Network policy must be 'azure', 'calico', or 'none'."
  }
}

# Security Configuration
variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy addon"
  type        = bool
  default     = true
}

variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = true
}

# Note: Add-on variables removed as they are deployed separately via scripts

# Jump VM Configuration
variable "jump_vm_name" {
  description = "Name of the jump VM for Bastion access"
  type        = string
  default     = "vm-jumpbox-dev-cus-001"
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
  default     = "AKS-Dev-Pass001!"
  sensitive   = true
}

# Resource Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "aks-private"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "IT-Infrastructure"
    Purpose     = "Private AKS Cluster"
    Instance    = "001"
  }
}
