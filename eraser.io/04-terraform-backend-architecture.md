# Terraform Backend Infrastructure Architecture

## Eraser.io Prompt

**Context**: Generate an Azure architecture diagram showing the Terraform backend infrastructure for managing multi-environment AKS deployments, including state management, CI/CD integration, and security controls for Infrastructure as Code operations.

## Architecture Overview

Create a comprehensive diagram showing the Terraform backend infrastructure that supports the entire multi-environment AKS deployment with:

### Core Infrastructure-as-Code Components
- **Azure Storage Account** for Terraform state file management
- **Azure Key Vault** for storing sensitive Terraform variables and secrets
- **Azure Container Instance** or **Azure Container Apps** for running Terraform operations
- **GitHub Actions** integration for CI/CD pipeline automation
- **Azure Resource Manager** for resource provisioning and management

### Multi-Environment State Management
- **Separate storage containers** for each environment (dev, staging, production)
- **State file isolation** and locking mechanisms
- **Backend configuration** management per environment
- **State backup and recovery** procedures

## Detailed Backend Components

### Terraform State Storage Infrastructure
**Azure Storage Account Configuration**:
- **Account Name**: `tfstate[uniqueid]sa` (globally unique)
- **SKU**: Standard_ZRS for zone-redundant storage
- **Access Tier**: Hot for frequent Terraform operations
- **Security**: Private endpoints for staging/production access
- **Versioning**: Enabled for state file recovery
- **Soft Delete**: Enabled with 30-day retention

**Storage Containers Structure**:
```
tfstate-dev/
├── networking/terraform.tfstate
├── aks/terraform.tfstate
├── monitoring/terraform.tfstate
└── ingress/terraform.tfstate

tfstate-staging/
├── networking/terraform.tfstate
├── aks/terraform.tfstate
├── monitoring/terraform.tfstate
└── ingress/terraform.tfstate

tfstate-prod/
├── networking/terraform.tfstate
├── aks/terraform.tfstate
├── monitoring/terraform.tfstate
└── ingress/terraform.tfstate
```

**State Locking with Azure Blob Lease**:
- Automatic state locking during Terraform operations
- Prevents concurrent modifications
- Lock timeout and recovery mechanisms
- Integration with CI/CD pipeline retry logic

### Azure Key Vault for Secrets Management
**Key Vault Configuration**:
- **Name**: `tfbackend-[env]-kv` per environment
- **SKU**: Premium with HSM for production
- **Access Policies**: Terraform service principal access
- **Private Endpoints**: For staging and production
- **Soft Delete**: Enabled with purge protection

**Stored Secrets Structure**:
```
Secrets:
├── terraform-client-id
├── terraform-client-secret
├── terraform-subscription-id
├── terraform-tenant-id
├── aks-admin-username
├── aks-admin-password
└── acr-admin-credentials

Certificates:
├── wildcard-ssl-cert
├── application-gateway-cert
└── ingress-tls-cert

Keys:
├── storage-encryption-key
├── aks-disk-encryption-key
└── backup-encryption-key
```

### CI/CD Integration Infrastructure
**GitHub Actions Runner Infrastructure**:
- **Self-hosted runners** on Azure Container Instances for security
- **Managed identity** authentication to Azure services
- **Network isolation** for production deployments
- **Artifact storage** for Terraform plans and outputs

**Container-based Terraform Execution**:
- **Custom Docker image** with Terraform, Azure CLI, and kubectl
- **Multi-stage builds** for security and optimization
- **Version pinning** for consistency across environments
- **Security scanning** integrated into image build process

## Environment-Specific Backend Configuration

### Development Environment Backend
**Security Model**: Simplified for developer productivity
- **Access**: Public storage account with IP restrictions
- **Authentication**: Service principal with contributor role
- **State isolation**: Separate container, shared storage account
- **Backup**: Basic blob versioning

**Configuration Example**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfbackend-dev-rg"
    storage_account_name = "tfstatedevsaUNIQUEID"
    container_name       = "tfstate-dev"
    key                  = "aks/terraform.tfstate"
    use_azuread_auth    = true
    use_oidc            = true
  }
}
```

### Staging Environment Backend
**Security Model**: Production-like with private access
- **Access**: Private endpoints and network restrictions
- **Authentication**: Managed identity with least privilege
- **State isolation**: Dedicated storage account per environment
- **Backup**: Geo-redundant storage with cross-region backup

**Configuration Example**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfbackend-staging-rg"
    storage_account_name = "tfstatestagingsaUNIQUEID"
    container_name       = "tfstate-staging"
    key                  = "aks/terraform.tfstate"
    use_azuread_auth    = true
    use_oidc            = true
  }
}
```

