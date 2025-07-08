# Scripts Directory

Administrative scripts for AKS Private Cluster setup and management.

## 🔐 Security Notice

**These scripts require elevated permissions and should only be run by repository administrators.**

## Scripts

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
