# AKS Private Cluster

A production-ready, private Azure Kubernetes Service (AKS) cluster deployment with GitHub Actions CI/CD automation and Terraform infrastructure as code.

## 🏗️ Architecture

This repository deploys:

- **Private AKS Cluster** with system and user node pools
- **Azure Container Registry** with private endpoint
- **Log Analytics Workspace** for monitoring and observability
- **User-assigned Managed Identities** for secure cluster operations
- **Azure Bastion Host** for secure administrative access
- **Jump VM** for kubectl operations and cluster management
- **Private DNS Zones** for secure networking
- **Network Security Groups** with appropriate security rules

## 📁 Repository Structure

```
├── .github/workflows/          # GitHub Actions workflows
│   ├── terraform-plan.yml      # Terraform plan workflow
│   ├── terraform-apply.yml     # Terraform apply workflow
│   ├── test-oidc.yml           # OIDC authentication test
│   ├── verify-environments.yml # Environment verification workflow
│   └── dependency-check.yml    # Dependency monitoring workflow
├── docs/                       # Additional documentation
├── infra/tf/                   # Terraform infrastructure code
│   ├── modules/                # Reusable Terraform modules
│   ├── main.tf                 # Main infrastructure configuration
│   ├variables.tf               # Input variables
│   ├── outputs.tf              # Output values
│   ├── Makefile                # Local deployment automation
│   └── README.md               # Detailed Terraform documentation
├── scripts/                    # Administrative scripts
│   ├── bootstrap-terraform-backend.sh  # Bootstrap Terraform backend
│   ├── setup-github-environments.sh   # One-time environment setup
│   ├── deploy-addons.sh        # AKS add-ons deployment
│   └── README.md               # Scripts documentation
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **Terraform** >= 1.7.0 installed
- **kubectl** installed for cluster access
- **GitHub CLI** (`gh`) for environment management
- **Repository admin permissions** for initial setup

### 2. Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd aks-private
   ```

2. **Set up GitHub environments** (admin only):
   ```bash
   ./scripts/setup-github-environments.sh
   ```

3. **Configure secrets** in GitHub environments (`dev`, `staging`, `prod`):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

4. **Set environment variables** for each environment:
   ```
   TF_VAR_environment = "dev" | "staging" | "prod"
   TF_VAR_location = "Central US"
   TF_VAR_instance = "001"
   ```

### 3. Set up Terraform Backend

Run the bootstrap script to create the Terraform backend storage:
```bash
./scripts/bootstrap-terraform-backend.sh
```

This will create:
- Azure Storage Account for Terraform state
- Managed Identity for secure access
- OIDC federation for GitHub Actions
- Environment-specific backend configurations

### 4. Deploy Infrastructure

You can deploy the infrastructure using either method:

#### Option A: Local Deployment (using Makefile)

1. **Navigate to the Terraform directory**:
   ```bash
   cd infra/tf
   ```

2. **Deploy using Makefile**:
   ```bash
   # Deploy to dev environment
   make deploy-dev
   
   # Deploy to staging environment
   make deploy-staging
   
   # Deploy to production environment
   make deploy-prod
   ```

The Makefile handles:
- Environment configuration
- Terraform initialization
- Backend configuration
- Plan and apply operations

#### Option B: GitHub Actions Deployment (recommended)

**Step 1: Plan the Infrastructure**
1. Navigate to your GitHub repository
2. Go to the **Actions** tab
3. Select **"Terraform Plan"** workflow from the left sidebar
4. Click **"Run workflow"** button
5. Select the target environment:
   - `dev` for development
   - `staging` for pre-production
   - `prod` for production
6. Click **"Run workflow"** to start the planning process

**Step 2: Review the Plan**
1. Wait for the workflow to complete (usually 2-5 minutes)
2. Click on the workflow run to view details
3. Expand the **"Terraform Plan"** step to review:
   - Resources to be created/modified/destroyed
   - Configuration changes
   - Potential issues or warnings
4. Verify the plan matches your expectations

**Step 3: Apply the Changes**
1. If the plan looks correct, go back to the **Actions** tab
2. Select **"Terraform Apply"** workflow
3. Click **"Run workflow"** button
4. Select the **same environment** you used for planning
5. Click **"Run workflow"** to start the deployment

**Step 4: Monitor Deployment**
1. Watch the workflow progress in real-time
2. Monitor the **"Terraform Apply"** step for:
   - Resource creation progress
   - Any errors or warnings
   - Completion status
3. Deployment typically takes 10-15 minutes for AKS cluster creation

