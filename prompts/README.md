# GitHub Copilot Prompts for AKS Private Cluster Project

This directory contains useful prompts for working with the private AKS cluster project using GitHub Copilot or other AI assistants. These prompts are designed to provide context and help with common tasks and troubleshooting.

## 🎯 **Getting Started: Orchestrated Deployment Guide**

This section provides step-by-step instructions for using the prompts to create a complete multi-environment AKS infrastructure deployment.

### **Phase 1: Terraform Backend Setup (Foundation)**

**Goal**: Create secure, isolated Terraform state management for each environment.

#### **Step 1.1: Enhanced Bootstrap Script Creation**
Use prompt: `deployment-bootstrap-enhancement.md`

**Purpose**: Create an enhanced bootstrap script that sets up secure Azure storage backends for Terraform state management.

**Key Actions**:
```bash
# Use the prompt to create enhanced bootstrap script
# Focus on these requirements:
- Multi-environment support (dev/staging/prod)
- Private endpoints for storage accounts
- VNet integration for secure access
- Managed identity configuration
- OIDC federation for GitHub Actions
```

**Expected Output**: Enhanced `scripts/bootstrap-terraform-backend.sh` with security features

#### **Step 1.2: Multi-Environment Backend Configuration**
Use prompt: `terraform-backend-multi-environment.md`

**Purpose**: Configure environment-specific storage backends with appropriate security controls.

**Key Actions**:
```bash
# Use the prompt to:
- Create environment-specific storage accounts
- Configure private endpoints for staging/prod
- Set up public access for dev (easier development)
- Generate backend configuration files
```

**Expected Output**: 
- `backend-configs/dev.conf` (public access)
- `backend-configs/staging.conf` (private endpoints)
- `backend-configs/prod.conf` (private endpoints)

#### **Step 1.3: Network Access Configuration**
Use prompt: `terraform-backend-network-access.md`

**Purpose**: Ensure proper network connectivity for Terraform operations.

**Key Actions**:
```bash
# Use the prompt to troubleshoot and configure:
- VNet integration for private backends
- GitHub Actions connectivity
- Network security group rules
- Private DNS resolution
```

**Expected Output**: Network configurations that allow Terraform operations from CI/CD

### **Phase 2: Multi-Environment AKS Infrastructure**

**Goal**: Deploy AKS clusters with environment-appropriate security configurations.

#### **Step 2.1: Infrastructure Module Creation**
Use prompt: `aks-cluster-multi-environment-deployment.md`

**Purpose**: Create comprehensive Terraform modules for multi-environment AKS deployment.

**Key Actions**:
```bash
# Use the prompt to create:
# 1. Foundation modules
mkdir -p infra/tf/modules/{networking,aks,acr,monitoring}

# 2. Environment-specific configurations
mkdir -p infra/tf/environments/{dev,staging,prod}

# 3. Module implementation following the prompt guidance:
- Networking module (VNets, subnets, NSGs)
- AKS module with conditional private/public access
- ACR module with conditional private endpoints
- Monitoring module with environment-specific configurations
```

**Expected Output**: Complete Terraform module structure with environment-specific logic

#### **Step 2.2: Development Environment Deployment**
Use prompt: `aks-cluster-multi-environment-deployment.md` (Phase 1 & 2 sections)

**Purpose**: Deploy and validate the development environment first (public access for easy testing).

**Key Actions**:
```bash
# Deploy development environment
cd infra/tf/environments/dev
terraform init -backend-config=../../../backend-configs/dev.conf
terraform plan -var-file=dev.tfvars
terraform apply

# Validate deployment
kubectl get nodes
az acr list --resource-group dev-aks-rg
```

**Expected Output**: 
- Working dev AKS cluster (public API server)
- Public ACR for easy development
- Direct kubectl access

#### **Step 2.3: Staging Environment Deployment**
Use prompt: `aks-cluster-multi-environment-deployment.md` (Private networking sections)

**Purpose**: Deploy staging with private networking to test production configurations.

**Key Actions**:
```bash
# Deploy staging environment with private configurations
cd infra/tf/environments/staging
terraform init -backend-config=../../../backend-configs/staging.conf
terraform plan -var-file=staging.tfvars
terraform apply

# Test private access via bastion
az network bastion ssh --name staging-bastion --resource-group staging-aks-rg
```

**Expected Output**:
- Private AKS cluster with bastion access
- Private ACR with VNet integration
- Validated private networking

#### **Step 2.4: Production Environment Deployment**
Use prompt: `aks-cluster-multi-environment-deployment.md` (Production sections)

**Purpose**: Deploy production with full security controls and monitoring.

**Key Actions**:
```bash
# Deploy production environment with maximum security
cd infra/tf/environments/prod
terraform init -backend-config=../../../backend-configs/prod.conf
terraform plan -var-file=prod.tfvars
# Manual approval required for prod
terraform apply

# Validate security configurations
```

**Expected Output**:
- Fully private production AKS cluster
- Enhanced security controls
- Comprehensive monitoring
- Backup and disaster recovery

### **Phase 3: Automation and Operations**

#### **Step 3.1: CI/CD Pipeline Setup**
Use prompt: `deployment-github-actions-pipelines.md`

**Purpose**: Create automated deployment pipelines for infrastructure.

**Key Actions**:
```bash
# Use the prompt to create:
- Environment-specific GitHub Actions workflows
- Approval gates for production deployments
- Integration with Terraform backends
- Security scanning and compliance checks
```

#### **Step 3.2: Application Management**
Use prompt: `deployment-application-management.md`

**Purpose**: Set up application deployment and management workflows.

**Expected Output**: Application deployment pipelines that work with the infrastructure

### **Phase 4: Security and Compliance**

