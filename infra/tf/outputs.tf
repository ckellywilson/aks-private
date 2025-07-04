# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# AKS Cluster
output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "cluster_node_resource_group" {
  description = "Resource group containing AKS cluster nodes"
  value       = module.aks.node_resource_group
}

output "cluster_identity" {
  description = "AKS cluster managed identity"
  value       = module.aks.cluster_identity
  sensitive   = true
}

# Kubernetes Connection
output "host" {
  description = "Kubernetes cluster server host"
  value       = module.aks.host
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded client certificate"
  value       = module.aks.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded client key"
  value       = module.aks.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = module.aks.cluster_ca_certificate
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw Kubernetes configuration"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

# Network
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.networking.subnet_id
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = module.networking.private_dns_zone_id
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = module.networking.bastion_public_ip
}

# Container Registry
output "container_registry_id" {
  description = "ID of the container registry"
  value       = module.registry.container_registry_id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.registry.container_registry_name
}

output "container_registry_login_server" {
  description = "Login server of the container registry"
  value       = module.registry.container_registry_login_server
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_name
}

# Identity
output "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  value       = module.identity.cluster_identity_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  value       = module.identity.cluster_identity_principal_id
}

output "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  value       = module.identity.kubelet_identity_id
}

output "kubelet_identity_principal_id" {
  description = "Principal ID of the kubelet managed identity"
  value       = module.identity.kubelet_identity_principal_id
}

# Connection Commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

output "bastion_connect_command" {
  description = "Command to connect through Bastion (if applicable)"
  value       = var.private_cluster_enabled ? "Connect through Azure Bastion at ${module.networking.bastion_public_ip}" : "Direct connection available"
}

# Jump VM outputs
output "jump_vm_name" {
  description = "Name of the jump VM"
  value       = module.networking.jump_vm_name
}

output "jump_vm_id" {
  description = "ID of the jump VM"
  value       = module.networking.jump_vm_id
}

output "jump_vm_private_ip" {
  description = "Private IP address of the jump VM"
  value       = module.networking.jump_vm_private_ip
}

output "jump_vm_admin_username" {
  description = "Admin username for the jump VM"
  value       = module.networking.jump_vm_admin_username
}

output "jump_vm_admin_password" {
  description = "Admin password for the jump VM"
  value       = module.networking.jump_vm_admin_password
  sensitive   = true
}

output "jump_vm_ssh_private_key" {
  description = "SSH private key for the jump VM (store securely)"
  value       = module.networking.jump_vm_ssh_private_key
  sensitive   = true
}

output "jump_vm_connection_instructions" {
  description = "Instructions for connecting to the jump VM via Bastion"
  value = var.private_cluster_enabled ? join("\n", [
    "=== AZURE BASTION CONNECTION OPTIONS ===",
    "",
    "OPTION 1: PASSWORD AUTHENTICATION (Easiest)",
    "1. Navigate to Azure Portal: https://portal.azure.com",
    "2. Go to: Resource Groups > ${azurerm_resource_group.main.name} > ${module.networking.jump_vm_name}",
    "3. Click 'Connect' > 'Bastion'",
    "4. Username: ${module.networking.jump_vm_admin_username}",
    "5. Authentication Type: Password",
    "6. Password: Use output 'jump_vm_admin_password' or set custom password",
    "",
    "OPTION 2: SSH KEY AUTHENTICATION (More Secure)",
    "1. Save the SSH private key from 'jump_vm_ssh_private_key' output to a file",
    "2. In Bastion connection, select 'SSH Private Key'",
    "3. Upload or paste the private key",
    "",
    "OPTION 3: Azure CLI",
    "# With password:",
    "az network bastion ssh --name ${var.bastion_name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${module.networking.jump_vm_id} --auth-type password --username ${module.networking.jump_vm_admin_username}",
    "",
    "# With SSH key:",
    "az network bastion ssh --name ${var.bastion_name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${module.networking.jump_vm_id} --auth-type ssh-key --username ${module.networking.jump_vm_admin_username} --ssh-key <path-to-private-key>"
  ]) : "Jump VM not deployed (private cluster disabled)"
}
