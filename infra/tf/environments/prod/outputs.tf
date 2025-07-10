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

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = module.networking.bastion_public_ip
}

output "jumpbox_private_ip" {
  description = "Jumpbox private IP address"
  value       = module.networking.jumpbox_private_ip
}

# Production-specific outputs
output "cluster_access_instructions" {
  description = "Instructions for accessing the production cluster"
  value       = <<-EOT
    Production AKS Cluster Access:
    
    IMPORTANT: This is a production cluster with private access only.
    
    1. Connect to the jumpbox through Bastion:
       - Use Azure Bastion to connect to the jumpbox
       - Bastion Public IP: ${module.networking.bastion_public_ip}
    
    2. From the jumpbox, get cluster credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}
    
    3. Verify cluster access:
       kubectl get nodes
       kubectl get namespaces
    
    4. ACR login (for pushing/pulling images):
       az acr login --name ${module.acr.acr_name}
    
    Note: This is a production cluster with private access and enhanced security.
    Direct access from outside the VNet is not allowed.
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

# Ingress Controller Outputs
output "ingress_controller_ip" {
  description = "IP address of the ingress controller load balancer"
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

output "cert_manager_enabled" {
  description = "Whether cert-manager is enabled"
  value       = module.ingress.cert_manager_enabled
}

output "letsencrypt_issuer_name" {
  description = "Name of the Let's Encrypt ClusterIssuer"
  value       = module.ingress.letsencrypt_issuer_name
}

output "azure_key_vault_csi_enabled" {
  description = "Whether Azure Key Vault CSI driver is enabled"
  value       = module.ingress.azure_key_vault_csi_enabled
}

# Production-specific ingress access instructions
output "ingress_access_instructions" {
  description = "Instructions for accessing applications through ingress"
  value       = <<-EOT
    Production Ingress Controller Access:
    
    IMPORTANT: This is a production environment with enhanced security.
    
    1. Access from jumpbox only:
       - Connect to jumpbox through Azure Bastion
       - All ingress management must be done from the jumpbox
    
    2. Get ingress controller IP:
       kubectl get service ingress-nginx-controller -n ingress-nginx
       
    3. Create an ingress for your application:
       kubectl apply -f your-ingress.yaml
       
    4. Test ingress connectivity (from jumpbox):
       curl -H "Host: your-app.yourdomain.com" http://${module.ingress.ingress_controller_ip}
    
    5. For HTTPS with Let's Encrypt (cert-manager enabled):
       - Add cert-manager.io/cluster-issuer: "letsencrypt-prod" annotation
       - Configure TLS section in your ingress
    
    6. Azure Key Vault integration:
       - Use Azure Key Vault CSI driver for secrets management
       - Configure SecretProviderClass for accessing Key Vault secrets
    
    Ingress Controller IP: ${module.ingress.ingress_controller_ip}
    Ingress Class: nginx
    Load Balancer Type: Internal (private)
    Cert Manager: ${module.ingress.cert_manager_enabled ? "Enabled" : "Disabled"}
    Azure Key Vault CSI: ${module.ingress.azure_key_vault_csi_enabled ? "Enabled" : "Disabled"}
    
    Security Notes:
    - All ingress traffic is routed through internal load balancer
    - TLS certificates are managed by cert-manager with Let's Encrypt
    - Secrets are managed through Azure Key Vault CSI driver
    - High availability with multiple replicas
    - Resource limits configured for production workloads
  EOT
}
