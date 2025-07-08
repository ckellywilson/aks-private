# AKS Pr**Example**: `rg-aks-dev-cus-001`
- `rg` = Resource Group
- `aks` = Workload (matches workspace: aks-private)
- `dev` = Environment 
- `cus` = Central US region
- `001` = Static instance identifier

## 🏗️ Architecture Overview

This configuration creates:

- **Private AKS Cluster** (`aks-cluster-dev-cus-001`) with system and user node pools
- **Azure Container Registry** (`craksdevcus001`) with private endpoint
- **Log Analytics Workspace** (`log-aks-dev-cus-001`) for monitoring
- **User-assigned Managed Identities** for cluster and kubelet
- **Azure Bastion Host** (`bas-aks-dev-cus-001`) for secure access
- **Jump VM** (`vm-jumpbox-dev-cus-001`) for kubectl operationsraform Configuration

This Terraform configuration deploys a production-ready, private Azure Kubernetes Service (AKS) cluster with all necessary supporting infrastructure using Azure best practice naming conventions.

## �️ Naming Convention

**Format**: `<resource-type>-<workload>-<environment>-<region>-<instance>`

**Example**: `rg-aks-dev-cus-001`
- `rg` = Resource Group
- `aks` = Workload (matches workspace: aks-private)
- `dev` = Environment 
- `cus` = Central US region
- `001` = Static instance identifier

## �🏗️ Architecture Overview

This configuration creates:

- **Private AKS Cluster** (`aks-cluster-dev-cus-001`) with system and user node pools
- **Azure Container Registry** (`craksdevcus001`) with private endpoint
- **Log Analytics Workspace** (`log-aks-dev-cus-001`) for monitoring
- **User-assigned Managed Identities** for cluster and kubelet
- **Azure Bastion Host** (`bas-aks-dev-cus-001`) for secure access
- **Jump VM** (`vm-jumpbox-dev-cus-001`) for kubectl operations
- **Private DNS Zones** for private endpoints
- **Network Security Groups** with appropriate rules
- **Manual add-on deployment** for nginx-ingress and cert-manager

## 📋 Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.0 installed
3. **kubectl** installed for cluster access
4. **Helm** >= 3.8 installed for package management
5. **Appropriate Azure permissions** to create resources
6. **Existing network infrastructure** (VNet, Subnet) as specified in requirements

### Required Azure Permissions

Your account needs the following minimum permissions:
- Contributor role on the subscription or resource group
- User Access Administrator role for role assignments
- Ability to create managed identities and role assignments

### Provider Versions

This configuration uses:
- **AzureRM Provider**: ~> 4.35 (latest)
- **Kubernetes Provider**: ~> 2.37
- **Helm Provider**: ~> 2.17

## 🚀 Quick Start

### 1. Setup Backend Storage

```bash
# Create storage account for Terraform state
make setup-backend
```

### 2. Configure Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the variables file
vim terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
make init

# Plan deployment
make plan

# Apply configuration
make apply
```

### 4. Access Your Cluster

```bash
# Get cluster credentials
make get-credentials

# Verify cluster
make verify-cluster
```

## 📁 Module Structure

```
infra/tf/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider version constraints
├── backend.tf                 # Remote state configuration
├── terraform.tfvars.example   # Example variables
├── Makefile                   # Automation targets
├── README.md                  # This file
└── modules/
    ├── aks/                   # AKS cluster module
    ├── identity/              # Managed identity module
    ├── networking/            # Network infrastructure module
    ├── registry/              # Container registry module
    └── monitoring/            # Log analytics module
```

## 🔧 Configuration

### Environment Variables

Key configuration variables in `terraform.tfvars`:

```hcl
# Environment Configuration
environment = "dev"
location    = "Central US"

# Resource Naming
resource_group_name         = "rg-aks-dev-cus-001"
cluster_resource_group_name = "rg-aks37921"
cluster_name               = "aks37921"

# Cluster Configuration
kubernetes_version = "1.32"
system_node_count = 1
user_node_count   = 1
user_min_count    = 1
user_max_count    = 3

# Network Configuration
subnet_cidr     = "10.240.0.0/16"
service_cidr    = "10.0.0.0/16"
dns_service_ip  = "10.0.0.10"

# Security
private_cluster_enabled = true
enable_azure_policy     = true
```

### Node Pools

The configuration creates two node pools:

1. **System Node Pool** (`system`):
   - Dedicated for system workloads
   - Tainted with `CriticalAddonsOnly=true:NoSchedule`
   - Default: 1 node, `Standard_D2s_v3`

2. **User Node Pool** (`user`):
   - For application workloads
   - Auto-scaling enabled (1-3 nodes)
   - Default: `Standard_D4s_v3`

## 📊 Monitoring and Add-ons

### Included Add-ons

- **Azure Monitor for Containers**: Cluster and pod monitoring
- **Azure Policy**: Policy enforcement and compliance
- **nginx-ingress**: Latest ingress controller via Helm
- **cert-manager**: TLS certificate automation via Helm
- **Workload Identity**: Azure AD workload identity integration

### Accessing Logs

```bash
# View cluster logs in Azure portal
az aks browse --resource-group rg-aks-dev-cus-001 --name aks-cluster-dev-cus-001

