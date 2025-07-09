# GitHub Actions CI/CD Pipeline for Private AKS

## Context
Setting up and maintaining GitHub Actions workflows for a private AKS cluster project, including Terraform operations, container builds, and deployment automation. The pipelines need to work with private networks and secure authentication.

## Task
Create, optimize, and troubleshoot GitHub Actions workflows for infrastructure deployment, application builds, testing, and deployment to private AKS cluster.

## Requirements
- OIDC authentication with Azure using managed identities
- Terraform operations (init, plan, apply) with private storage backend
- Container image builds and pushes to Azure Container Registry
- Helm chart deployments to private AKS cluster
- Security scanning (Checkov, container scanning)
- Parallel job execution for efficiency
- Proper secret management and environment separation
- VNet integration for accessing private resources

## Current Workflow Structure
```
├── tf-unit-tests.yml (Terraform validation and security)
├── terraform-plan.yml (Infrastructure planning)
├── terraform-apply.yml (Infrastructure deployment)
├── container-build.yml (Application builds)
└── aks-deployment.yml (Application deployment)
```

## Authentication Configuration
```yaml
permissions:
  id-token: write
  contents: read
  security-events: write

- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Common Challenges
- Accessing private storage backend from GitHub Actions runners
- Network connectivity to private AKS cluster for deployments
- Managing secrets and environment-specific configuration
- Efficient caching and artifact management
- Handling long-running operations and timeouts
- Coordinating infrastructure and application deployments
- Security scanning integration and SARIF uploads

## VNet Integration Options
1. **Azure Container Instances**: Deploy runners in VNet subnet
2. **Self-hosted Runners**: VM-based runners in Azure VNet
3. **Azure Container Apps Jobs**: Serverless job execution in VNet
4. **Private Endpoints**: Direct private connectivity to Azure services

## Expected Solutions
- Workflow templates for common deployment patterns
- Scripts for setting up self-hosted runners
- Troubleshooting guides for authentication and connectivity
- Best practices for secret management and security
- Performance optimization techniques
- Integration patterns for external tools and services

## Sample Workflow Pattern
```yaml
jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    environment: dev
    steps:
    - uses: actions/checkout@v4
    - uses: azure/login@v1
    - name: Run in VNet
      # Use Container Instance or self-hosted runner
    - name: Terraform Operations
      # Access private storage backend
```

## Additional Context
- Using Azure managed identities for authentication
- Private storage backend with VNet integration
- Multiple environments (dev, staging, prod)
- Terraform state management and locking
- Container registry integration
- Monitoring and alerting for pipeline health
