# Multi-Environment AKS Cluster Deployment (Dev/Staging/Prod)

## Context
Deploying and managing Azure Kubernetes Service (AKS) clusters across multiple environments with environment-specific security and access configurations. Development environment prioritizes accessibility for rapid iteration, while staging and production environments implement enhanced security with private networking.

## Task
Deploy, configure, and troubleshoot AKS clusters across three environments with appropriate security postures, networking configurations, and integration with Azure services based on environment requirements.

## Implementation Workflow

### Phase 1: Foundation Setup
1. Create module directory structure (`modules/{aks,networking,acr,monitoring}`)
2. Implement networking module (foundation for all environments)
3. Create basic AKS module with conditional logic for public/private clusters
4. Test with development environment deployment

### Phase 2: Environment Progression  
1. Deploy and validate development environment (public access)
2. Extend modules for private networking capabilities
3. Deploy staging environment with private configurations
4. Deploy production with full security controls

### Phase 3: Automation & Operations
1. Create deployment scripts for each environment
2. Prepare infrastructure for CI/CD integration (without creating pipelines)
3. Add monitoring and alerting configurations
4. Document deployment procedures for chosen CI/CD platform

## Quick Start Guide

### Prerequisites
- Azure CLI installed and authenticated (`az login`)
- Terraform >= 1.0 installed
- kubectl installed
- Appropriate Azure permissions (Contributor on subscription)

### Rapid Development Setup (5 minutes)
```bash
# 1. Create module structure
mkdir -p infra/tf/{modules/{aks,networking,acr},environments/{dev,staging,prod}}

# 2. Deploy development environment
cd infra/tf/environments/dev
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan

# 3. Get kubectl credentials
az aks get-credentials --resource-group dev-aks-rg --name dev-aks
```

### Production Deployment Checklist
- [ ] Private cluster configuration validated in staging
- [ ] Bastion host access tested and documented
- [ ] Private DNS zones configured and tested
- [ ] ACR private endpoints functional
- [ ] Jump box access procedures documented
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery tested

## Environment Requirements

### 🔧 Development Environment
- **AKS Cluster**: Public API server endpoint for easy access
- **Azure Container Registry**: Public access for simplified development workflow
- **Networking**: Standard networking with basic security groups
- **Access**: Direct kubectl access from developer machines
- **Purpose**: Rapid development, testing, and experimentation

### 🧪 Staging Environment  
- **AKS Cluster**: Private API server with Private Link
- **Azure Container Registry**: Private ACR with VNet integration
- **Networking**: Private VNet with controlled access
- **Access**: Bastion host or VPN for secure management
- **Purpose**: Pre-production testing and validation

### 🏭 Production Environment
- **AKS Cluster**: Private API server with Private Link
- **Azure Container Registry**: Private ACR with VNet integration  
- **Networking**: Fully private networking with network security groups
- **Access**: Bastion host, VPN, or jump box for management
- **Purpose**: Production workloads with maximum security

## Environment-Specific Architecture

### Development Environment
```
Public Internet
    ↓
AKS Public API Server (443)
    ↓
VNet (10.240.0.0/16)
├── AKS Subnet (10.240.0.0/24)
│   ├── System Node Pool (1-2 nodes)
│   └── User Node Pool (auto-scaling 0-5)
└── ACR (Public Access)
```

### Staging Environment
```
VNet (10.241.0.0/16)
├── AKS Subnet (10.241.0.0/24)
│   ├── System Node Pool (1-3 nodes)
│   ├── User Node Pool (auto-scaling 1-10)
│   └── Private API Server
├── Bastion Subnet (10.241.1.0/24)
│   └── Azure Bastion Host
├── ACR Private Endpoint (10.241.2.0/24)
└── Private DNS Zones
    ├── privatelink.{region}.azmk8s.io
    └── privatelink.azurecr.io
```

