# 🚀 GitHub Actions for AKS Terraform Deployment

Complete CI/CD solution for deploying AKS private cluster infrastructure using GitHub Actions and Terraform with **Federated Identity (OIDC)** authentication.

## 🏗️ Quick Start

### 1. Setup Authentication (2 minutes)
```bash
# Login to Azure
az login

# Run federated identity setup
./.github/setup-federated-identity.sh
```

### 2. Deploy Infrastructure (5 minutes)
1. Go to **Actions** tab in GitHub
2. Run **"Setup Terraform Backend"** workflow
3. Run **"Terraform Plan & Apply"** workflow

## 🔐 Authentication (Federated Identity)

This repository uses **User-Assigned Managed Identity** with **Federated Credentials** for secure, modern authentication.

### ✅ Benefits
- **No secrets to manage** - OIDC tokens are automatically rotated
- **Enhanced security** - Scoped to specific repository and branches
- **Zero secret sprawl** - No long-lived credentials
- **Microsoft recommended** - 2025 best practices

### 🎯 What Gets Created
- **Resource Group**: `rg-github-actions-identity`
- **Managed Identity**: `github-actions-terraform-aks`
- **Role Assignment**: Contributor on subscription
- **Federated Credentials**: For main, PR, and environment deployments
- **GitHub Secrets**: Only 3 needed (no client secret!)

### 🔑 Required GitHub Secrets

| Secret Name | Description | Purpose |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Managed Identity Client ID | OIDC authentication |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | Target subscription |
| `AZURE_TENANT_ID` | Azure Tenant ID | Azure AD tenant |

### �️ Manual Setup (If Needed)

If the automated script doesn't work:

```bash
# 1. Create managed identity
az identity create --name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity" \
  --location "Central US"

# 2. Assign role
az role assignment create \
  --assignee-object-id $(az identity show --name "github-actions-terraform-aks" \
    --resource-group "rg-github-actions-identity" --query principalId -o tsv) \
  --role "Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)"

# 3. Create federated credentials for each scenario
az identity federated-credential create \
  --name "github-main-branch" \
  --identity-name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:YOUR_OWNER/YOUR_REPO:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

# 4. Add secrets to GitHub
gh secret set AZURE_CLIENT_ID --body "$(az identity show --name github-actions-terraform-aks --resource-group rg-github-actions-identity --query clientId -o tsv)"
gh secret set AZURE_SUBSCRIPTION_ID --body "$(az account show --query id -o tsv)"
gh secret set AZURE_TENANT_ID --body "$(az account show --query tenantId -o tsv)"
```

## 🚀 Usage Instructions

### Step 1: Setup Terraform Backend

1. Go to Actions tab in your GitHub repository
2. Select "🔧 Setup Terraform Backend" workflow
3. Click "Run workflow"
4. Choose environment (dev/staging/prod)
5. Click "Run workflow" button

This will:
- Create Azure storage resources for Terraform state
- Generate backend configuration
- Verify connectivity

### Step 2: Deploy Infrastructure

1. Go to Actions tab in your GitHub repository
2. Select "🚀 Terraform Plan & Apply" workflow
3. Click "Run workflow"
4. Choose:
   - **Environment**: dev/staging/prod
   - **Action**: plan/apply/destroy
   - **Auto approve**: true/false (use with caution)
5. Click "Run workflow" button

### Step 3: Review and Monitor

- **Plan results**: Check the workflow logs or PR comments
- **Apply results**: Monitor the deployment progress
- **State artifacts**: Download artifacts for troubleshooting

## 🏗️ Workflows

### 1. Backend Setup (`terraform-backend-setup.yml`)
Sets up Azure Storage backend for Terraform state:
- Creates resource group for Terraform state
- Creates storage account with security best practices
- Creates blob container for state files
- Verifies backend connectivity

### 2. Infrastructure Deployment (`terraform-deploy.yml`)
Plans and applies Terraform infrastructure:
- **Triggers**: Manual dispatch, Pull Requests
- **Actions**: plan, apply, destroy
- **Environments**: dev, staging, prod
- **Features**: PR comments, state artifacts, auto-approve option

## 🌍 GitHub Environments

Environments are automatically created with appropriate protection:

| Environment | Protection Rules | Purpose |
|-------------|------------------|---------|
| **dev** | None | Development deployments |
| **staging** | Wait timer | Pre-production testing |
| **prod** | Enhanced protection | Production deployments |

## 🔧 Usage

