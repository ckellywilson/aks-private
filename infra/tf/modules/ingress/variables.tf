variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for ingress controller"
  type        = bool
  default     = false
}

variable "ingress_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 1
  validation {
    condition     = var.ingress_replica_count >= 1 && var.ingress_replica_count <= 10
    error_message = "Replica count must be between 1 and 10."
  }
}

variable "ingress_nginx_version" {
  description = "Version of ingress-nginx Helm chart"
  type        = string
  default     = "4.8.3"
}

variable "cpu_requests" {
  description = "CPU requests for ingress controller"
  type        = string
  default     = "100m"
}

variable "memory_requests" {
  description = "Memory requests for ingress controller"
  type        = string
  default     = "90Mi"
}

variable "cpu_limits" {
  description = "CPU limits for ingress controller"
  type        = string
  default     = "200m"
}

variable "memory_limits" {
  description = "Memory limits for ingress controller"
  type        = string
  default     = "180Mi"
}

variable "enable_metrics" {
  description = "Enable metrics collection for ingress controller"
  type        = bool
  default     = false
}

variable "enable_prometheus_rule" {
  description = "Enable Prometheus monitoring rules"
  type        = bool
  default     = false
}

variable "subnet_name" {
  description = "Subnet name for internal load balancer"
  type        = string
  default     = "aks-subnet"
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for automatic certificate management"
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "Version of cert-manager Helm chart"
  type        = string
  default     = "v1.13.0"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com"
}

variable "enable_azure_key_vault_csi" {
  description = "Enable Azure Key Vault CSI driver"
  type        = bool
  default     = false
}

variable "csi_secrets_store_version" {
  description = "Version of CSI Secrets Store Provider Azure chart"
  type        = string
  default     = "1.4.0"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
