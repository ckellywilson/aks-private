# Multi-Environment Deployment Architecture

## Eraser.io Prompt

**Context**: Generate an Azure architecture diagram showing the multi-environment deployment strategy for AKS private clusters, illustrating how dev, staging, and production environments are structured with different security postures and shared services.

## Architecture Overview

Create a comprehensive diagram showing three distinct environments for AKS deployment:

### Development Environment
**Purpose**: Developer productivity and rapid iteration
- **Security Level**: Moderate (balance between security and accessibility)
- **Access Pattern**: Direct developer access with some public endpoints
- **Cost Optimization**: Aggressive (lower-cost SKUs, scheduled start/stop)

### Staging Environment  
**Purpose**: Production-like testing and validation
- **Security Level**: High (mirrors production security)
- **Access Pattern**: Controlled access, private endpoints
- **Cost Optimization**: Balanced (production-like but smaller scale)

### Production Environment
**Purpose**: Live customer workloads
- **Security Level**: Maximum (fully locked down)
- **Access Pattern**: Strictly controlled, all private endpoints
- **Cost Optimization**: Performance-focused (high availability, scaling)

## Environment-Specific Configurations

### Development Environment Details
**Infrastructure**:
- **AKS Cluster**: Standard_D2s_v3 nodes, 1-3 node auto-scaling
- **ACR**: Basic SKU with public endpoint (network restrictions)
- **Key Vault**: Standard SKU with selected network access
- **Networking**: Simplified VNet, fewer subnets
- **Monitoring**: Basic monitoring, shorter retention periods

**Security Posture**:
- Network access from developer IP ranges
- Azure AD authentication for developers
- Basic RBAC with developer permissions
- Network Security Groups with development-friendly rules
- No private endpoints (cost optimization)

**Access Patterns**:
- Developers connect directly via kubectl
- Container builds push to ACR via Azure CLI
- Secrets managed through Azure CLI/Portal
- Monitoring dashboards publicly accessible to team

### Staging Environment Details
**Infrastructure**:
- **AKS Cluster**: Standard_D4s_v3 nodes, 2-5 node auto-scaling
- **ACR**: Standard SKU with private endpoint
- **Key Vault**: Premium SKU with private endpoint and HSM
- **Networking**: Production-like VNet with full subnet segmentation
- **Monitoring**: Full monitoring stack with medium retention

**Security Posture**:
- Private AKS cluster with private API endpoint
- Private endpoints for all Azure PaaS services
- Azure Bastion for administrative access
- Network Security Groups with production-like rules
- Azure AD with staging-specific groups and permissions

**Access Patterns**:
- Access via Azure Bastion and jump box
- CI/CD pipelines deploy via managed identity
- Private connectivity for all service communication
- Monitoring accessible via private endpoints

### Production Environment Details
**Infrastructure**:
- **AKS Cluster**: Standard_D8s_v4+ nodes, 3-20 node auto-scaling
- **ACR**: Premium SKU with geo-replication and private endpoints
- **Key Vault**: Premium SKU with HSM, private endpoints, and backup
- **Networking**: Fully segmented VNet with dedicated subnets for each service
- **Monitoring**: Complete observability stack with long retention

**Security Posture**:
- Fully private AKS cluster with private DNS zone
- All Azure services accessible only via private endpoints
- Azure Firewall for egress traffic control
- Comprehensive Network Security Groups and Azure Policy enforcement
- Zero-trust networking with micro-segmentation

**Access Patterns**:
- No direct access - all through CI/CD pipelines
- Break-glass emergency access via Azure Bastion
- All service-to-service communication over private networks
- Monitoring and alerting with 24/7 operations integration

## Shared Services Architecture

### Cross-Environment Shared Services
**Azure Container Registry**:
- Single Premium ACR with geo-replication
- Private endpoints in staging and production VNets
- Public endpoint with IP restrictions for development
- Separate repositories/tags for each environment

**Azure Monitor & Log Analytics**:
- Dedicated workspace per environment
- Central monitoring subscription for cross-environment dashboards
- Shared alerting and notification systems
- Centralized cost management and reporting

**Azure Key Vault**:
- Separate Key Vault per environment
- Shared certificate management for wildcard SSL certificates
- Environment-specific access policies and RBAC
- Cross-environment backup and disaster recovery

### CI/CD Pipeline Integration
**GitHub Actions Workflows**:
- Separate workflows for each environment
- Progressive deployment: dev → staging → production
- Environment-specific approval gates and security scanning
- Shared runner infrastructure with environment isolation

**Infrastructure as Code**:
- Terraform state files per environment
- Shared modules with environment-specific parameters
- Centralized Terraform backend with environment isolation
- Policy-as-code enforcement across all environments

## Network Topology

### Hub-Spoke Architecture
**Hub VNet** (Shared Services):
- Azure Firewall for centralized egress control
- VPN Gateway for on-premises connectivity
- Shared DNS services and domain controllers
- Central monitoring and security services

**Spoke VNets** (Per Environment):
- Development Spoke: 10.1.0.0/16
- Staging Spoke: 10.2.0.0/16  
- Production Spoke: 10.3.0.0/16
- VNet peering to hub for shared services access

### Cross-Environment Isolation
- **Network isolation**: Separate VNets with controlled peering
- **Identity isolation**: Environment-specific Azure AD groups and service principals
- **Resource isolation**: Separate subscriptions or resource groups per environment
- **Policy isolation**: Environment-specific Azure Policy assignments

## Visual Guidelines

### Layout Structure
- **Horizontal layout**: Dev → Staging → Production (left to right)
- **Shared services**: Top section showing centralized components
- **Network flows**: Clear arrows showing promotion pipeline
- **Security boundaries**: Color-coded borders for security levels

### Color Coding
- **Green**: Development environment (permissive)
- **Yellow**: Staging environment (production-like)
- **Red**: Production environment (fully secured)
- **Blue**: Shared services and hub infrastructure
- **Gray**: Network infrastructure and connectivity

### Security Indicators
- **Open locks**: Public endpoints in development
- **Partial locks**: Restricted access in staging
- **Closed locks**: Private endpoints in production
- **Shield icons**: Network security groups and firewalls
- **Eye icons**: Monitoring and observability

### Flow Indicators
- **Deployment flows**: Code promotion from dev through prod
- **Data flows**: Metrics, logs, and monitoring data
- **Access flows**: User and service authentication paths
- **Network flows**: Traffic routing and connectivity

## Specific Requirements

1. **Show environment progression** with clear promotion pipeline
2. **Highlight security differences** between environments
3. **Illustrate shared services** and how they're consumed
4. **Display network isolation** and controlled connectivity
5. **Include cost optimization** strategies per environment
6. **Show CI/CD integration** with environment-specific deployments

## Expected Output

A comprehensive multi-environment architecture diagram that clearly demonstrates:
- Environment-specific security postures and access patterns
- Shared services strategy and resource optimization
- Network topology with proper isolation and connectivity
- CI/CD pipeline integration and deployment flows
- Progressive security hardening from dev to production
- Cost optimization strategies appropriate for each environment

This diagram should serve as a reference for understanding the complete multi-environment strategy and be suitable for architectural reviews and compliance discussions.
