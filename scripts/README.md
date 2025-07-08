# Terraform Backend Bootstrap

This directory contains scripts and documentation for setting up the Azure storage backend for Terraform state management.

## Overview

The Terraform backend setup follows a **bootstrap approach** where the storage infrastructure is created once manually, and then GitHub Actions workflows handle only the Terraform plan/apply operations.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  BOOTSTRAP PHASE                           │
│  (One-time manual setup with privileged account)          │
├─────────────────────────────────────────────────────────────┤
│  • Create storage account for Terraform state             │
│  • Create managed identity for Terraform                  │
│  • Assign minimal permissions to managed identity         │
│  • Configure OIDC federation for GitHub Actions          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 AUTOMATION PHASE                           │
│     (GitHub Actions with limited permissions)             │
├─────────────────────────────────────────────────────────────┤
│  • terraform plan (validation workflow)                   │
│  • terraform apply (deployment workflow)                  │
│  • Uses pre-created backend and managed identity          │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

1. **Azure CLI installed** and logged in with an account that has:
   - `Owner` role on the subscription, OR
   - `Contributor` + `User Access Administrator` roles
2. **Appropriate permissions** to create resources and assign roles

### Bootstrap Process

1. **Run the bootstrap script:**
   ```bash
   cd scripts
   ./bootstrap-terraform-backend.sh
   ```

2. **Follow the interactive prompts:**
   - Confirm your Azure subscription
   - Select environments to set up (dev, staging, prod)
   - Choose Azure region
   - Optionally provide GitHub Actions service principal ID

3. **Review generated files:**
   - `infra/tf/environments/{env}/backend.tf` - Backend configuration
   - `terraform-backend-summary-{env}.md` - Complete setup summary

4. **Update GitHub Secrets:**
   Use the values from the summary documents to update your repository secrets:
   ```
   AZURE_CLIENT_ID = "managed-identity-client-id"
   AZURE_SUBSCRIPTION_ID = "subscription-id"
   AZURE_TENANT_ID = "tenant-id"
   ```

## What Gets Created

For each environment, the bootstrap script creates:

### Azure Resources
- **Resource Group**: `rg-terraform-state-{env}-cus-001`
- **Storage Account**: `staks{env}cus001tfstate`
- **Blob Container**: `terraform-state`
- **Managed Identity**: `id-terraform-{env}-cus-001`

### Security Configuration
- ✅ **Encryption at rest**: Enabled by default
- ✅ **Blob versioning**: Enabled for state file recovery
- ✅ **HTTPS only**: Enforced
- ✅ **Public blob access**: Disabled
- ✅ **Shared key access**: Disabled
- ✅ **Minimum TLS version**: 1.2

### Permissions
- **Managed Identity**: Storage Blob Data Contributor + Storage Account Contributor
- **GitHub Actions SP** (optional): Storage Blob Data Reader + Reader (resource group scope)

## File Structure

```
scripts/
├── bootstrap-terraform-backend.sh    # Main bootstrap script
├── assign-github-actions-permissions.sh  # Helper for GitHub Actions perms
└── README.md                         # This file

infra/tf/environments/
├── dev/
│   ├── backend.tf                   # Backend configuration
│   ├── backend-config.txt           # Key-value config
│   └── terraform.tfvars             # Environment variables
├── staging/
└── prod/

# Generated summary documents
terraform-backend-summary-dev.md
terraform-backend-summary-staging.md
terraform-backend-summary-prod.md
```

## Scripts

### `bootstrap-terraform-backend.sh`
**Purpose**: Complete one-time setup of Terraform backend infrastructure

**Features**:
- Interactive configuration
- Multi-environment support
- Permission verification
- Comprehensive error handling
- Detailed documentation generation

**Usage**:
```bash
./bootstrap-terraform-backend.sh
```

### `assign-github-actions-permissions.sh`
**Purpose**: Assign additional permissions to GitHub Actions service principal

