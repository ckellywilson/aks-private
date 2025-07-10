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

### Phase 4: Ingress Configuration and Testing
1. Validate ingress-nginx controller deployment (deployed via Terraform)
2. Test ingress functionality and DNS resolution
3. Create sample applications for ingress testing
4. Configure SSL/TLS certificates for ingress (if using cert-manager)
5. Document ingress access patterns for each environment

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
- [ ] Ingress-nginx controller deployed via Terraform
- [ ] Ingress functionality validated using provided scripts
- [ ] SSL/TLS certificates configured for ingress
- [ ] DNS records pointing to ingress load balancer
- [ ] Ingress access tested from appropriate networks

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
│   ├── monitoring/
│   │   ├── main.tf            # Log Analytics, monitoring
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ingress/
│       ├── main.tf            # Ingress controller (Helm)
│       ├── variables.tf
│       ├── outputs.tf
│       └── values-templates/  # Helm values templates
│           ├── values-dev.yaml
│           ├── values-staging.yaml
│           └── values-prod.yaml
├── environments/               # Environment-specific deployments
│   ├── dev/
│   │   ├── main.tf            # Module calls for dev
│   │   ├── variables.tf       # Dev-specific variables
│   │   ├── terraform.tfvars   # Dev variable values
│   │   ├── providers.tf       # Dev provider configuration
│   │   └── outputs.tf         # Dev-specific outputs
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── providers.tf
│   │   └── outputs.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── providers.tf
│       └── outputs.tf
└── helm-values/                # Helm chart values files
    ├── ingress-nginx-values-dev.yaml
    ├── ingress-nginx-values-staging.yaml
    └── ingress-nginx-values-prod.yaml
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
# environments/dev/providers.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "staksdevtfstate"
    container_name       = "terraform-state"
    key                  = "dev.tfstate"
  }
}

# environments/prod/providers.tf  
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

## Post-Deployment Helm Configuration

### Ingress-Nginx Controller Deployment

The ingress-nginx controller is deployed automatically as part of the main Terraform infrastructure deployment, not as a separate post-deployment step. The controller is configured using environment-specific Helm values templates and integrated into the Terraform module structure.

#### Terraform Integration
The ingress-nginx controller is deployed using the dedicated `ingress` module located at `modules/ingress/`. This module:
- Creates the ingress-nginx namespace with proper labels
- Deploys ingress-nginx using Helm with environment-specific configurations
- Optionally deploys cert-manager for SSL certificate management
- Optionally deploys Azure Key Vault CSI driver for secret management

#### Environment-Specific Configuration
Each environment has tailored ingress-nginx settings defined in Terraform variables and applied through Helm values templates:

##### Development Environment Configuration
- **Replicas**: 1 (cost-optimized)
- **Resources**: Minimal (100m CPU, 90Mi memory)
- **Load Balancer**: Public (for easy access)
- **Monitoring**: Basic metrics enabled
- **SSL**: Optional cert-manager integration

##### Staging Environment Configuration  
- **Replicas**: 2 (basic high availability)
- **Resources**: Moderate (200m CPU, 180Mi memory)
- **Load Balancer**: Internal (private networking)
- **Monitoring**: Enhanced metrics and basic alerting
- **SSL**: cert-manager recommended

##### Production Environment Configuration
- **Replicas**: 3+ (high availability)
- **Resources**: Production-grade (500m CPU, 512Mi memory)
- **Load Balancer**: Internal (private networking)
- **Monitoring**: Comprehensive metrics and alerting
- **SSL**: cert-manager with production certificates

#### Deployment Process
When you run `terraform apply` in any environment, the ingress-nginx controller is deployed automatically:

```bash
# Deploy entire infrastructure including ingress-nginx
cd infra/tf/environments/dev
terraform init
terraform apply

# Verify ingress controller deployment
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

#### Validation and Testing
After Terraform deployment, use the provided validation scripts to ensure proper ingress functionality:

```bash
# Validate ingress-nginx deployment
./validation/validate-ingress.sh dev

# Create sample application for testing
./validation/create-sample-ingress.sh dev
```

#### Terraform Module Structure
The ingress module includes the following components:

```
modules/ingress/
├── main.tf                    # Main ingress-nginx deployment
├── variables.tf               # Input variables for configuration
├── outputs.tf                 # Outputs for downstream consumption
└── values-templates/          # Environment-specific Helm values
    ├── values-dev.yaml        # Development configuration
    ├── values-staging.yaml    # Staging configuration
    └── values-prod.yaml       # Production configuration
```

#### Configuration Variables
Key Terraform variables for ingress-nginx configuration:

- `ingress_replica_count`: Number of controller replicas
- `ingress_cpu_requests/limits`: CPU resource allocation
- `ingress_memory_requests/limits`: Memory resource allocation
- `enable_internal_load_balancer`: Use internal vs public load balancer
- `enable_metrics`: Enable Prometheus metrics collection
- `enable_cert_manager`: Deploy cert-manager for SSL certificates
- `enable_azure_key_vault_csi`: Deploy Azure Key Vault CSI driver

#### Environment-Specific Values Templates

###### Development Environment Values (`values-dev.yaml`)
```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
  replicaCount: 1
  resources:
    requests:
      cpu: 100m
      memory: 90Mi
    limits:
      cpu: 200m
      memory: 180Mi
  nodeSelector:
    kubernetes.io/os: linux
  tolerations: []
  affinity: {}

