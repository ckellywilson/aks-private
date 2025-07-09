# Terraform variables file for AKS Private Cluster
# Azure best practice naming convention with static instance identifier

# Environment Configuration
environment = "dev"
location    = "Central US"

# Resource Naming (Azure best practices: <type>-<workload>-<env>-<region>-<instance>)
resource_group_name          = "rg-aks-dev-cus-001"
cluster_resource_group_name  = "rg-aks-nodes-dev-cus-001"
cluster_name                 = "aks-cluster-dev-cus-001"
registry_name                = "craksdevcus001"
log_analytics_workspace_name = "log-aks-dev-cus-001"
bastion_name                 = "bas-aks-dev-cus-001"

# Network Infrastructure
vnet_name           = "vnet-aks-dev-cus-001"
subnet_name         = "snet-aks-dev-cus-001"
bastion_subnet_name = "AzureBastionSubnet"

# AKS Cluster Configuration
kubernetes_version = "1.32"

# System Node Pool Configuration (for control plane workloads)
system_node_count = 1
system_vm_size    = "Standard_D2s_v3"

# User Node Pool Configuration (for application workloads)
user_node_count = 1
user_min_count  = 1
user_max_count  = 3
user_vm_size    = "Standard_D4s_v3"

# Network Configuration
subnet_cidr    = "10.240.0.0/24"
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"
network_policy = "azure"

# Security Configuration
private_cluster_enabled    = true
enable_azure_policy        = true
enable_pod_security_policy = true

# Jump VM Configuration (for Bastion access)
jump_vm_name           = "vm-jumpbox-dev-cus-001"
jump_vm_size           = "Standard_B2s"
jump_vm_admin_username = "azureuser"
jump_vm_admin_password = "AKS-Dev-Pass001!"

# Note: Add-on configuration moved to separate deployment scripts

# Resource Tags
tags = {
  Environment = "dev"
  Project     = "aks-private"
  ManagedBy   = "Terraform"
  Owner       = "DevOps Team"
  CostCenter  = "IT-Infrastructure"
  Purpose     = "Private AKS Cluster"
  Instance    = "001"
}
