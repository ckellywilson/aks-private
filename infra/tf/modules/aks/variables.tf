variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "cluster_resource_group_name" {
  description = "Name of the cluster resource group for AKS managed resources"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
}

# Identity variables
variable "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  type        = string
}

variable "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  type        = string
}

variable "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  type        = string
}

variable "kubelet_identity_principal_id" {
  description = "Principal ID of the kubelet managed identity"
  type        = string
}

variable "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  type        = string
}

# Networking variables
variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for DNS service"
  type        = string
}

variable "network_policy" {
  description = "Network policy to use"
  type        = string
  default     = "azure"
}

# System node pool variables
variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "system_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

# User node pool variables
variable "user_node_count" {
  description = "Initial number of nodes in the user node pool"
  type        = number
  default     = 1
}

variable "user_min_count" {
  description = "Minimum number of nodes in the user node pool"
  type        = number
  default     = 1
}

variable "user_max_count" {
  description = "Maximum number of nodes in the user node pool"
  type        = number
  default     = 3
}

variable "user_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

# Security variables
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

# Monitoring variables
variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

# Container Registry variables
variable "container_registry_id" {
  description = "ID of the container registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