# Query logs with kubectl
kubectl logs -n kube-system -l app=azure-policy
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## 🔐 Security Features

### Private Cluster Configuration

- Private API server endpoint
- Nodes deployed in private subnet
- Private DNS zone for API server resolution
- Azure Bastion for secure management access

### Identity and Access Management

- User-assigned managed identities for cluster and kubelet
- Minimal required role assignments
- Azure AD integration for RBAC
- Pod Security Standards enabled

### Network Security

- Network Security Groups with restrictive rules
- Azure CNI with network policies
- Private endpoints for container registry
- VNet integration for all components

## 🌐 Networking

### Network Architecture

```
Internet
    │
    ├── Azure Bastion (Public IP)
    │
    └── VNet (vnet37921)
        └── AKS Subnet (snet37921: 10.240.0.0/16)
            ├── AKS Nodes (Private IPs)
            ├── Private Endpoint (ACR)
            └── Private DNS Zones
```

### Access Patterns

1. **Developer Access**: Through Azure Bastion or VPN
2. **Application Traffic**: Through private load balancer
3. **Registry Access**: Private endpoint within VNet

## 🛠️ Management Commands

### Makefile Targets

```bash
make help              # Show all available targets
make init              # Initialize Terraform
make plan              # Plan deployment
make apply             # Deploy infrastructure
make destroy           # Destroy infrastructure
make get-credentials   # Configure kubectl
make verify-cluster    # Verify cluster health
make show-endpoints    # Display important endpoints
make clean             # Clean temporary files
```

### Environment-Specific Deployment

```bash
# Development
make dev-plan
make dev-apply

# Staging
make staging-plan ENV=staging TF_VAR_FILE=staging.tfvars
make staging-apply ENV=staging

# Production
make prod-plan ENV=prod TF_VAR_FILE=production.tfvars
make prod-apply ENV=prod
```

## 🔄 State Management

### Backend Configuration

Terraform state is stored in Azure Storage:

- **Storage Account**: `staksdevcus001tfstate`
- **Container**: `terraform-state`
- **State File**: `dev.tfstate`
- **Features**: Encryption at rest, blob versioning, access controls

### State Commands

```bash
# Refresh state
make refresh

# List resources
make state-list

# Show outputs
make output
```

## 📈 Scaling

### Node Pool Scaling

```bash
# Scale user node pool
az aks nodepool scale \
  --resource-group rg-aks-dev-cus-001 \
  --cluster-name aks37921 \
  --name user \
  --node-count 5
```

### Application Scaling

```bash
# Enable cluster autoscaler
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-status
  namespace: kube-system
data:
  nodes.max: "10"
  nodes.min: "1"
EOF
```

## 🚨 Troubleshooting

### Common Issues

1. **Cannot access API server**
   - Ensure you're connected through Bastion or authorized network
   - Check private DNS zone configuration

2. **Pods can't pull images**
   - Verify ACR role assignments
   - Check private endpoint connectivity

3. **Ingress not working**
   - Verify nginx-ingress controller is running
   - Check LoadBalancer service configuration

### Debug Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check cert-manager
kubectl get pods -n cert-manager
kubectl get clusterissuer
```

## 🔧 Customization

### Adding Custom Node Pools

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "custom" {
  name                  = "custom"
  kubernetes_cluster_id = module.aks.cluster_id
  vm_size               = "Standard_D8s_v3"
  node_count            = 2
  
  node_taints = ["custom=true:NoSchedule"]
  node_labels = {
    "workload-type" = "custom"
  }
}
```

### Custom Helm Deployments

```hcl
resource "helm_release" "custom_app" {
  name       = "custom-app"
  repository = "https://charts.example.com"
  chart      = "custom-app"
  namespace  = "custom"
  
  create_namespace = true
  depends_on       = [module.aks]
}
```

## 📝 Outputs

After deployment, the following information is available:

```bash
# Connection information
terraform output kubectl_config_command
terraform output bastion_connect_command

# Resource details
terraform output cluster_id
terraform output container_registry_login_server
terraform output log_analytics_workspace_id
```

## 🔒 Security Considerations

1. **Rotate certificates regularly**
2. **Keep Kubernetes version updated**
3. **Review and update network security groups**
4. **Monitor Azure Policy compliance**
5. **Audit access logs regularly**
6. **Use Azure Key Vault for secrets**

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Configuration ID**: aks37921  
**Environment**: Development  
**Region**: Central US  
**Last Updated**: July 2025