# Development-specific configurations
defaultBackend:
  enabled: true
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
    limits:
      cpu: 20m
      memory: 40Mi
```

###### Staging Environment Values (`values-staging.yaml`)
```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
      service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "aks-subnet"
  replicaCount: 2
  resources:
    requests:
      cpu: 200m
      memory: 180Mi
    limits:
      cpu: 500m
      memory: 360Mi
  nodeSelector:
    kubernetes.io/os: linux
  tolerations: []
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
          topologyKey: kubernetes.io/hostname

# Staging-specific configurations
defaultBackend:
  enabled: true
  resources:
    requests:
      cpu: 20m
      memory: 30Mi
    limits:
      cpu: 50m
      memory: 60Mi

# Enable metrics for monitoring
metrics:
  enabled: true
  service:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "10254"
```

###### Production Environment Values (`values-prod.yaml`)
```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
      service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "aks-subnet"
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
  nodeSelector:
    kubernetes.io/os: linux
  tolerations: []
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: ingress-nginx
        topologyKey: kubernetes.io/hostname
  
  # Production-grade configurations
  config:
    use-proxy-protocol: "true"
    compute-full-forwarded-for: "true"
    use-forwarded-headers: "true"
    log-format-escape-json: "true"
    log-format-upstream: '{"time": "$time_iso8601", "remote_addr": "$proxy_protocol_addr", "x_forwarded_for": "$proxy_add_x_forwarded_for", "request_id": "$req_id", "remote_user": "$remote_user", "bytes_sent": $bytes_sent, "request_time": $request_time, "status": $status, "vhost": "$host", "request_proto": "$server_protocol", "path": "$uri", "request_query": "$args", "request_length": $request_length, "duration": $request_time, "method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent"}'

# Production-specific configurations
defaultBackend:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 60Mi
    limits:
      cpu: 100m
      memory: 120Mi

# Enable comprehensive monitoring
metrics:
  enabled: true
  service:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "10254"
  prometheusRule:
    enabled: true
    rules:
      - alert: NGINXConfigFailed
        expr: count(nginx_ingress_controller_config_last_reload_successful == 0) > 0
        for: 1s
        labels:
          severity: critical
        annotations:
          description: bad ingress config - nginx config test failed
          summary: uninstall the latest ingress changes to allow config reloads to resume
      - alert: NGINXCertificateExpiry
        expr: (avg(nginx_ingress_controller_ssl_expire_time_seconds) by (host) - time()) < 604800
        for: 1s
        labels:
          severity: critical
        annotations:
          description: ssl certificate(s) will expire in less then a week
          summary: renew expiring certificates to avoid downtime
```

#### Terraform Deployment Examples

##### Deploy to Development Environment
```bash
cd infra/tf/environments/dev
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan

# Verify ingress deployment
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

##### Deploy to Staging Environment
```bash
cd infra/tf/environments/staging
terraform init
terraform plan -out=staging.tfplan
terraform apply staging.tfplan

# Verify private load balancer assignment
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

##### Deploy to Production Environment
```bash
cd infra/tf/environments/prod
terraform init
terraform plan -out=prod.tfplan
terraform apply prod.tfplan

# Verify high availability configuration
kubectl get pods -n ingress-nginx -o wide
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

#### Post-Deployment Validation

##### 1. Verify Terraform Deployment
```bash
# Check Terraform outputs
terraform output ingress_controller_ip
terraform output ingress_namespace
terraform output ingress_class

# Verify all resources are created
terraform state list | grep module.ingress
```

##### 2. Validate Kubernetes Resources
```bash
# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller service and load balancer
kubectl get services -n ingress-nginx

# Check ingress class configuration
kubectl get ingressclass

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

##### 3. Test Ingress Functionality
```bash
# Use validation script for comprehensive testing
./validation/validate-ingress.sh dev

# Create sample application for testing
./validation/create-sample-ingress.sh dev

# Test ingress connectivity
curl -H 'Host: dev.app.example.com' http://<EXTERNAL_IP>
```

##### 2. Get Load Balancer IP
```bash
# Get external IP (development) or internal IP (staging/prod)
kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

##### 3. Configure DNS Records
```bash
# Development: Point DNS to public IP
# Staging/Production: Point DNS to internal IP via private DNS zone

# Example DNS configuration
# dev.example.com    -> <public-ip>
# staging.example.com -> <internal-ip>
# prod.example.com   -> <internal-ip>
```

#### SSL/TLS Certificate Management

