# Multi-Environment Terraform Backend

This directory contains scripts, configurations, and automation for setting up a comprehensive multi-environment Terraform backend strategy with different security models for development vs staging/production environments.

## Architecture Overview

### Development Environment (Public Access)
- **Storage**: Azure Storage Account with controlled public access via GitHub Actions IP ranges
- **Runners**: Standard GitHub-hosted runners
- **Security**: Basic security with IP restrictions and managed identity authentication
- **Access**: Direct access to storage account through public internet with restricted IPs

### Staging/Production Environment (Private Access)
- **Storage**: Azure Storage Account with private access only
- **Network**: Private VNet with service endpoints and private endpoints
- **Runners**: Self-hosted runners in private container instances
- **Registry**: Private Azure Container Registry for runner images
- **Security**: Zero public access, private endpoints, enhanced monitoring

## Directory Structure

```
tf-backend/
├── bootstrap-terraform-backend.sh    # Multi-environment bootstrap script
├── validate-environment.sh           # Environment validation script
├── docker/                          # Container images for self-hosted runners
│   ├── Dockerfile                   # Secure Terraform runner image
│   └── entrypoint.sh               # Runner entrypoint with security checks
└── workflows/                       # GitHub Actions workflows
    ├── terraform-dev.yml           # Development environment deployment
    ├── terraform-stage-prod.yml    # Staging/production deployment
    ├── container-build-stage-prod.yml  # Container build workflow
    └── cleanup-resources.yml       # Resource cleanup automation
```

## Quick Start

### 1. Bootstrap Environment

```bash
# Development environment
./bootstrap-terraform-backend.sh dev -s YOUR_SUBSCRIPTION_ID

# Staging environment
./bootstrap-terraform-backend.sh staging -s YOUR_SUBSCRIPTION_ID

# Production environment
./bootstrap-terraform-backend.sh prod -s YOUR_SUBSCRIPTION_ID
```

### 2. Validate Environment

```bash
# Validate development environment
./validate-environment.sh dev -s YOUR_SUBSCRIPTION_ID

# Validate staging/production
./validate-environment.sh staging -s YOUR_SUBSCRIPTION_ID --verbose
```

### 3. Configure GitHub Actions

Set up the following secrets in your GitHub repository:

#### Required Secrets
- `AZURE_CLIENT_ID`: Azure AD Application (Client) ID
- `AZURE_TENANT_ID`: Azure AD Tenant ID  
- `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID
- `GH_PAT`: GitHub Personal Access Token for self-hosted runner registration

#### Required Variables
- `AKS_CLUSTER_NAME`: Name of your AKS cluster (if applicable)
- `RESOURCE_GROUP_NAME`: Resource group containing your infrastructure
- `ACR_NAME`: Azure Container Registry name (if applicable)

## Environment-Specific Configurations

### Development Environment

#### Storage Account Configuration
- **Name Pattern**: `staksdeveus001tfstate`
- **Access**: Controlled public access with GitHub Actions IP ranges
- **Replication**: LRS (Local Redundant Storage)
- **Features**: Basic blob storage with HTTPS-only access

#### Network Security
- **Default Action**: Deny
- **Allowed IPs**: GitHub Actions IP ranges
- **Authentication**: Azure AD and Managed Identity only

### Staging/Production Environment

#### Storage Account Configuration
- **Name Pattern**: `staksstageeus001tfstate` / `staksprodeus001tfstate`
- **Access**: Private access only via VNet
- **Replication**: ZRS (Zone Redundant Storage)
- **Features**: Advanced security, versioning, soft delete

#### Network Architecture
- **VNet**: `10.100.0.0/16`
- **Private Subnet**: `10.100.1.0/24` (self-hosted runners)
- **Private Endpoints Subnet**: `10.100.2.0/24`
- **Service Endpoints**: Storage, Container Registry

#### Container Registry
- **Name Pattern**: `acrterraformstageeus001` / `acrterraformprodeus001`
- **Access**: Private only via VNet
- **Images**: Custom Terraform runner images
- **Features**: Vulnerability scanning, content trust

## Security Features

### Development Environment Security
- ✅ IP-restricted access (GitHub Actions ranges only)
- ✅ HTTPS-only communication
- ✅ Managed identity authentication
- ✅ Disabled shared key access
- ✅ Disabled public blob access

### Staging/Production Security
- ✅ Zero public network access
- ✅ Private VNet with service endpoints
- ✅ Private endpoints for all services
- ✅ Container image vulnerability scanning
- ✅ Network security groups
- ✅ Advanced threat protection
- ✅ Comprehensive audit logging
- ✅ Immutable infrastructure patterns

## Monitoring and Observability

### Log Analytics Workspaces
Each environment has dedicated Log Analytics workspace:
- **Development**: `law-terraform-dev-eus-001`
- **Staging**: `law-terraform-staging-eus-001`
- **Production**: `law-terraform-prod-eus-001`

### Monitoring Features
- 📊 Storage account diagnostic logs
- 🔔 Security alerts for unauthorized access
- 📈 Performance metrics and capacity monitoring
- 🔍 Container instance monitoring
- 🛡️ Network security monitoring

## GitHub Actions Workflows

### Development Workflow (`terraform-dev.yml`)
- **Trigger**: Push/PR to `develop` branch
- **Runner**: GitHub-hosted (`ubuntu-latest`)
- **Features**:
  - Security scanning with Checkov
  - Terraform validate, plan, apply
  - PR comments with plan output
  - Post-deployment validation

### Staging/Production Workflow (`terraform-stage-prod.yml`)
- **Trigger**: Push to `main` branch or manual dispatch
- **Runner**: Self-hosted in private VNet
- **Features**:
  - Container instance deployment
  - Private network validation
  - Enhanced security checks
  - Automatic cleanup

### Container Build Workflow (`container-build-stage-prod.yml`)
- **Trigger**: Changes to Docker files or manual dispatch
- **Purpose**: Build and push runner images to private ACR
- **Features**:
  - Security scanning with Trivy
  - Multi-environment builds
  - Image vulnerability assessment

## Cost Optimization

### Environment-Specific Sizing
- **Development**: Basic SKUs, shorter retention
- **Staging**: Standard SKUs, medium retention
- **Production**: Premium SKUs, extended retention

### Automated Cleanup
- Orphaned container instances cleanup
- Old terraform plan artifacts removal
- Automatic resource deallocation

## Troubleshooting

### Common Issues

#### 1. Authentication Failures
```bash
# Check Azure CLI authentication
az account show

# Verify subscription access
az account list --output table
```

#### 2. Network Connectivity (Private Environments)
```bash
# Test private endpoint connectivity
az network private-endpoint list --resource-group rg-terraform-state-staging-eus-001

# Check VNet configuration
az network vnet show --name vnet-terraform-staging --resource-group rg-terraform-state-staging-eus-001
```

#### 3. Storage Access Issues
```bash
# Check storage account network rules
az storage account show --name staksstageeus001tfstate --query "networkRuleSet"

# Test storage connectivity
az storage container list --account-name staksstageeus001tfstate --auth-mode login
```

### Debug Mode

Enable verbose logging in scripts:
```bash
./bootstrap-terraform-backend.sh staging -s YOUR_SUBSCRIPTION_ID --dry-run
./validate-environment.sh staging -s YOUR_SUBSCRIPTION_ID --verbose
```

## Best Practices

### Infrastructure as Code
- ✅ Use consistent naming conventions
- ✅ Apply comprehensive tagging strategy
- ✅ Implement proper resource lifecycle management
- ✅ Use environment-specific configurations

### Security
- ✅ Follow principle of least privilege
- ✅ Enable audit logging for all operations
- ✅ Use private endpoints in production
- ✅ Regularly scan container images
- ✅ Implement network segmentation

### Operations
- ✅ Automate all deployments
- ✅ Implement proper backup strategies
- ✅ Monitor resource utilization
- ✅ Plan for disaster recovery

## Support and Maintenance

### Regular Tasks
1. **Weekly**: Review security scan results
2. **Monthly**: Update container images and tools
3. **Quarterly**: Review and optimize costs
4. **Annually**: Security and compliance audit

### Updates and Patches
- Monitor Terraform provider updates
- Keep container base images updated
- Update GitHub Actions versions
- Review and update IP allow lists

## Contributing

When making changes to this infrastructure:

1. Test in development environment first
2. Run security scans and validation
3. Update documentation as needed
4. Follow the established naming conventions
5. Ensure all secrets are properly managed

## Additional Resources

- [Azure Storage Security Guide](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Azure Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