### Production Environment
```
VNet (10.242.0.0/16)
├── AKS Subnet (10.242.0.0/24)
│   ├── System Node Pool (3-5 nodes)
│   ├── User Node Pool (auto-scaling 3-20)
│   └── Private API Server
├── Bastion Subnet (10.242.1.0/24)
│   └── Azure Bastion Host
├── ACR Private Endpoint (10.242.2.0/24)
├── Jump Box Subnet (10.242.3.0/24)
│   └── Management VM
└── Private DNS Zones
    ├── privatelink.{region}.azmk8s.io
    └── privatelink.azurecr.io
```

## Infrastructure Components by Environment

### Common Components (All Environments)
- **Resource Groups**: Environment-specific resource containers
- **Managed Identities**: Cluster and kubelet identities
- **VNet**: Environment-specific virtual networks
- **AKS Cluster**: Kubernetes cluster with appropriate access level
- **Log Analytics**: Monitoring and logging workspace
- **Key Vault**: Secrets and certificate management

### Development-Specific Components
- **Public AKS API Server**: Direct access for developers
- **Public ACR**: Simplified image push/pull operations
- **Basic NSGs**: Minimal network security rules
- **Cost-optimized sizing**: Smaller node pools and instances

### Staging/Production-Specific Components
- **Private AKS API Server**: Enhanced security through Private Link
- **Private ACR**: Container registry with VNet integration
- **Azure Bastion**: Secure shell access to cluster nodes
- **Private DNS Zones**: Internal name resolution
- **Enhanced NSGs**: Comprehensive network security rules
- **Production-grade sizing**: Appropriate node pools and instances

## Security Configuration Matrix

| Component | Development | Staging | Production |
|-----------|-------------|---------|------------|
| AKS API Server | Public | Private | Private |
| Container Registry | Public | Private | Private |
| Network Access | Internet | VNet + Bastion | VNet + Bastion + Jump Box |
| Node Pool Size | 1-5 nodes | 1-10 nodes | 3-20 nodes |
| Monitoring | Basic | Enhanced | Full |
| Backup Strategy | None | Basic | Full |
| Disaster Recovery | None | Regional | Multi-regional |

## Terraform Module Structure
```
infra/tf/
├── modules/                    # Reusable infrastructure modules
│   ├── aks/
│   │   ├── main.tf            # AKS cluster resources
│   │   ├── variables.tf       # Input variables
│   │   └── outputs.tf         # Output values
│   ├── networking/
│   │   ├── main.tf            # VNet, subnets, NSGs
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acr/
│   │   ├── main.tf            # Container registry
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf            # Log Analytics, monitoring
│       ├── variables.tf
│       └── outputs.tf
└── environments/               # Environment-specific deployments
    ├── dev/
    │   ├── main.tf            # Module calls for dev
    │   ├── variables.tf       # Dev-specific variables
    │   ├── terraform.tfvars   # Dev variable values
    │   ├── backend.tf         # Dev backend configuration
    │   └── outputs.tf         # Dev-specific outputs
    ├── staging/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   ├── backend.tf
    │   └── outputs.tf
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        ├── backend.tf
        └── outputs.tf
```

## Architectural Decision: Separate Environment Folders

### Why Separate Folders Over Single Folder + Workspaces

This prompt uses the **separate environment folders** approach rather than Terraform workspaces for several critical reasons:

#### ✅ **State Isolation & Safety**
```bash
# Each environment has completely isolated state
environments/dev/     → Uses dev state backend
environments/staging/ → Uses staging state backend  
environments/prod/    → Uses prod state backend

# No risk of accidentally affecting wrong environment
cd environments/dev && terraform apply    # Only touches dev resources
cd environments/prod && terraform apply  # Only touches prod resources
```

#### ✅ **Blast Radius Control**
- Terraform errors are contained to single environment
- No risk of destroying production while working on development
- Failed state operations don't affect other environments
- Easier rollback and recovery per environment