#### **Step 4.1: Security Hardening**
Use prompt: `infrastructure-security-best-practices.md`

**Purpose**: Implement comprehensive security controls across all environments.

**Key Actions**:
- Azure Policy implementation
- Network security review
- Identity and access management
- Compliance validation

#### **Step 4.2: Troubleshooting Setup**
Use prompt: `troubleshooting-network-connectivity.md`

**Purpose**: Establish troubleshooting procedures and monitoring.

**Expected Output**: Comprehensive troubleshooting documentation and monitoring setup

## 📋 **Deployment Checklist**

### **Prerequisites** ✅
- [ ] Azure CLI installed and authenticated
- [ ] Terraform >= 1.0 installed
- [ ] GitHub CLI authenticated
- [ ] Azure subscription with Contributor permissions
- [ ] GitHub repository with appropriate permissions

### **Phase 1 Completion** ✅
- [ ] Enhanced bootstrap script created and tested
- [ ] Storage accounts created for all environments
- [ ] Backend configurations generated
- [ ] Network access validated for CI/CD

### **Phase 2 Completion** ✅
- [ ] Development environment deployed and validated
- [ ] Staging environment deployed with private networking
- [ ] Production environment deployed with full security
- [ ] All environments accessible and functional

### **Phase 3 Completion** ✅
- [ ] CI/CD pipelines configured and tested
- [ ] Application deployment workflows operational
- [ ] Security scanning integrated
- [ ] Approval gates configured for production

### **Phase 4 Completion** ✅
- [ ] Security controls implemented and validated
- [ ] Compliance requirements met
- [ ] Monitoring and alerting configured
- [ ] Troubleshooting procedures documented

## 📂 **Prompt Categories**

## 📂 **Prompt Categories**

### 📦 **Terraform Backend (`terraform-backend-*.md`)**
- **`terraform-backend-multi-environment.md`** - Multi-environment backend setup with private networks
- **`terraform-backend-network-access.md`** - Storage backend network configuration and troubleshooting
- **`deployment-bootstrap-enhancement.md`** - Enhanced bootstrap script with security features

### 🏗️ **AKS Cluster Management (`aks-cluster-*.md`)**
- **`aks-cluster-multi-environment-deployment.md`** - Complete multi-environment AKS deployment guide

### 🔧 **Infrastructure Management (`infrastructure-*.md`)**
- **`infrastructure-terraform-modules.md`** - Module development and organization
- **`infrastructure-security-best-practices.md`** - Comprehensive security implementation

### 🚀 **Deployment Automation (`deployment-*.md`)**
- **`deployment-github-actions-pipelines.md`** - GitHub Actions workflows and CI/CD
- **`deployment-application-management.md`** - Application deployment and management

### 🐛 **Troubleshooting (`troubleshooting-*.md`)**
- **`troubleshooting-network-connectivity.md`** - Network diagnostics and connectivity issues

## 🎯 **How to Use These Prompts**

### **Step-by-Step Approach**
1. **Start with Phase 1** (Terraform Backend) - Foundation must be solid
2. **Progress through Phase 2** (AKS Infrastructure) - Build incrementally
3. **Implement Phase 3** (Automation) - Add CI/CD capabilities
4. **Complete Phase 4** (Security) - Harden and monitor

### **Using Individual Prompts**
1. **Select the appropriate prompt** based on your current task
2. **Copy the prompt content** and modify it with your specific details
3. **Use with GitHub Copilot** in VS Code or your preferred AI assistant
4. **Follow the implementation patterns** provided in each prompt
5. **Iterate and refine** based on the responses you get

### **Best Practices**
- **Follow the sequence**: Backend → Infrastructure → Automation → Security
- **Test each phase**: Validate before moving to the next phase
- **Environment progression**: Dev → Staging → Production
- **Security first**: Apply security controls from the beginning
- **Document everything**: Keep track of configurations and decisions

## 🔗 **Quick Reference Links**

| Phase | Primary Prompts | Purpose |
|-------|----------------|---------|
| **1. Backend** | `deployment-bootstrap-enhancement.md`<br>`terraform-backend-multi-environment.md` | Secure state management |
| **2. Infrastructure** | `aks-cluster-multi-environment-deployment.md` | Multi-env AKS deployment |
| **3. Automation** | `deployment-github-actions-pipelines.md`<br>`deployment-application-management.md` | CI/CD and automation |
| **4. Security** | `infrastructure-security-best-practices.md`<br>`troubleshooting-network-connectivity.md` | Security and monitoring |

## 📚 **Additional Resources**

- **INDEX.md** - Complete prompt index with detailed descriptions
- **Architecture diagrams** - Included in individual prompt files
- **Code examples** - Implementation patterns in each prompt
- **Troubleshooting guides** - Common issues and solutions

## 🤝 **Contributing**

When you discover new useful prompts or improvements:
1. Create a new `.md` file with a descriptive name
2. Follow the existing format and structure
3. Include context, specific requirements, and expected outcomes
4. Test the prompt to ensure it provides helpful responses
5. Update this README.md with the new prompt information

## 📝 **Prompt Template**

```markdown
# Prompt Title

## Context
Brief description of the scenario and goals

## Task  
Specific task or problem to solve

## Implementation Details
Detailed requirements and specifications

## Expected Outcomes
What should be delivered or achieved
```

---

**💡 Pro Tip**: Start with the orchestrated deployment guide above for the best experience. The prompts are designed to work together in sequence for maximum effectiveness.

## Context
Brief description of the scenario or problem

## Task
Specific task or goal you want to accomplish

## Requirements
- Bullet points of specific requirements
- Technical constraints
- Expected outcomes

## Sample Input/Output
Example of what you're working with and what you expect

## Additional Context
Any relevant technical details, error messages, or constraints
```