**Step 5: Post-Deployment Verification**
1. Check the workflow output for cluster details
2. Verify resources in the Azure Portal
3. Test connectivity using the jump VM or Azure Bastion

**Environment-Specific Considerations**:
- **Dev**: Immediate deployment, no approvals required
- **Staging**: Requires reviewer approval before deployment
- **Prod**: Requires reviewer approval + 5-minute wait timer

#### Benefits of Each Approach

**Local Deployment (Makefile)**:
- ✅ Direct control over deployment
- ✅ Easy for development and testing
- ✅ Immediate feedback and troubleshooting
- ✅ No dependency on GitHub Actions

**GitHub Actions Deployment**:
- ✅ Consistent deployment process
- ✅ Audit trail and deployment history
- ✅ Code review integration
- ✅ Environment protection rules
- ✅ Automated validation and testing

For more detailed instructions, see [`infra/tf/README.md`](infra/tf/README.md).

## 🔐 Security & Best Practices

### Authentication Strategy
- **OIDC/Federated Identity** for GitHub Actions (no long-lived secrets)
- **Managed Identities** for Azure resource authentication
- **Private endpoints** for secure communication
- **Network segmentation** with appropriate security groups

### Environment Isolation
- **Separate environments**: `dev`, `staging`, `prod`
- **Environment-specific secrets** and variables
- **Protection rules** on staging/prod environments
- **Centralized logging** and monitoring

### Permission Model
- **Least privilege** access for workflows
- **Admin scripts** require elevated permissions (one-time use)
- **Separation of concerns** between setup and deployment

## 🌍 Environment Configuration

### Development (`dev`)
- **Purpose**: Development and testing
- **Protection**: None (immediate deployment)
- **Location**: Central US

### Staging (`staging`)
- **Purpose**: Pre-production testing
- **Protection**: Reviewer approval required
- **Location**: Central US

### Production (`prod`)
- **Purpose**: Live workloads
- **Protection**: Reviewer approval + 5-minute wait timer
- **Location**: Central US

## 📊 Resource Naming Convention

All resources follow Azure best practices:

**Format**: `<type>-<workload>-<env>-<region>-<instance>`

**Examples**:
- Resource Group: `rg-aks-dev-cus-001`
- AKS Cluster: `aks-cluster-dev-cus-001`
- Container Registry: `craksdevcus001`
- VNet: `vnet-aks-dev-cus-001`
- Storage Account: `staksdevcus001tfstate`

## � Deploying with GitHub Actions

### Prerequisites for GitHub Actions Deployment

Before using GitHub Actions, ensure the following setup is complete:

1. **Azure Resources**:
   - Terraform backend storage account created (via bootstrap script)
   - Managed identity with appropriate permissions
   - OIDC federation configured for GitHub

2. **GitHub Secrets** (configured in environment settings):
   ```
   AZURE_CLIENT_ID=<managed-identity-client-id>
   AZURE_TENANT_ID=<azure-tenant-id>
   AZURE_SUBSCRIPTION_ID=<azure-subscription-id>
   ```

3. **GitHub Environment Variables**:
   ```
   TF_VAR_environment=dev|staging|prod
   TF_VAR_location=Central US
   TF_VAR_instance=001
   ```

### Deployment Workflow

#### 1. Plan Infrastructure Changes
```bash
# Via GitHub UI:
Actions → Terraform Plan → Run workflow → Select environment
```

**What happens**:
- Authenticates to Azure using OIDC
- Initializes Terraform with remote backend
- Generates and displays infrastructure plan
- Shows resources to be created/modified/destroyed

#### 2. Apply Infrastructure Changes
```bash
# Via GitHub UI:
Actions → Terraform Apply → Run workflow → Select same environment
```

**What happens**:
- Authenticates to Azure using OIDC
- Applies the planned infrastructure changes
- Creates AKS cluster and supporting resources
- Outputs cluster connection information

### Environment Protection Rules

| Environment | Protection Rules | Use Case |
|-------------|-----------------|----------|
| **dev** | None | Development and testing |
| **staging** | Reviewer approval | Pre-production validation |
| **prod** | Reviewer approval + 5min wait | Production deployments |

### Monitoring Deployments

**Real-time Monitoring**:
- GitHub Actions provides live logs during deployment
- Monitor resource creation progress
- View any errors or warnings immediately

**Post-Deployment Verification**:
```bash
# Check cluster status
az aks show --resource-group rg-aks-dev-cus-001 --name aks-cluster-dev-cus-001

# Get cluster credentials
az aks get-credentials --resource-group rg-aks-dev-cus-001 --name aks-cluster-dev-cus-001

# Verify cluster nodes
kubectl get nodes
```