#### ✅ **Environment-Specific Backend Configurations**
```hcl
# environments/dev/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "staksdevtfstate"
    container_name       = "terraform-state"
    key                  = "dev.tfstate"
  }
}

# environments/prod/backend.tf  
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod"
    storage_account_name = "staksprodtfstate"
    container_name       = "terraform-state"
    key                  = "prod.tfstate"
  }
}
```

#### ✅ **Team Access Control**
- Production folders can have restricted access
- Developers can have full access to dev environment only
- CI/CD pipelines can use environment-specific service principals
- Easier to implement least-privilege access

#### ✅ **CI/CD Pipeline Simplicity**
```yaml
# Simple environment-specific pipeline triggers
trigger:
  paths:
    include:
    - infra/tf/environments/dev/*    # Only triggers dev pipeline
    - infra/tf/modules/*             # Triggers all environments
```

#### ❌ **Problems with Single Folder + Workspaces**
- **Shared state backend**: All environments in same storage account
- **Workspace confusion**: Easy to `terraform apply` to wrong workspace
- **Complex CI/CD**: Need workspace switching logic in pipelines
- **Provider limitations**: Difficult to use different Azure subscriptions
- **Human error prone**: `terraform workspace select prod` before operations

### Implementation Best Practices

#### **Module Design Principles**
```hcl
# modules/aks/main.tf - Environment-agnostic module
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.environment}-aks-${var.instance}"
  private_cluster_enabled = var.enable_private_cluster
  
  # All configuration driven by variables
  api_server_access_profile {
    authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  }
}

# environments/dev/main.tf - Environment-specific configuration
module "aks" {
  source = "../../modules/aks"
  
  environment             = "dev"
  instance               = "001"
  enable_private_cluster = false      # Dev-specific: public access
  aks_api_server_authorized_ip_ranges = ["0.0.0.0/0"]
}

# environments/prod/main.tf - Different configuration, same module
module "aks" {
  source = "../../modules/aks"
  
  environment             = "prod" 
  instance               = "001"
  enable_private_cluster = true       # Prod-specific: private access
  aks_api_server_authorized_ip_ranges = []
}
```

#### **Variable Management Strategy**
```hcl
# environments/dev/variables.tf - Environment-specific variable definitions
variable "enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = false  # Dev default: public for easy access
}

# environments/prod/variables.tf - Different defaults for prod
variable "enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = true   # Prod default: private for security
}
```

#### **Backend Configuration Management**
```bash
# Separate backend configs prevent cross-environment mistakes
backend-configs/
├── dev.conf
├── staging.conf
└── prod.conf

# Initialize with specific backend
terraform init -backend-config=../../../backend-configs/dev.conf
```

This architectural approach ensures maximum safety, scalability, and maintainability for multi-environment infrastructure management.

## Module Design Patterns

### Conditional Resource Creation
```hcl
# Use count for environment-specific resources
resource "azurerm_private_endpoint" "acr" {
  count               = var.acr_public_network_access_enabled ? 0 : 1
  name                = "${var.environment}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.acr_pe_subnet_id

  private_service_connection {
    name                           = "${var.environment}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

# Use dynamic blocks for optional configurations
dynamic "network_rule_set" {
  for_each = var.acr_public_network_access_enabled ? [] : [1]
  content {
    default_action = "Deny"
  }
}
```

### Variable-Driven Security
```hcl
# Environment-specific security configurations
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.environment}-aks"
  private_cluster_enabled = var.enable_private_cluster
  
  # Public access only for dev
  api_server_access_profile {
    authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  }
  
  # Conditional node pool sizing
  default_node_pool {
    node_count          = var.system_node_count
    vm_size             = var.system_vm_size
    enable_auto_scaling = true
    min_count           = var.system_min_count
    max_count           = var.system_max_count
  }
}
```

