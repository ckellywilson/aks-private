output "ingress_controller_ip" {
  description = "IP address of the ingress controller load balancer"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].ip, null)
}

output "ingress_controller_hostname" {
  description = "Hostname of the ingress controller load balancer"
  value       = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "ingress_namespace" {
  description = "Namespace where ingress controller is deployed"
  value       = kubernetes_namespace.ingress_nginx.metadata[0].name
}

output "ingress_controller_service_name" {
  description = "Name of the ingress controller service"
  value       = data.kubernetes_service.ingress_nginx.metadata[0].name
}

output "cert_manager_enabled" {
  description = "Whether cert-manager is enabled"
  value       = var.enable_cert_manager
}

output "letsencrypt_issuer_name" {
  description = "Name of the Let's Encrypt ClusterIssuer"
  value       = var.enable_cert_manager ? "letsencrypt-prod" : null
}

output "azure_key_vault_csi_enabled" {
  description = "Whether Azure Key Vault CSI driver is enabled"
  value       = var.enable_azure_key_vault_csi
}

output "ingress_class" {
  description = "Ingress class name"
  value       = "nginx"
}
