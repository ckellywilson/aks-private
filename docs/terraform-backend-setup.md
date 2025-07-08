# Terraform Backend Setup Guide

This guide walks you through setting up Terraform backend storage for the AKS Private Cluster project using Azure Storage with OIDC authentication.

## 🎯 Overview

The setup creates:
- **Managed Identity**: For OIDC authentication without long-lived secrets
- **Storage Accounts**: One per environment (dev, staging, prod) for state isolation
- **GitHub Integration**: Automated workflows for backend creation and management

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] **Azure CLI** installed and authenticated (`az login`)
- [ ] **GitHub CLI** installed and authenticated (`gh auth login`)
- [ ] **Repository admin permissions** on the GitHub repository
- [ ] **Subscription Contributor** permissions in Azure
- [ ] **GitHub environments** created (dev, staging, prod)

## 🚀 Setup Process

### Step 1: Setup GitHub Environments (One-time)

```bash
# From repository root
./scripts/setup-github-environments.sh
```

This creates the three GitHub environments with basic protection rules.

### Step 2: Setup Managed Identity (One-time)

```bash
# From repository root
./scripts/setup-terraform-backend-identity.sh
```

This script:
- ✅ Creates a user-assigned managed identity
- ✅ Assigns necessary Azure RBAC roles
- ✅ Sets up federated identity credentials for OIDC
- ✅ Creates GitHub repository and environment secrets
- ✅ Generates setup summary documentation

### Step 3: Test OIDC Authentication (Optional)

Use the GitHub Actions workflow to test authentication:

1. Go to **Actions** → **🧪 Test OIDC Authentication**
2. Run the workflow for each environment
3. Verify all tests pass

### Step 4: Create Backend Storage

Use the GitHub Actions workflow to create backend storage:

1. Go to **Actions** → **🏗️ Setup Terraform Backend Storage**
2. Run the workflow for each environment (dev, staging, prod)
3. Download the backend configuration artifacts

### Step 5: Update Backend Configuration

1. **Download artifacts** from the workflow runs
2. **Update `infra/tf/backend.tf`** with the generated configuration
3. **Run `terraform init`** to initialize the backend
4. **Run `terraform plan`** to verify setup

## 📁 Backend Configuration Examples

### Development Environment
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev-cus-001"
    storage_account_name = "staksdevcus001tfstate"
    container_name       = "terraform-state"
    key                  = "dev.tfstate"
  }
}
```

### Staging Environment
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-staging-cus-001"
    storage_account_name = "staksstaginkcus001tfstate"
    container_name       = "terraform-state"
    key                  = "staging.tfstate"
  }
}
```

### Production Environment
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod-cus-001"
    storage_account_name = "staksprodcus001tfstate"
    container_name       = "terraform-state"
    key                  = "prod.tfstate"
  }
}
```

## 🔐 Security Features

### OIDC Authentication
- ✅ **No long-lived secrets** - Uses federated identity
- ✅ **Token-based authentication** - Tokens expire automatically
- ✅ **Environment-specific** - Each environment has its own federated credential

### Storage Security
- ✅ **Encryption at rest** - All data encrypted with Microsoft-managed keys
- ✅ **HTTPS only** - All connections must use HTTPS
- ✅ **Public access disabled** - No anonymous access allowed
- ✅ **Shared key access disabled** - Only Azure AD authentication
- ✅ **Blob versioning** - State file versioning enabled
- ✅ **Soft delete** - Protection against accidental deletion

### Access Control
- ✅ **Managed identity** - Principle of least privilege
- ✅ **Role-based access** - Only necessary permissions granted
- ✅ **Environment isolation** - Each environment has separate resources
- ✅ **Audit logging** - All operations logged in Azure Activity Log

## 📊 Resource Naming Convention

| Resource Type | Naming Pattern | Example |
|---------------|----------------|---------|
| Resource Group | `rg-terraform-state-{env}-cus-001` | `rg-terraform-state-dev-cus-001` |
| Storage Account | `staks{env}cus001tfstate` | `staksdevcus001tfstate` |
| Container | `terraform-state` | `terraform-state` |
| State File | `{env}.tfstate` | `dev.tfstate` |

## 🚨 Troubleshooting

### Common Issues

#### 1. **Permission Denied**
```
Error: insufficient privileges to complete the operation
```
**Solution**: Ensure the managed identity has `Storage Account Contributor` role

#### 2. **Storage Account Name Conflict**
```
Error: The storage account name is already taken
```
**Solution**: Storage account names must be globally unique. The script uses a random suffix.

#### 3. **OIDC Authentication Failed**
```
Error: AADSTS70021: No matching federated identity record found
```
**Solution**: Verify federated identity credentials are correctly configured

#### 4. **Environment Not Found**
```
Error: Environment 'dev' not found
```
**Solution**: Run `./scripts/setup-github-environments.sh` first

### Debug Steps

1. **Check Azure CLI authentication**:
   ```bash
   az account show
   ```

2. **Verify GitHub CLI authentication**:
   ```bash
   gh auth status
   ```

3. **Check managed identity**:
   ```bash
   az identity show --name id-terraform-backend-cus-001 --resource-group rg-terraform-backend-identity-cus-001
   ```

4. **Verify federated credentials**:
   ```bash
   az identity federated-credential list --name id-terraform-backend-cus-001 --resource-group rg-terraform-backend-identity-cus-001
   ```

## 📚 Additional Resources

- [Azure Managed Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform AzureRM Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Azure Storage Security](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)

## 🔄 Maintenance

### Monthly Tasks
- [ ] Review Azure Activity Log for unusual activity
- [ ] Verify storage account access logs
- [ ] Check for Azure security recommendations

### Quarterly Tasks
- [ ] Review and rotate managed identity credentials (if needed)
- [ ] Audit federated identity credential configurations
- [ ] Test backup and recovery procedures

### Annual Tasks
- [ ] Review and update security policies
- [ ] Conduct security assessment
- [ ] Update documentation and procedures

---

**⚠️ Important**: This setup is for production use. All scripts follow security best practices and implement proper authentication mechanisms.
