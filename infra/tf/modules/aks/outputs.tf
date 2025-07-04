output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "node_resource_group" {
  description = "Resource group containing AKS cluster nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "cluster_identity" {
  description = "AKS cluster managed identity"
  value       = azurerm_kubernetes_cluster.main.identity
  sensitive   = true
}

output "host" {
  description = "Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded client key"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity" {
  description = "Kubelet identity used by agent pool"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity
  sensitive   = true
}

output "system_node_pool_id" {
  description = "ID of the system node pool"
  value       = azurerm_kubernetes_cluster.main.default_node_pool[0].name
}

output "user_node_pool_id" {
  description = "ID of the user node pool"
  value       = azurerm_kubernetes_cluster_node_pool.user.id
}
