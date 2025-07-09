output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.acr.acr_login_server
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config
  sensitive   = true
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = module.monitoring.log_analytics_workspace_name
}

output "vnet_name" {
  description = "Virtual network name"
  value       = module.networking.vnet_name
}

# Development-specific outputs
output "cluster_access_instructions" {
  description = "Instructions for accessing the development cluster"
  value       = <<-EOT
    Development AKS Cluster Access:
    
    1. Get cluster credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}
    
    2. Verify cluster access:
       kubectl get nodes
       kubectl get namespaces
    
    3. ACR login (for pushing/pulling images):
       az acr login --name ${module.acr.acr_name}
    
    Note: This is a development cluster with public access enabled for easy development.
  EOT
}

output "resource_ids" {
  description = "Resource IDs for CI/CD integration"
  value = {
    resource_group_id          = azurerm_resource_group.main.id
    cluster_id                 = module.aks.cluster_id
    acr_id                     = module.acr.acr_id
    log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
    vnet_id                    = module.networking.vnet_id
  }
}
