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

# Ingress Controller Outputs
output "ingress_controller_ip" {
  description = "Internal IP address of the ingress controller load balancer"
  value       = module.ingress.ingress_controller_ip
}

output "ingress_controller_hostname" {
  description = "Hostname of the ingress controller load balancer"
  value       = module.ingress.ingress_controller_hostname
}

output "ingress_namespace" {
  description = "Namespace where ingress controller is deployed"
  value       = module.ingress.ingress_namespace
}

output "ingress_class" {
  description = "Ingress class name"
  value       = module.ingress.ingress_class
}

output "azure_key_vault_csi_enabled" {
  description = "Whether Azure Key Vault CSI driver is enabled"
  value       = module.ingress.azure_key_vault_csi_enabled
}

# Staging-specific ingress access instructions
output "ingress_access_instructions" {
  description = "Instructions for accessing applications through ingress in staging"
  value       = <<-EOT
    Staging Ingress Controller Access (Private):
    
    1. Access through Bastion or from connected network:
       - Ingress controller uses internal load balancer
       - Access from within VNet or through Bastion host
    
    2. Get ingress controller internal IP:
       kubectl get service ingress-nginx-controller -n ingress-nginx
       
    3. Create an ingress for your application:
       kubectl apply -f your-ingress.yaml
       
    4. Test ingress connectivity (from within VNet):
       curl -H "Host: your-app-staging.example.com" http://${module.ingress.ingress_controller_ip}
    
    5. For HTTPS with Azure Key Vault certificates:
       - Use Azure Key Vault CSI driver (enabled)
       - Configure SecretProviderClass for certificate retrieval
       - Reference in ingress TLS configuration
    
    Internal Ingress IP: ${module.ingress.ingress_controller_ip}
    Ingress Class: nginx
    Azure Key Vault CSI: ${module.ingress.azure_key_vault_csi_enabled ? "Enabled" : "Disabled"}
    
    Note: Ingress is only accessible from within the VNet or through Bastion.
  EOT
}