### Production Environment Backend
**Security Model**: Maximum security with strict controls
- **Access**: Private endpoints only, no public access
- **Authentication**: Federated identity with GitHub OIDC
- **State isolation**: Completely isolated infrastructure
- **Backup**: Multi-region replication with point-in-time recovery

**Configuration Example**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfbackend-prod-rg"
    storage_account_name = "tfstateprodsaUNIQUEID"
    container_name       = "tfstate-prod"
    key                  = "aks/terraform.tfstate"
    use_azuread_auth    = true
    use_oidc            = true
  }
}
```

## CI/CD Pipeline Integration

### GitHub Actions Workflow Architecture
**Terraform Workflow Components**:
- **Plan Phase**: Terraform plan with output to PR comments
- **Apply Phase**: Terraform apply with approval gates
- **Destroy Phase**: Controlled resource cleanup
- **Drift Detection**: Scheduled runs to detect configuration drift

**Environment Promotion Pipeline**:
```
Development → Staging → Production
     ↓           ↓          ↓
 Auto-deploy  Manual     Executive
             approval    approval
```

**Security Integration**:
- **GitHub OIDC** for passwordless authentication
- **Azure Policy** compliance checking during plan
- **Security scanning** of Terraform configurations
- **Cost estimation** and budget alerts

### Container Runtime Environment
**Terraform Runner Container**:
- **Base Image**: Ubuntu 22.04 LTS minimal
- **Terraform Version**: 1.6.0+ (pinned version)
- **Azure CLI**: Latest stable version
- **kubectl**: Version matching AKS supported versions
- **Security Tools**: Checkov, TFSec, Terrascan

**Runtime Security**:
- **Non-root user** execution
- **Read-only root filesystem**
- **Secrets mounted** as volumes
- **Network policies** for outbound restrictions

## State Management and Recovery

### Backup Strategy
**Automated Backups**:
- **Storage account backup** using Azure Backup
- **Cross-region replication** for disaster recovery
- **Version history** maintained for rollback capability
- **Backup testing** and recovery procedures

**State Recovery Procedures**:
1. **State corruption detection** through checksum validation
2. **Automatic rollback** to last known good state
3. **Manual recovery** procedures for complex scenarios
4. **Import procedures** for orphaned resources

### Monitoring and Alerting
**Terraform Operations Monitoring**:
- **Azure Monitor** for storage account metrics
- **Log Analytics** for Terraform operation logs
- **Application Insights** for CI/CD pipeline monitoring
- **Custom alerts** for state lock timeouts and failures

**Key Metrics**:
- State file modification frequency
- Lock duration and timeout incidents
- Backend authentication failures
- Storage account access patterns

## Visual Guidelines

### Layout Structure
- **Top section**: GitHub repository and CI/CD workflows
- **Middle section**: Terraform backend infrastructure per environment
- **Bottom section**: Target Azure resources being managed
- **Side panels**: Security and monitoring components

### Component Visualization
- **Storage accounts**: Cylinder icons with environment labels
- **Key Vaults**: Vault icons with key symbols
- **Containers**: Box icons representing isolation boundaries
- **Workflows**: Pipeline arrows showing deployment flow
- **State files**: Document icons with lock symbols

### Security Indicators
- **OIDC connections**: Secure connection symbols
- **Private endpoints**: Lock icons with network lines
- **Access policies**: Shield icons with user representations
- **Encryption**: Key icons on storage and transit paths

### Color Coding
- **Blue**: Storage and state management infrastructure
- **Green**: CI/CD and automation components
- **Red**: Security services and access controls
- **Purple**: Monitoring and observability
- **Orange**: Key Vault and secrets management

## Specific Requirements

1. **Show state isolation** between environments clearly
2. **Illustrate security boundaries** and access controls
3. **Display CI/CD integration** with GitHub Actions
4. **Highlight backup and recovery** mechanisms
5. **Include monitoring touchpoints** for operations
6. **Show network connectivity** patterns for different environments

## Expected Output

A comprehensive Terraform backend architecture diagram that clearly demonstrates:
- Multi-environment state management strategy
- Security controls and access patterns for each environment
- CI/CD pipeline integration with infrastructure automation
- Backup, recovery, and business continuity procedures
- Monitoring and operational visibility into infrastructure operations
- Network topology and connectivity requirements

This diagram should serve as the definitive reference for Terraform backend implementation and be suitable for DevOps reviews and compliance audits.