### First-Time Deployment
1. **Setup Backend**: Actions → "Setup Terraform Backend" → Run workflow
2. **Deploy Infrastructure**: Actions → "Terraform Plan & Apply" → Select "apply"

### Regular Updates
1. **Plan Changes**: Actions → "Terraform Plan & Apply" → Select "plan"
2. **Review Plan**: Check workflow logs or PR comments
3. **Apply Changes**: Actions → "Terraform Plan & Apply" → Select "apply"

### Pull Request Flow
1. Create PR with Terraform changes
2. Workflow automatically runs `terraform plan`
3. Review plan in PR comments
4. Merge PR to trigger apply (if configured)

## 🔐 Authentication (Federated Identity)

This repository uses **User-Assigned Managed Identity** with **Federated Credentials** for secure, modern authentication.

### ✅ Benefits
- **No secrets to manage** - OIDC tokens are automatically rotated
- **Enhanced security** - Scoped to specific repository and branches
- **Zero secret sprawl** - No long-lived credentials
- **Microsoft recommended** - 2025 best practices

### 🎯 What Gets Created
- **Resource Group**: `rg-github-actions-identity`
- **Managed Identity**: `github-actions-terraform-aks`
- **Role Assignment**: Contributor on subscription
- **Federated Credentials**: For main, PR, and environment deployments
- **GitHub Secrets**: Only 3 needed (no client secret!)

### 🔑 Required GitHub Secrets

| Secret Name | Description | Purpose |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Managed Identity Client ID | OIDC authentication |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | Target subscription |
| `AZURE_TENANT_ID` | Azure Tenant ID | Azure AD tenant |

### �️ Manual Setup (If Needed)

If the automated script doesn't work:

```bash
# 1. Create managed identity
az identity create --name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity" \
  --location "Central US"

# 2. Assign role
az role assignment create \
  --assignee-object-id $(az identity show --name "github-actions-terraform-aks" \
    --resource-group "rg-github-actions-identity" --query principalId -o tsv) \
  --role "Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)"

# 3. Create federated credentials for each scenario
az identity federated-credential create \
  --name "github-main-branch" \
  --identity-name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:YOUR_OWNER/YOUR_REPO:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

# 4. Add secrets to GitHub
gh secret set AZURE_CLIENT_ID --body "$(az identity show --name github-actions-terraform-aks --resource-group rg-github-actions-identity --query clientId -o tsv)"
gh secret set AZURE_SUBSCRIPTION_ID --body "$(az account show --query id -o tsv)"
gh secret set AZURE_TENANT_ID --body "$(az account show --query tenantId -o tsv)"
```

## 🚀 Usage Instructions

### Step 1: Setup Terraform Backend

1. Go to Actions tab in your GitHub repository
2. Select "🔧 Setup Terraform Backend" workflow
3. Click "Run workflow"
4. Choose environment (dev/staging/prod)
5. Click "Run workflow" button

This will:
- Create Azure storage resources for Terraform state
- Generate backend configuration
- Verify connectivity

### Step 2: Deploy Infrastructure

1. Go to Actions tab in your GitHub repository
2. Select "🚀 Terraform Plan & Apply" workflow
3. Click "Run workflow"
4. Choose:
   - **Environment**: dev/staging/prod
   - **Action**: plan/apply/destroy
   - **Auto approve**: true/false (use with caution)
5. Click "Run workflow" button

### Step 3: Review and Monitor

- **Plan results**: Check the workflow logs or PR comments
- **Apply results**: Monitor the deployment progress
- **State artifacts**: Download artifacts for troubleshooting

## 🏗️ Workflows

### 1. Backend Setup (`terraform-backend-setup.yml`)
Sets up Azure Storage backend for Terraform state:
- Creates resource group for Terraform state
- Creates storage account with security best practices
- Creates blob container for state files
- Verifies backend connectivity

### 2. Infrastructure Deployment (`terraform-deploy.yml`)
Plans and applies Terraform infrastructure:
- **Triggers**: Manual dispatch, Pull Requests
- **Actions**: plan, apply, destroy
- **Environments**: dev, staging, prod
- **Features**: PR comments, state artifacts, auto-approve option

## 🌍 GitHub Environments

Environments are automatically created with appropriate protection:

| Environment | Protection Rules | Purpose |
|-------------|------------------|---------|
| **dev** | None | Development deployments |
| **staging** | Wait timer | Pre-production testing |
| **prod** | Enhanced protection | Production deployments |

## 🔧 Usage

