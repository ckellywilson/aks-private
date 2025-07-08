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

#### Option B: GitHub Actions Deployment (automated)

1. **Trigger the plan workflow**:
   - Go to the Actions tab in your GitHub repository
   - Select "Terraform Plan" workflow
   - Click "Run workflow"
   - Choose the environment (dev, staging, prod)

2. **Review the plan**:
   - Check the workflow output for the Terraform plan
   - Verify the changes are as expected

3. **Apply the changes**:
   - If the plan looks good, run the "Terraform Apply" workflow
   - Choose the same environment
   - Monitor the deployment progress

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

## 🔄 CI/CD Workflows

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

### Common Issues

1. **Permission errors**: Ensure proper Azure RBAC roles and GitHub environment secrets
2. **Terraform state issues**: Check backend storage account configuration
3. **Network connectivity**: Verify private endpoint and DNS configuration
4. **AKS access**: Use jump VM or Azure Bastion for cluster access

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
