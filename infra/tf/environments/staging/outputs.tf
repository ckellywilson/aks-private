output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_private_fqdn" {
  description = "AKS cluster private FQDN"
  value       = module.aks.cluster_private_fqdn
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

output "bastion_fqdn" {
  description = "Bastion host FQDN"
  value       = module.networking.bastion_fqdn
}

# Staging-specific outputs
output "cluster_access_instructions" {
  description = "Instructions for accessing the staging cluster"
  value       = <<-EOT
    Staging AKS Cluster Access (Private Cluster):
    
    1. Connect via Azure Bastion:
       - Navigate to Azure Portal
       - Go to Bastion: ${module.networking.bastion_fqdn}
       - Connect to a VM in the VNet with kubectl installed
    
    2. Alternative - Private endpoint access from connected network:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}
    
    3. Verify cluster access:
       kubectl get nodes
       kubectl get namespaces
    
    4. ACR access (from within VNet):
       az acr login --name ${module.acr.acr_name}
    
    Note: This is a private cluster accessible only through the VNet or Bastion.
    Private FQDN: ${module.aks.cluster_private_fqdn}
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
    bastion_subnet_id          = module.networking.bastion_subnet_id
    acr_pe_subnet_id           = module.networking.acr_pe_subnet_id
  }
}
