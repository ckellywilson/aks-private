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

# Development-specific ingress access instructions
output "ingress_access_instructions" {
  description = "Instructions for accessing applications through ingress"
  value       = <<-EOT
    Ingress Controller Access:
    
    1. Get ingress controller IP:
       kubectl get service ingress-nginx-controller -n ingress-nginx
       
    2. Create an ingress for your application:
       kubectl apply -f your-ingress.yaml
       
    3. Test ingress connectivity:
       curl -H "Host: your-app.example.com" http://${module.ingress.ingress_controller_ip}
    
    4. For HTTPS with Let's Encrypt (cert-manager enabled):
       - Add cert-manager.io/cluster-issuer: "letsencrypt-prod" annotation
       - Configure TLS section in your ingress
    
    Ingress Controller IP: ${module.ingress.ingress_controller_ip}
    Ingress Class: nginx
    Cert Manager: ${module.ingress.cert_manager_enabled ? "Enabled" : "Disabled"}
  EOT
}