### Environment-Specific Module Calls
```hcl
# Development environment - public access
module "aks" {
  source = "../../modules/aks"
  
  environment                         = "dev"
  enable_private_cluster             = false  # Public for dev
  aks_api_server_authorized_ip_ranges = ["0.0.0.0/0"]  # Open access
  system_vm_size                     = "Standard_B2ms"  # Cost-optimized
}

# Production environment - private access
module "aks" {
  source = "../../modules/aks"
  
  environment                         = "prod"
  enable_private_cluster             = true   # Private for prod
  aks_api_server_authorized_ip_ranges = []    # No public access
  system_vm_size                     = "Standard_D4s_v3"  # Production-grade
}
```

## Environment-Specific Variables

### Development Environment Variables
```hcl
environment = "dev"
aks_api_server_authorized_ip_ranges = ["0.0.0.0/0"]  # Public access
acr_public_network_access_enabled = true
enable_private_cluster = false
node_pool_min_count = 1
node_pool_max_count = 5
vm_size = "Standard_B2ms"  # Cost-optimized
```

### Staging Environment Variables
```hcl
environment = "staging"
aks_api_server_authorized_ip_ranges = []  # Private only
acr_public_network_access_enabled = false
enable_private_cluster = true
enable_private_dns_zone = true
node_pool_min_count = 1
node_pool_max_count = 10
vm_size = "Standard_D2s_v3"
```

### Production Environment Variables
```hcl
environment = "prod"
aks_api_server_authorized_ip_ranges = []  # Private only
acr_public_network_access_enabled = false
enable_private_cluster = true
enable_private_dns_zone = true
node_pool_min_count = 3
node_pool_max_count = 20
vm_size = "Standard_D4s_v3"
enable_backup = true
enable_disaster_recovery = true
```

## Access Patterns

### Development Access
```bash
# Direct kubectl access
kubectl get nodes
kubectl get pods -A

# Direct ACR push/pull
az acr login --name myregistry
docker push myregistry.azurecr.io/myapp:latest
```

### Staging/Production Access
```bash
# Via Bastion host
az network bastion ssh --name mybastion --resource-group myrg --target-resource-id /subscriptions/.../virtualMachines/jumpbox

# From jump box
kubectl get nodes
kubectl get pods -A

# ACR access through private endpoint
docker push myregistry.azurecr.io/myapp:latest
```

## CI/CD Integration Considerations

### Infrastructure Readiness for CI/CD Platforms
The infrastructure modules should be designed to work with either Azure DevOps or GitHub Actions:

#### Azure DevOps Considerations
- Service connections for Azure authentication
- Variable groups for environment-specific configurations  
- Pipeline templates for consistent deployments
- Approval gates for production deployments

#### GitHub Actions Considerations
- OIDC authentication with Azure
- Environment secrets and variables
- Reusable workflows for deployment consistency
- Environment protection rules

### CI/CD Integration Points
```hcl
# Output values needed for CI/CD integration
output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  value = azurerm_kubernetes_cluster.main.resource_group_name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}
```

### Environment-Specific Deployment Patterns
- **Development**: Automated deployment on code changes
- **Staging**: Automated deployment with post-deployment testing
- **Production**: Manual approval with automated deployment after approval

**Note**: This prompt focuses on infrastructure creation. CI/CD pipeline implementation should be done separately based on your chosen platform (Azure DevOps or GitHub Actions).

## Common Configuration Areas
- Environment-specific Kubernetes versions and upgrade policies
- Node pool sizing based on environment requirements
- Network policies appropriate for security level
- Ingress controllers with environment-specific configurations
- Certificate management (dev vs. production certificates)
- Monitoring and alerting levels by environment
- RBAC policies matching environment access patterns

## Typical Issues by Environment

### Development Issues
- Cost optimization vs. functionality balance
- Public endpoint security concerns
- Resource quotas and limitations
- Developer access management

### Staging/Production Issues
- Private endpoint connectivity problems
- Bastion host access and configuration
- Private DNS resolution issues
- Network security group rule conflicts
- ACR authentication through private endpoints
- Monitoring in restricted network environments

## Common Implementation Pitfalls