## �🔄 CI/CD Workflows

### Current Workflows
- **🔍 Terraform Plan**: Validates and plans infrastructure changes
- **🚀 Terraform Apply**: Applies infrastructure changes
- **🔐 Test OIDC**: Validates OIDC authentication setup
- **✅ Verify GitHub Environments**: Validates environment configuration
- **🔎 Dependency Check**: Monitors for security vulnerabilities

### Security Features
- **Manual triggers only** (no automatic execution)
- **Minimal permissions** (`contents: read`)
- **Environment-based secrets** and variables
- **OIDC authentication** (no long-lived secrets)
- **Audit trail** through GitHub Actions logs

## 🛠️ Administrative Scripts

Located in [`scripts/`](scripts/) directory:

- **`bootstrap-terraform-backend.sh`**: One-time setup of Terraform backend storage (admin only)
- **`setup-github-environments.sh`**: One-time environment setup (admin only)
- **`deploy-addons.sh`**: Deploy AKS add-ons (nginx-ingress, cert-manager)

⚠️ **Security Note**: Admin scripts require elevated permissions and should only be run manually by repository administrators.

**Setup Sequence**: Run `bootstrap-terraform-backend.sh` before any deployment to create the required storage infrastructure.

## 📚 Documentation

- [`infra/tf/README.md`](infra/tf/README.md): Detailed Terraform configuration and deployment guide
- [`scripts/README.md`](scripts/README.md): Administrative scripts documentation
- [`docs/README.md`](docs/README.md): Additional project documentation

## 🆘 Troubleshooting

## 🆘 Troubleshooting

### GitHub Actions Issues

**Authentication Failures**:
```bash
# Symptoms: "Failed to authenticate with Azure"
# Solutions:
1. Verify AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID secrets
2. Check OIDC federation configuration in Azure
3. Ensure managed identity has proper permissions
```

**Terraform Backend Issues**:
```bash
# Symptoms: "Failed to initialize backend"
# Solutions:
1. Verify storage account exists: staksdevcus001tfstate
2. Check container exists: terraform-state
3. Verify managed identity has Storage Blob Data Contributor role
```

**Plan/Apply Failures**:
```bash
# Symptoms: "Terraform plan/apply failed"
# Solutions:
1. Check Azure resource quotas and limits
2. Verify resource naming doesn't conflict
3. Review Terraform state for inconsistencies
4. Check Azure RBAC permissions for managed identity
```

**Environment Protection Issues**:
```bash
# Symptoms: "Deployment blocked by environment protection"
# Solutions:
1. Add required reviewers to environment protection settings
2. Wait for approval before proceeding
3. Check protection rule configuration in repository settings
```

### Common Issues

1. **Permission errors**: Ensure proper Azure RBAC roles and GitHub environment secrets
2. **Terraform state issues**: Check backend storage account configuration
3. **Network connectivity**: Verify private endpoint and DNS configuration
4. **AKS access**: Use jump VM or Azure Bastion for cluster access

### Quick Reference

**GitHub Actions Deployment Commands**:
```bash
# Plan infrastructure for dev environment
GitHub → Actions → Terraform Plan → Select "dev" → Run workflow

# Apply infrastructure for dev environment  
GitHub → Actions → Terraform Apply → Select "dev" → Run workflow

# Check workflow status
GitHub → Actions → [Workflow Name] → View run details
```

**Alternative: GitHub CLI**:
```bash
# Trigger plan workflow
gh workflow run terraform-plan.yml -f environment=dev

# Trigger apply workflow
gh workflow run terraform-apply.yml -f environment=dev

# Check workflow status
gh run list --workflow=terraform-plan.yml
```

### Getting Help

1. Check the detailed documentation in each directory
2. Review GitHub Actions workflow logs for deployment issues
3. Verify Azure resource configuration in the Azure Portal
4. Check Terraform state and plan output for infrastructure drift

## 🎯 Status

1. ✅ Repository structure and documentation organized
2. ✅ Security model implemented with least privilege
3. ✅ Environment management configured
4. ✅ Terraform backend setup (bootstrap script)
5. ✅ Infrastructure deployment workflows (both local and GitHub Actions)
6. ✅ OIDC authentication and security hardening
7. ⏳ **TODO**: Add monitoring and alerting configuration
8. ⏳ **TODO**: Implement automated testing and validation

---

**Note**: This repository follows infrastructure as code best practices with a focus on security, automation, and maintainability.
