output "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.principal_id
}

output "cluster_identity_client_id" {
  description = "Client ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.client_id
}

output "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.id
}

output "kubelet_identity_principal_id" {
  description = "Principal ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.client_id
}
