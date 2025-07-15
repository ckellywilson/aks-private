# Simplified AKS Private Cluster - Production Architecture

## Eraser.io Prompt

**Context**: Generate a simplified Azure architecture diagram for a production-ready AKS (Azure Kubernetes Service) private cluster implementation with a single application landing zone, focused on core components and streamlined network architecture.

## Architecture Overview

Create a detailed Azure architecture diagram showing a simplified AKS private cluster setup with the following key characteristics:

### Core Infrastructure
- **Private AKS Cluster** in a dedicated VNet with private API server endpoint and no public access
- **Azure Container Registry (ACR)** with private endpoints for secure container image access
- **Azure Key Vault** for secrets management with private endpoint connectivity and CSI driver integration
- **Azure Application Gateway** with Web Application Firewall (WAF) for secure external access
- **Internal Load Balancer** (nginx-ingress or AGIC) for internal service routing
- **Virtual Network** with segmented subnets for different components and proper network isolation
- **Azure Bastion** for secure administrative access
- **Network Security Groups (NSGs)** and Azure Firewall for comprehensive traffic filtering

### Single Application Landing Zone Network Architecture
- **Single VNet**: Consolidated application landing zone with all components in one virtual network
- **Private DNS zones** for internal name resolution
- **Private endpoints** for secure communication to all Azure PaaS services
- **User-Defined Routes (UDRs)** forcing traffic through Azure Firewall for egress control
- **Network security perimeter** with zero-trust network access principles
- **Subnet segmentation** for proper isolation between components

### Production Environment Design
Show production environment with comprehensive security hardening:
- **Production environment**: Fully private with all security controls, compliance monitoring, and zero-trust access
- **Enterprise-grade security** with comprehensive monitoring and governance
- **High availability** across multiple availability zones
- **Disaster recovery** and business continuity planning

### Identity & Access Management
- **Azure AD integration** with RBAC for cluster and namespace-level permissions
- **Managed identities** for secure service-to-service authentication without secrets
- **Azure AD Pod Identity** or **Workload Identity** for pod-level authentication to Azure services
- **Just-in-Time (JIT) access** through Azure Bastion and conditional access policies
- **Service principals** with minimal required permissions for CI/CD automation

### Ingress & Traffic Management
- **Azure Application Gateway** with WAF v2 for external traffic protection and SSL termination
- **Internal nginx-ingress** or **Application Gateway Ingress Controller (AGIC)** for internal routing
- **Internal Load Balancer** with private IP for secure internal service exposure
- **Network policies** for pod-to-pod communication control and micro-segmentation

### Compute & Storage
- **System node pools**: Dedicated for cluster services (2-3 nodes, Standard_D4s_v4)
- **User node pools**: Application workloads with auto-scaling (1-10 nodes, Standard_D8s_v4, multiple zones)
- **Azure Files** with private endpoints for shared storage scenarios and legacy application support
- **Backup strategies** with Velero for disaster recovery and Azure Backup for VM-level protection

### CI/CD & Infrastructure Automation
- **GitHub Actions** or **Azure DevOps** pipelines for automated infrastructure deployment
- **Infrastructure as Code** with Terraform modules for consistent environment provisioning
- **GitOps workflows** with ArgoCD or Flux for application deployment automation
- **Security scanning** integration in CI/CD pipeline (container images, infrastructure code, secrets)
- **Blue-green deployments** and canary releases for zero-downtime application updates

### Cost Optimization & Governance
- **Azure Policy** for governance, compliance, and cost control automation
- **Cluster autoscaler** and **Horizontal Pod Autoscaler (HPA)** for dynamic resource optimization
- **Resource quotas** and **limit ranges** for workload resource management
- **Azure Cost Management** integration for cost monitoring and budget alerts

### Monitoring & Observability
- **Azure Monitor** with Container Insights for cluster monitoring
- **Log Analytics workspace** for centralized logging
- **Azure Application Insights** for application performance monitoring
- **Prometheus and Grafana** for detailed metrics (if using Azure Monitor managed Prometheus)

## Detailed Components

### AKS Cluster Configuration
- **Private cluster enabled** with private DNS zone and no public API server access
- **System node pool**: 2-3 nodes, Standard_D4s_v4 VMs, dedicated for system pods
- **User node pool**: Auto-scaling 1-10 nodes, Standard_D8s_v4 VMs, spread across multiple zones
- **Azure CNI networking** with pod subnet delegation for enhanced networking capabilities
- **Azure AD integration** with RBAC for fine-grained access control
- **Managed identity** for cluster authentication and Azure service integration
- **Network policies** (Calico or Azure) for micro-segmentation and pod-level security

### Single Application Landing Zone Network Topology
**Production VNet (Consolidated Landing Zone)**:
- **VNet CIDR**: 10.0.0.0/16
- **AKS subnet**: 10.0.1.0/24 with large address space for pod networking
- **Private endpoints subnet**: 10.0.2.0/27 (ACR, Key Vault, Storage)
- **Application Gateway subnet**: 10.0.3.0/27 (external traffic ingress)
- **Internal Load Balancer subnet**: 10.0.4.0/27 (nginx-ingress, internal services)
- **Azure Firewall subnet**: 10.0.5.0/26 (AzureFirewallSubnet)
- **Bastion subnet**: 10.0.6.0/27 (AzureBastionSubnet)
- **Shared services subnet**: 10.0.7.0/24 (DNS, monitoring, management tools)