**Usage**:
```bash
# Interactive mode
./assign-github-actions-permissions.sh

# With environment variable
GITHUB_ACTIONS_CLIENT_ID="sp-client-id" ./assign-github-actions-permissions.sh
```

## Troubleshooting

### Common Issues

#### 1. Insufficient Permissions
**Error**: `AuthorizationFailed` when creating role assignments

**Solution**: Ensure your account has `Owner` or `User Access Administrator` role:
```bash
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

#### 2. Storage Account Name Conflicts
**Error**: Storage account name already taken

**Solution**: Storage account names are globally unique. The bootstrap script uses a consistent naming pattern, but you may need to modify the name if there's a conflict.

#### 3. Managed Identity Not Found
**Error**: Cannot find managed identity in GitHub Actions

**Solution**: Verify the `AZURE_CLIENT_ID` secret matches the managed identity client ID from the summary document.

### Verification Commands

**Check backend resources**:
```bash
# List resource group contents
az resource list --resource-group rg-terraform-state-dev-cus-001 --output table

# Verify storage account
az storage account show --name staksdevcus001tfstate --resource-group rg-terraform-state-dev-cus-001

# Check managed identity
az identity show --name id-terraform-dev-cus-001 --resource-group rg-terraform-state-dev-cus-001
```

**Test Terraform backend**:
```bash
cd infra/tf
terraform init
terraform plan
```

## Security Considerations

### Principle of Least Privilege
- **Bootstrap account**: Needs high privileges (Owner/User Access Admin) but only used once
- **Managed Identity**: Has only storage permissions needed for Terraform
- **GitHub Actions**: Has minimal read permissions for validation

### Separation of Concerns
- **Infrastructure setup** (bootstrap): Manual process with full control
- **Application deployment** (workflows): Automated with limited permissions

### Audit Trail
- All resource creation is logged in Azure Activity Log
- Generated summary documents provide complete audit trail
- Version-controlled configuration files

## Migration from Workflow-Based Setup

If you previously used the GitHub Actions workflow for backend setup:

1. **Remove the old workflow**:
   ```bash
   rm .github/workflows/setup-terraform-backend.yml
   ```

2. **Run the bootstrap script** to create resources properly

3. **Update your GitHub secrets** with the new managed identity details

4. **Test the new setup** with terraform init

## Best Practices

### Environment Management
- Use consistent naming patterns across environments
- Separate resource groups per environment
- Use different managed identities per environment

### State File Security
- Enable blob versioning for recovery
- Monitor access with Azure Monitor
- Regular backup verification

### Access Control
- Regular review of role assignments
- Use managed identities instead of service principals where possible
- Minimal permissions for automation accounts

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the generated summary documents
3. Verify your Azure permissions
4. Check Azure Activity Logs for detailed error information

---

**Note**: This bootstrap approach follows Azure and HashiCorp best practices for Terraform backend management in production environments.

### `check-prerequisites.sh`

**Purpose**: Validate that all prerequisites are met before running setup scripts

**Requirements**:
- Azure CLI installed and authenticated
- GitHub CLI installed and authenticated
- Repository access (admin permissions for full setup)

**Usage**:
```bash
# From repository root
./scripts/check-prerequisites.sh
```

**Security Notes**:
- ✅ **Safe to run** - Read-only checks, no modifications
- 🔍 **Validation only** - Identifies issues before they cause setup failures
- 🚀 **Run first** - Always run before executing setup scripts

**What it does**:
1. Checks required tools are installed (`az`, `gh`, `jq`, `curl`)
2. Validates Azure CLI and GitHub CLI authentication
3. Verifies repository access and admin permissions
4. Confirms Azure subscription permissions
5. Checks file permissions and workflow existence

### `setup-github-environments.sh`

**Purpose**: One-time setup of GitHub environments (dev, staging, prod)

**Requirements**:
- Repository admin permissions
- GitHub CLI (`gh`) installed and authenticated
- Run manually by administrator

**Usage**:
```bash
# From repository root
./scripts/setup-github-environments.sh
```

**Security Notes**:
- ⚠️ **ADMIN ONLY** - Requires repository admin permissions
- 🚫 **NOT for CI/CD** - Should never be run in automated workflows
- 🔒 **One-time use** - Only needed during initial repository setup
- 📋 **Audit trail** - Check git history to see when environments were created

**What it does**:
1. Verifies admin permissions
2. Creates three GitHub environments: `dev`, `staging`, `prod`
3. Configures basic protection rules
4. Provides next steps for manual secret configuration

### `setup-terraform-backend-identity.sh`

**Purpose**: Setup managed identity for Terraform backend storage with OIDC authentication

**Requirements**:
- Azure CLI installed and authenticated
- GitHub CLI installed and authenticated
- Subscription Contributor permissions
- Repository admin permissions (for setting secrets)

**Usage**:
```bash
# From repository root
./scripts/setup-terraform-backend-identity.sh
```

**Security Notes**:
- ⚠️ **ADMIN ONLY** - Requires subscription-level permissions
- 🔐 **OIDC Authentication** - No long-lived secrets
- 🔒 **Principle of least privilege** - Only necessary permissions
- 📋 **Audit trail** - All actions logged in Azure Activity Log

**What it does**:
1. Creates user-assigned managed identity
2. Assigns required roles (Storage Account Contributor, Contributor)
3. Sets up federated identity credentials for GitHub Actions
4. Creates GitHub repository and environment secrets
5. Generates setup summary documentation

### `deploy-addons.sh`

**Purpose**: Deploy AKS add-ons (nginx-ingress, cert-manager) to the cluster

**Requirements**:
- Access to AKS cluster (via jump VM/Bastion)
- kubectl configured
- Helm installed

**Usage**:
```bash
# From jump VM or Bastion session
./scripts/deploy-addons.sh
```

**Security Notes**:
- 🌐 **Network access required** - Must be run from within VNet
- 🔧 **Cluster access required** - kubectl must be configured
- 📋 **Post-deployment step** - Run after Terraform deployment

**What it does**:
1. Verifies cluster access
2. Deploys nginx-ingress controller via Helm
3. Deploys cert-manager via Helm
4. Configures cluster issuer for Let's Encrypt

## 🏗️ Setup Sequence

For new repository setup, run scripts in this order:

1. **`check-prerequisites.sh`** - Validate prerequisites before setup
2. **`setup-github-environments.sh`** - Create GitHub environments
3. **`setup-terraform-backend-identity.sh`** - Setup managed identity and OIDC
4. **Use GitHub Actions workflow** - `setup-terraform-backend.yml` to create backend storage
5. **Deploy infrastructure** - Use Terraform to deploy AKS cluster
6. **`deploy-addons.sh`** - Deploy cluster add-ons

## 🔐 Security Model

### Authentication Flow
1. **GitHub Actions** authenticates with Azure using OIDC
2. **Managed Identity** provides necessary permissions
3. **No long-lived secrets** stored in GitHub
4. **Environment-specific** federated credentials

### Permission Boundaries
- **Setup scripts**: Require admin permissions (one-time use)
- **Workflows**: Use managed identity with limited permissions
- **Environments**: Isolated secrets and configurations

### Audit and Compliance
- **Azure Activity Log**: All resource operations logged
- **GitHub Actions**: Workflow execution history
- **Terraform State**: Change tracking and history

## 🚨 Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure proper Azure RBAC roles
2. **OIDC Authentication Failed**: Check federated credential configuration
3. **Environment Not Found**: Run setup-github-environments.sh first
4. **Storage Account Conflict**: Names must be globally unique

### Getting Help

1. Check script output for specific error messages
2. Verify Azure CLI and GitHub CLI authentication
3. Review Azure Activity Log for detailed error information
4. Check GitHub Actions workflow logs for deployment issues

## 📚 Additional Resources

- [Workflows Documentation](.github/workflows/README.md) - Detailed GitHub Actions workflow usage
- [Azure Managed Identity Documentation](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform AzureRM Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)

---

**Security First**: All scripts follow the principle of least privilege and implement proper authentication mechanisms.