##### Option 1: cert-manager with Let's Encrypt (Development)
```bash
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

##### Option 2: Azure Key Vault Integration (Staging/Production)
```bash
# Install Azure Key Vault CSI driver
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm repo update

helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --version 1.4.0
```

#### Environment-Specific Ingress Examples

##### Development Ingress Example
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-app-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - dev.example.com
    secretName: dev-example-com-tls
  rules:
  - host: dev.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-app-service
            port:
              number: 80
```

##### Production Ingress Example
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-app-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: SAMEORIGIN";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
spec:
  tls:
  - hosts:
    - prod.example.com
    secretName: prod-example-com-tls
  rules:
  - host: prod.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-app-service
            port:
              number: 80
```

#### Terraform Integration for Ingress Configuration

##### Add Helm Provider to Terraform
```hcl
# providers.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}
```

##### Create Ingress Module
```hcl
# modules/ingress/main.tf
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    templatefile("${path.module}/values-${var.environment}.yaml", {
      environment = var.environment
      internal_lb = var.enable_internal_load_balancer
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}

# Output ingress controller service details
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  depends_on = [helm_release.ingress_nginx]
}
```

##### Module Variables
```hcl
# modules/ingress/variables.tf
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_internal_load_balancer" {
  description = "Enable internal load balancer for ingress controller"
  type        = bool
  default     = false
}

variable "ingress_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 1
}
```

##### Module Outputs
```hcl
# modules/ingress/outputs.tf
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
```

#### Post-Deployment Validation Scripts

##### Ingress Controller Health Check
```bash
#!/bin/bash
# validate-ingress.sh

ENVIRONMENT=$1
NAMESPACE="ingress-nginx"

echo "Validating ingress-nginx controller in $ENVIRONMENT environment..."

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "❌ Namespace $NAMESPACE does not exist"
    exit 1
fi

# Check if ingress controller pods are running
PODS_READY=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}')
if [[ $PODS_READY == *"False"* ]]; then
    echo "❌ Ingress controller pods are not ready"
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx
    exit 1
fi

# Check if service has external IP
EXTERNAL_IP=$(kubectl get service ingress-nginx-controller -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXTERNAL_IP" ]; then
    echo "❌ Ingress controller service does not have external IP"
    kubectl get service ingress-nginx-controller -n $NAMESPACE
    exit 1
fi

echo "✅ Ingress controller is healthy"
echo "📍 External IP: $EXTERNAL_IP"

# Test ingress controller health endpoint
if curl -s -f "http://$EXTERNAL_IP/healthz" > /dev/null; then
    echo "✅ Ingress controller health endpoint is responsive"
else
    echo "⚠️  Ingress controller health endpoint is not accessible"
fi

echo "Ingress controller validation complete for $ENVIRONMENT environment"
```

#### Deployment Automation Script with Ingress

```bash
#!/bin/bash
# deploy-with-ingress.sh

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <dev|staging|prod>"
    exit 1
fi

echo "Deploying $ENVIRONMENT environment with ingress controller..."

# Deploy infrastructure
cd "infra/tf/environments/$ENVIRONMENT"
terraform init -backend-config="../../../backend-$ENVIRONMENT.conf"
terraform plan -var-file="$ENVIRONMENT.tfvars" -out="$ENVIRONMENT.tfplan"
terraform apply "$ENVIRONMENT.tfplan"

# Get cluster credentials
if [ $? -eq 0 ]; then
    echo "Getting cluster credentials..."
    az aks get-credentials --resource-group "$ENVIRONMENT-aks-rg" --name "$ENVIRONMENT-aks" --overwrite-existing
    
    # Wait for cluster to be ready
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Deploy ingress controller
    echo "Deploying ingress controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Create ingress namespace
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ingress-nginx with environment-specific values
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --values "../../../helm-values/ingress-nginx-values-$ENVIRONMENT.yaml" \
      --version 4.8.3 \
      --wait \
      --timeout 300s
    
    # Validate ingress deployment
    echo "Validating ingress deployment..."
    sleep 30
    ./validate-ingress.sh $ENVIRONMENT
    
    echo "✅ $ENVIRONMENT environment deployment complete with ingress controller"
else
    echo "❌ Infrastructure deployment failed"
    exit 1
fi
```

#### Monitoring and Alerting for Ingress

##### Prometheus Monitoring Rules
```yaml
# ingress-monitoring-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ingress-nginx-monitoring
  namespace: ingress-nginx
spec:
  groups:
  - name: ingress-nginx
    rules:
    - alert: IngressNginxDown
      expr: up{job="ingress-nginx-controller-metrics"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Ingress Nginx is down"
        description: "Ingress Nginx has been down for more than 1 minute"
    
    - alert: IngressNginxHighErrorRate
      expr: rate(nginx_ingress_controller_requests{status=~"5.."}[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in Ingress Nginx"
        description: "Ingress Nginx error rate is above 10% for 2 minutes"
```

This comprehensive post-deployment configuration ensures that ingress-nginx is properly installed, configured, and monitored across all environments with appropriate security and performance settings.
