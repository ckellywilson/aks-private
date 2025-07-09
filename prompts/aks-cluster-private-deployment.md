# Private AKS Cluster Deployment and Configuration

## Context
Deploying and managing a private Azure Kubernetes Service (AKS) cluster with proper networking, security, and connectivity. The cluster should be isolated from public internet while maintaining necessary access for management and CI/CD operations.

## Task
Deploy, configure, and troubleshoot private AKS cluster including networking, node pools, identity management, and integration with other Azure services.

## Requirements
- Private AKS cluster with no public API server endpoint
- VNet integration with custom subnet (10.240.0.0/16)
- Azure Bastion for secure management access
- Managed identity for cluster and kubelet
- Integration with Azure Container Registry (ACR)
- Log Analytics workspace for monitoring
- Private DNS zones for cluster resolution
- Network policies for pod-to-pod communication
- Multiple node pools (system and user)

## Current Architecture
```
VNet (10.240.0.0/16)
├── AKS Subnet (configurable CIDR)
│   ├── System Node Pool (1-3 nodes)
│   ├── User Node Pool (auto-scaling)
│   └── Private API Server
├── Bastion Subnet (10.240.1.0/24)
│   └── Azure Bastion Host
└── Private DNS Zone
    └── privatelink.{region}.azmk8s.io
```

## Infrastructure Components
- **Resource Group**: Main container for all resources
- **Managed Identities**: Cluster identity and kubelet identity
- **VNet**: Virtual network with subnets and security groups
- **AKS Cluster**: Private cluster with managed identity
- **ACR**: Container registry with VNet integration
- **Log Analytics**: Monitoring and logging workspace
- **Bastion**: Secure access for management

## Common Configuration Areas
- Kubernetes version and upgrade policies
- Node pool sizing and scaling configuration
- Network policies (Azure CNI, Calico, etc.)
- Ingress controllers (nginx, application gateway)
- Certificate management (cert-manager, Let's Encrypt)
- Monitoring and alerting setup
- RBAC and security policies

## Typical Issues
- Connectivity problems to private API server
- Node pool scaling and resource allocation
- Container registry authentication and access
- Ingress configuration and DNS resolution
- Pod-to-pod communication and network policies
- Certificate provisioning and renewal
- Monitoring and log collection setup

## Expected Outcomes
- Terraform modules for consistent cluster deployment
- Scripts for post-deployment configuration (ingress, cert-manager)
- Troubleshooting guides for common networking issues
- Best practices for security and compliance
- Automated testing and validation procedures

## Additional Context
- Using Terraform for infrastructure-as-code
- GitHub Actions for CI/CD pipelines
- Helm for application deployment
- Azure CLI and kubectl for management
- Following Azure Well-Architected Framework principles