### First-Time Deployment
1. **Setup Backend**: Actions → "Setup Terraform Backend" → Run workflow
2. **Deploy Infrastructure**: Actions → "Terraform Plan & Apply" → Select "apply"

### Regular Updates
1. **Plan Changes**: Actions → "Terraform Plan & Apply" → Select "plan"
2. **Review Plan**: Check workflow logs or PR comments
3. **Apply Changes**: Actions → "Terraform Plan & Apply" → Select "apply"

### Pull Request Flow
1. Create PR with Terraform changes
2. Workflow automatically runs `terraform plan`
3. Review plan in PR comments
4. Merge PR to trigger apply (if configured)

## 🛡️ Security Best Practices

### Authentication Security
- ✅ Use federated identity (no long-lived secrets)
- ✅ Scope credentials to specific branches/environments
- ✅ Monitor Azure AD sign-in logs
- ✅ Regular access reviews

### Workflow Security
- ✅ Environment protection rules
- ✅ Manual approval for production
- ✅ Limited workflow permissions
- ✅ Audit logging enabled

### State Management
- ✅ Remote backend (Azure Storage)
- ✅ State locking enabled
- ✅ Encryption at rest
- ✅ Access logging

## 📁 Project Structure

```
.github/
├── workflows/
│   ├── terraform-backend-setup.yml    # Backend setup
│   └── terraform-deploy.yml           # Infrastructure deployment
├── setup-federated-identity.sh        # Authentication setup
├── setup-github-secrets.sh           # Secrets automation
└── README.md                          # This file

infra/tf/
├── backend.tf                        # Terraform backend config
├── main.tf                           # Main infrastructure
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── terraform.tfvars.example          # Example configuration
└── modules/                          # Terraform modules
    ├── aks/                          # AKS cluster module
    ├── networking/                   # VNet/subnet module
    ├── identity/                     # Identity module
    ├── monitoring/                   # Monitoring module
    └── registry/                     # Container registry module
```

## 🔍 Troubleshooting

### Authentication Issues
```bash
# Check GitHub secrets
gh secret list

# Verify managed identity
az identity show --name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity"

# Check federated credentials
az identity federated-credential list \
  --identity-name "github-actions-terraform-aks" \
  --resource-group "rg-github-actions-identity"
```

### Common Problems

**Authentication Failed:**
- Verify GitHub secrets are set correctly
- Check federated credential subjects match repository
- Ensure workflows run from correct branches/environments

**Backend Setup Failed:**
- Check storage account naming conflicts
- Verify permissions on subscription
- Review resource group existence

**Terraform Plan Failed:**
- Check `terraform.tfvars` configuration
- Verify resource naming conventions
- Review Azure quota limits

### Debug Steps
1. **Check workflow logs** for detailed execution info
2. **Download artifacts** for state files and plans
3. **Test locally** with Azure CLI and Terraform
4. **Verify permissions** in Azure portal

## 📋 Configuration

### Required Variables

Copy `infra/tf/terraform.tfvars.example` to `infra/tf/terraform.tfvars`:

```hcl
# Environment
environment = "dev"
location    = "Central US"

# Naming
resource_group_name = "rg-aks-dev-cus-001"
cluster_name       = "aks-cluster-dev-cus-001"
registry_name      = "craksdevcus001"

# AKS Settings
kubernetes_version = "1.29"
system_node_count  = 1
user_node_count    = 1

# Security
private_cluster_enabled = true
enable_azure_policy     = true
```

## 🎯 Best Practices

### Development Workflow
1. **Test locally** before committing
2. **Use PR workflow** for all changes
3. **Review plans** before applying
4. **Monitor costs** and resource usage

### State Management
- Always use remote backend
- Enable state locking
- Regular state backups
- Monitor state file access

### Security
- Regular credential rotation (automatic with federated identity)
- Least privilege access
- Environment separation
- Audit trail monitoring

## 🆘 Support

**Getting Help:**
1. Check [troubleshooting section](#-troubleshooting)
2. Review workflow logs and artifacts
3. Verify Azure permissions and quotas
4. Consult [Azure documentation](https://docs.microsoft.com/azure/)

**Useful Commands:**
```bash
# Test authentication
az account show

# Validate Terraform
terraform validate

# Check workflow status
gh run list

# View secrets
gh secret list
```

---

> **🔐 Security Note**: This setup uses federated identity with no long-lived secrets, following Microsoft's 2025 best practices for secure CI/CD authentication to Azure.
