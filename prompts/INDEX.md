# Prompt Index - Quick Reference

This index provides a quick reference to all available prompts organized by category and use case.

## 🚀 Quick Start Prompts

| Prompt | Use Case | Key Topics |
|--------|----------|------------|
| `terraform-backend-network-access.md` | Storage backend issues | VNet integration, 403 errors, network rules |
| `terraform-backend-multi-environment.md` | Multi-env backend setup | Dev/Stage/Prod, ACR, private networks |
| `troubleshooting-network-connectivity.md` | Network problems | Connectivity issues, DNS, diagnostics |
| `aks-cluster-multi-environment-deployment.md` | Multi-env AKS setup | Dev/Staging/Prod, public/private access |

## 📂 All Prompts by Category

### 🔧 Terraform Backend
- **`terraform-backend-network-access.md`**
  - Storage account network configuration
  - VNet integration for backend access
  - GitHub Actions authentication issues
  - Security and compliance controls

- **`terraform-backend-multi-environment.md`**
  - Multi-environment deployment strategy (dev/stage/prod)
  - Azure Container Registry with private access
  - Self-hosted GitHub Actions runners in VNet
  - Environment-specific security models
  - Container build and deployment workflows

### 🏗️ Infrastructure Management  
- **`infrastructure-terraform-modules.md`**
  - Module development and organization
  - Best practices and testing
  - Version management and documentation
  - Reusable component design

- **`infrastructure-security-best-practices.md`**
  - Comprehensive security implementation
  - Compliance frameworks and controls
  - Monitoring and incident response
  - Risk assessment and mitigation

### ☸️ AKS Cluster Management
- **`aks-cluster-multi-environment-deployment.md`**
  - Multi-environment AKS cluster deployment (Dev/Staging/Prod)
  - Environment-specific security configurations
  - Public vs private access patterns
  - Integration with Azure services

### 🚀 Deployment and Automation
- **`deployment-github-actions-pipelines.md`**
  - CI/CD pipeline configuration
  - Authentication and VNet integration
  - Workflow optimization and security
  - Multi-environment deployment

- **`deployment-bootstrap-enhancement.md`**
  - Bootstrap script improvements
  - Security and network integration
  - Automation and validation
  - Error handling and recovery

- **`deployment-application-management.md`**
  - Application deployment strategies
  - Container builds and Helm charts
  - Operational monitoring and scaling
  - GitOps and deployment patterns

### 🐛 Troubleshooting
- **`troubleshooting-network-connectivity.md`**
  - Network connectivity diagnostics
  - Common issues and resolutions
  - Azure-specific troubleshooting
  - Kubernetes networking problems

## 🎯 Use Case Matrix

| I want to... | Use this prompt |
|--------------|-----------------|
| Fix storage backend 403 errors | `terraform-backend-network-access.md` |
| Set up multi-environment backend with ACR | `terraform-backend-multi-environment.md` |
| Deploy multi-environment AKS clusters | `aks-cluster-multi-environment-deployment.md` |
| Set up GitHub Actions for private resources | `deployment-github-actions-pipelines.md` |
| Create reusable Terraform modules | `infrastructure-terraform-modules.md` |
| Implement security best practices | `infrastructure-security-best-practices.md` |
| Troubleshoot network connectivity | `troubleshooting-network-connectivity.md` |
| Enhance bootstrap script | `deployment-bootstrap-enhancement.md` |
| Deploy applications to AKS | `deployment-application-management.md` |

## 🏷️ Tag Reference

### By Technology
- **Azure**: All prompts
- **Terraform**: `terraform-backend-*`, `infrastructure-terraform-*`
- **Kubernetes**: `aks-cluster-*`, `deployment-application-*`
- **GitHub Actions**: `deployment-github-actions-*`
- **Networking**: `terraform-backend-network-*`, `troubleshooting-network-*`

### By Complexity
- **Beginner**: `aks-cluster-multi-environment-deployment.md`
- **Intermediate**: `terraform-backend-network-access.md`, `deployment-github-actions-pipelines.md`
- **Advanced**: `infrastructure-security-best-practices.md`, `infrastructure-terraform-modules.md`

### By Environment
- **Development**: `deployment-bootstrap-enhancement.md`
- **Production**: `infrastructure-security-best-practices.md`
- **CI/CD**: `deployment-github-actions-pipelines.md`

## 💡 Tips for Using Prompts

1. **Start with context**: Always provide your specific environment details
2. **Be specific**: Include error messages, resource names, and configurations
3. **Combine prompts**: Use multiple prompts for complex scenarios
4. **Iterate**: Refine prompts based on the responses you get
5. **Customize**: Modify prompts to match your specific requirements

## 🔄 Prompt Maintenance

- **Regular updates**: Keep prompts current with Azure changes
- **Feedback integration**: Improve prompts based on usage experience
- **New scenarios**: Add prompts for emerging use cases
- **Version control**: Track prompt changes and improvements

---
*Last updated: July 9, 2025*
