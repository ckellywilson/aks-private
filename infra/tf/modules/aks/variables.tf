variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "enable_private_cluster" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "aks_subnet_id" {
  description = "AKS subnet ID"
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID"
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = []
}

variable "system_node_pool" {
  description = "System node pool configuration"
  type = object({
    vm_size             = string
    node_count          = optional(number, 1)
    enable_auto_scaling = optional(bool, true)
    min_count           = optional(number, 1)
    max_count           = optional(number, 3)
    availability_zones  = optional(list(string), ["1", "2", "3"])
  })
  default = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
  }
}

variable "user_node_pools" {
  description = "User node pool configurations"
  type = map(object({
    vm_size             = string
    node_count          = optional(number, 1)
    enable_auto_scaling = optional(bool, true)
    min_count           = optional(number, 1)
    max_count           = optional(number, 5)
    availability_zones  = optional(list(string), ["1", "2", "3"])
    node_taints         = optional(list(string), [])
    node_labels         = optional(map(string), {})
  }))
  default = {
    user = {
      vm_size             = "Standard_D2s_v3"
      node_count          = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 5
    }
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID for AcrPull role assignment"
  type        = string
  default     = ""
}

variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be azure or kubenet."
  }
}

variable "network_policy" {
  description = "Network policy (azure, calico, or none)"
  type        = string
  default     = "azure"
}

variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "enable_azure_ad_integration" {
  description = "Enable Azure AD integration"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