### Module Dependencies
- **Issue**: Circular dependencies between modules
- **Solution**: Use data sources for existing resources, careful output management
```hcl
# Use data source instead of direct reference
data "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  resource_group_name = var.resource_group_name
}
```

### Environment Variable Management  
- **Issue**: Hardcoded values instead of environment-specific variables
- **Solution**: Use terraform.tfvars files per environment
```hcl
# dev.tfvars
environment = "dev"
aks_api_server_authorized_ip_ranges = ["0.0.0.0/0"]
acr_public_network_access_enabled = true

# prod.tfvars  
environment = "prod"
aks_api_server_authorized_ip_ranges = []
acr_public_network_access_enabled = false
```

### State Management
- **Issue**: Shared state files causing conflicts
- **Solution**: Separate backend configurations per environment
```hcl
# backend-dev.conf
resource_group_name  = "rg-terraform-state-dev"
storage_account_name = "staksdevtfstate"
container_name       = "terraform-state"
key                  = "dev.tfstate"
```

### Private Cluster Access
- **Issue**: Inability to access private clusters after deployment
- **Solution**: Deploy bastion/jump box as part of initial deployment
```bash
# Deploy network infrastructure first
terraform apply -target=module.networking

# Then deploy cluster with bastion
terraform apply
```

## Deployment Scripts

### Multi-Environment Deployment Script
```bash
#!/bin/bash

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <dev|staging|prod>"
    exit 1
fi

echo "Deploying $ENVIRONMENT environment..."

cd "infra/tf/environments/$ENVIRONMENT"

# Initialize Terraform with environment-specific backend
terraform init -backend-config="../../../backend-$ENVIRONMENT.conf"

# Plan deployment
terraform plan -var-file="$ENVIRONMENT.tfvars" -out="$ENVIRONMENT.tfplan"

# Apply (with approval for prod)
if [ "$ENVIRONMENT" = "prod" ]; then
    echo "Production deployment requires manual approval"
    read -p "Continue with production deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply "$ENVIRONMENT.tfplan"
    fi
else
    terraform apply "$ENVIRONMENT.tfplan"
fi

# Get cluster credentials if deployment succeeded
if [ $? -eq 0 ]; then
    echo "Getting cluster credentials..."
    az aks get-credentials --resource-group "$ENVIRONMENT-aks-rg" --name "$ENVIRONMENT-aks"
fi
```

### Environment Validation Script
```bash
#!/bin/bash

ENVIRONMENT=$1

echo "Validating $ENVIRONMENT environment..."

# Test cluster connectivity
kubectl cluster-info

# Test ACR connectivity
ACR_NAME="${ENVIRONMENT}acr$(terraform output -raw acr_suffix)"
az acr check-health --name "$ACR_NAME"

# Test private endpoint resolution (for staging/prod)
if [ "$ENVIRONMENT" != "dev" ]; then
    nslookup "$ACR_NAME.azurecr.io"
    nslookup "${ENVIRONMENT}-aks.privatelink.${AZURE_REGION}.azmk8s.io"
fi

echo "$ENVIRONMENT environment validation complete"
```

## Expected Outcomes
- **Terraform modules**: Flexible modules supporting all environments
- **Environment configurations**: Specific variable files for each environment
- **Access documentation**: Clear procedures for each environment
- **Security guidelines**: Environment-appropriate security measures
- **Troubleshooting guides**: Environment-specific issue resolution
- **Infrastructure outputs**: Values needed for CI/CD platform integration
- **Deployment scripts**: Manual deployment capabilities for testing

## Additional Context
- Using Terraform with environment-specific state files
- Infrastructure designed for integration with Azure DevOps or GitHub Actions
- Helm charts with environment-specific values
- Azure CLI and kubectl with environment-specific configurations
- Following Azure Well-Architected Framework with environment considerations
- Cost optimization strategies for development environments
- Security hardening for staging and production environments
- Manual deployment scripts for testing and emergency scenarios