### Security & Compliance Configuration
- **Zero-trust network access** with private endpoints and no public access points
- **Azure Policy** for governance, compliance automation, and security baselines
- **Microsoft Defender for Containers** for runtime threat detection and vulnerability scanning
- **Pod Security Standards** (restricted) enforced cluster-wide with policy exceptions
- **Secrets management** through Azure Key Vault CSI driver with rotation automation
- **Network security groups** with least-privilege access rules and application-aware filtering
- **Azure Firewall** with application and network rules for controlled egress traffic

### Traffic Flow Patterns
1. **External User Traffic**: Internet → Application Gateway (WAF) → Internal Load Balancer → AKS Pods
2. **Developer Access**: VPN/ExpressRoute → Azure Bastion → AKS Management
3. **CI/CD Automation**: GitHub Actions → Azure → Terraform → AKS Infrastructure
4. **Container Images**: AKS Nodes → ACR Private Endpoint → Container Registry
5. **Secrets Access**: AKS Pods → Key Vault Private Endpoint → Azure Key Vault
6. **Monitoring Data**: AKS Components → Azure Monitor → Log Analytics Workspace

### Storage & Data
- **Container Storage Interface (CSI)** drivers for Azure File
- **Backup and disaster recovery** with Velero or Azure Backup
- **Persistent Volume Claims** for stateful applications

## Visual Guidelines

### Layout Suggestions
- **Single VNet topology**: Consolidated application landing zone with all components in one network
- **Traffic flow visualization**: Clear arrows showing ingress, egress, and internal communication paths
- **Security zones**: Distinct visual boundaries for public, DMZ, private, and management zones
- **Production-focused display**: Single environment view with enterprise-grade components
- **Color coding with security context**: 
  - Blue for compute resources and applications
  - Green for networking and connectivity components
  - Red for security services and protective controls
  - Purple for monitoring, observability, and management
  - Orange for storage and data services
  - Gray for infrastructure and platform services

### Azure Service Icons
Use official Azure service icons for comprehensive service representation:
- Azure Kubernetes Service (with private cluster indicator)
- Azure Container Registry (with private endpoint symbol)
- Azure Key Vault (with CSI driver integration)
- Azure Application Gateway (with WAF shield)
- Virtual Network (with subnet segmentation indication)
- Network Security Groups (with rule counts)
- Azure Bastion (with secure access symbol)
- Azure Firewall (with traffic control indication)
- Azure Monitor (with Container Insights)
- Log Analytics (with data ingestion flows)
- Azure AD (with RBAC integration)
- GitHub Actions or Azure DevOps (for CI/CD automation)

### Connection Types
- **Solid lines**: Direct network connections
- **Dashed lines**: Private endpoint connections
- **Dotted lines**: Management/monitoring connections
- **Thick lines**: High-bandwidth data paths
- **Arrows**: Direction of traffic flow

### Security Boundaries
- **Subnet boundaries**: Clearly defined rectangles
- **Network security groups**: Shield icons at subnet borders
- **Private endpoints**: Lock icons with connection lines
- **Azure AD**: Authentication flows with user icons

### Labels and Annotations
- **Service names**: Clear, readable labels for each component
- **IP address ranges**: Subnet CIDR blocks
- **Key configurations**: Private cluster, RBAC enabled, etc.
- **Security features**: NSG rules, private endpoints, etc.

## Specific Requirements

1. **Show consolidated single VNet topology** with clear subnet segmentation and traffic flows
2. **Illustrate zero-trust network architecture** with private endpoints and no public access points
3. **Display complete traffic flows** from external users through multiple security layers to applications
4. **Highlight CI/CD integration** showing infrastructure automation and deployment pipelines
5. **Emphasize security boundaries** with NSGs, Azure Firewall, and network segmentation
6. **Show identity integration** with Azure AD, managed identities, and RBAC throughout the stack
7. **Display monitoring and observability** data flows to Azure Monitor and Log Analytics
8. **Include cost optimization features** like autoscaling and resource quotas
9. **Show disaster recovery** and backup strategies for production environment
10. **Illustrate compliance** and governance controls through Azure Policy integration

## Expected Output

A simplified, production-focused Azure architecture diagram that clearly demonstrates:
- **Complete AKS private cluster setup** with zero-trust network architecture and comprehensive security controls
- **Single application landing zone** with consolidated network topology and proper subnet segmentation
- **Production-grade deployment strategy** with comprehensive security hardening and enterprise controls
- **Integrated CI/CD automation** showing infrastructure and application deployment workflows
- **Identity and access management** integration throughout the entire stack
- **Comprehensive monitoring and observability** with centralized logging and metrics collection
- **Cost optimization and governance** controls for efficient resource utilization
- **Disaster recovery and business continuity** planning for production environment
- **Security compliance and governance** through automated policy enforcement
- **Professional enterprise layout** suitable for executive presentations, technical reviews, compliance audits, and operational documentation

This simplified diagram should serve as a streamlined reference for the AKS private cluster architecture implementation in a single application landing zone and be suitable for enterprise architecture reviews, security assessments, compliance audits, and operational team onboarding focused on production deployments.
