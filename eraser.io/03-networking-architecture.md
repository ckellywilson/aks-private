# Networking Architecture - Detailed Network Design

## Eraser.io Prompt

**Context**: Generate a detailed Azure networking architecture diagram focusing on the network design, security controls, and connectivity patterns for the AKS private cluster implementation.

## Architecture Overview

Create a comprehensive networking diagram showing the complete network architecture for AKS private clusters with emphasis on:

### Network Topology
- **Hub-and-spoke network design** with centralized shared services
- **Private AKS clusters** with completely private API servers
- **Network segmentation** using subnets and Network Security Groups
- **Private endpoint connectivity** for Azure PaaS services
- **Secure outbound internet access** through Azure Firewall or NAT Gateway

### Security-First Design
- **Zero-trust networking** principles with explicit allow rules
- **Network micro-segmentation** for pod-to-pod communication
- **Private DNS zones** for internal name resolution
- **Network Security Groups** with least-privilege access
- **Azure Policy** enforcement for network compliance

## Detailed Network Components

### Hub VNet Architecture
**Hub VNet CIDR**: 10.0.0.0/16

**Subnets in Hub**:
- **Azure Firewall Subnet**: 10.0.1.0/26 (AzureFirewallSubnet - required name)
- **VPN Gateway Subnet**: 10.0.2.0/27 (GatewaySubnet - required name)  
- **Azure Bastion Subnet**: 10.0.3.0/27 (AzureBastionSubnet - required name)
- **Shared Services Subnet**: 10.0.4.0/24 (Domain controllers, monitoring)
- **Management Subnet**: 10.0.5.0/27 (Jump boxes, administrative VMs)

**Hub Services**:
- **Azure Firewall**: Centralized outbound internet access and filtering
- **VPN Gateway**: Site-to-site connectivity for on-premises integration
- **Azure Bastion**: Secure RDP/SSH access without public IP addresses
- **Private DNS Zones**: Centralized DNS for private endpoint resolution
- **Network Watcher**: Network monitoring and diagnostics

### Development Spoke VNet
**Dev VNet CIDR**: 10.1.0.0/16

**Subnets**:
- **AKS System Subnet**: 10.1.1.0/24 (System node pool)
- **AKS User Subnet**: 10.1.2.0/23 (User workloads, large address space for pods)
- **ACR Private Endpoint**: 10.1.4.0/28 (If using private endpoints in dev)
- **Key Vault Private Endpoint**: 10.1.4.16/28
- **Application Gateway**: 10.1.5.0/27 (If using App Gateway for ingress)

**Security Configuration**:
- Network Security Groups with development-friendly rules
- Limited private endpoint usage for cost optimization
- Direct internet access for some services (with restrictions)
- Azure AD authentication for developer access

### Staging Spoke VNet  
**Staging VNet CIDR**: 10.2.0.0/16

**Subnets**:
- **AKS System Subnet**: 10.2.1.0/24
- **AKS User Subnet**: 10.2.2.0/23
- **Pod Subnet**: 10.2.4.0/22 (Dedicated subnet for pod IP allocation)
- **ACR Private Endpoint**: 10.2.8.0/28
- **Key Vault Private Endpoint**: 10.2.8.16/28
- **Storage Private Endpoint**: 10.2.8.32/28
- **Application Gateway**: 10.2.9.0/27
- **Azure Bastion**: 10.2.10.0/27

**Security Configuration**:
- Fully private AKS cluster with private API server
- All Azure PaaS services accessible via private endpoints
- Network Security Groups with production-like rules
- Azure Firewall for outbound internet access

### Production Spoke VNet
**Production VNet CIDR**: 10.3.0.0/16

**Subnets**:
- **AKS System Subnet**: 10.3.1.0/24
- **AKS User Subnet**: 10.3.2.0/23  
- **Pod Subnet**: 10.3.4.0/22
- **ACR Private Endpoint**: 10.3.8.0/28
- **Key Vault Private Endpoint**: 10.3.8.16/28
- **Storage Private Endpoint**: 10.3.8.32/28
- **SQL Private Endpoint**: 10.3.8.48/28
- **Application Gateway**: 10.3.9.0/27
- **Azure Bastion**: 10.3.10.0/27
- **Load Balancer**: 10.3.11.0/28

**Security Configuration**:
- Maximum security with all traffic flowing through private networks
- Azure Firewall with comprehensive rule sets
- Network Security Groups with explicit allow rules only
- Azure Policy enforcement for network compliance

## Private Endpoint Architecture

### Private Endpoint Design
**Azure Container Registry**:
- Private endpoint in each spoke VNet
- Private DNS zone: privatelink.azurecr.io
- Network interface in dedicated subnet
- DNS resolution through hub DNS services

**Azure Key Vault**:
- Private endpoint per environment
- Private DNS zone: privatelink.vaultcore.azure.net
- Integrated with Azure AD for authentication
- Network policies for fine-grained access control

**Azure Storage Accounts**:
- Private endpoints for different storage services:
  - Blob storage: privatelink.blob.core.windows.net
  - File storage: privatelink.file.core.windows.net
  - Table storage: privatelink.table.core.windows.net

**Azure SQL Database** (if used):
- Private endpoint in production only
- Private DNS zone: privatelink.database.windows.net
- Connection pooling through private connectivity

### DNS Architecture
**Private DNS Zone Strategy**:
- Centralized private DNS zones in hub VNet
- Virtual network links to all spoke VNets
- Conditional forwarding for on-premises DNS integration
- Azure-provided DNS for public name resolution

**DNS Resolution Flow**:
1. Pod queries for privatelink.azurecr.io
2. Azure DNS resolver in VNet
3. Private DNS zone returns private endpoint IP
4. Traffic flows over private network to service

## Network Security Controls

### Network Security Groups (NSGs)
**AKS System Subnet NSG**:
- Allow inbound HTTPS (443) from Application Gateway
- Allow inbound SSH (22) from Bastion subnet only
- Allow outbound to internet via Azure Firewall
- Deny all other inbound traffic by default

**AKS User Subnet NSG**:
- Allow inbound from Application Gateway on required ports
- Allow pod-to-pod communication within cluster
- Allow outbound to ACR private endpoint
- Allow outbound to Key Vault private endpoint
- Route outbound internet via Azure Firewall

**Private Endpoint Subnets NSG**:
- Allow inbound from AKS subnets on service ports
- Allow outbound to Azure backbone (automatic)
- Explicit deny rules for internet access
- Logging enabled for security monitoring

### Azure Firewall Rules
**Network Rules**:
- Allow outbound HTTPS to Azure services (management)
- Allow outbound DNS to Azure DNS (53)
- Allow outbound NTP for time synchronization (123)
- Allow specific outbound for container image pulls

**Application Rules**:
- Allow FQDN-based rules for container registries
- Allow access to Azure management endpoints
- Allow access to approved external package repositories
- Block all other outbound internet access

## Traffic Flow Patterns

### Inbound Traffic Flow
1. **Internet → Application Gateway** (Public IP with WAF)
2. **Application Gateway → AKS Load Balancer** (Private IP)
3. **Load Balancer → Pod** (CNI-assigned IP in pod subnet)
4. **Network policy enforcement** at pod level

### Outbound Traffic Flow
1. **Pod → Service** (cluster-internal or private endpoint)
2. **Pod → Azure Firewall** (for internet access)
3. **Azure Firewall → Internet** (with SNAT and filtering)
4. **Return traffic via established connections**

### Management Traffic Flow
1. **Administrator → Azure Bastion** (over internet with MFA)
2. **Bastion → Jump box** (private IP, no public IP on target)
3. **Jump box → AKS API server** (private endpoint)
4. **API server authentication** via Azure AD

## Visual Guidelines

### Layout Structure
- **Top section**: Hub VNet with shared services
- **Middle section**: Spoke VNets arranged horizontally by environment
- **Bottom section**: On-premises connectivity and external services
- **Overlay**: Security controls and traffic flows

### Network Visualization
- **VNets**: Large rectangles with clear CIDR labels
- **Subnets**: Smaller rectangles within VNets with IP ranges
- **Peering connections**: Bidirectional arrows between VNets
- **Private endpoints**: Small circles with service icons
- **Traffic flows**: Colored arrows showing different traffic types

### Security Indicators
- **NSG shields**: At subnet boundaries showing security rules
- **Firewall icons**: Azure Firewall with rule processing
- **Lock icons**: Private endpoints and secure connections
- **DNS icons**: Private DNS zones and resolution paths

### Color Coding
- **Blue**: Network infrastructure (VNets, subnets, NSGs)
- **Red**: Security services (Firewall, Bastion, NSGs)
- **Green**: Private endpoints and secure connectivity
- **Purple**: DNS and name resolution services
- **Orange**: Management and administrative access

## Expected Output

A detailed networking architecture diagram that clearly shows:
- Complete network topology with accurate IP addressing
- Private endpoint connectivity and DNS resolution
- Security controls and traffic filtering points
- Traffic flow patterns for different scenarios
- Network segmentation and isolation boundaries
- Management access paths and security controls

This diagram should serve as the definitive reference for network implementation and be suitable for network security reviews and compliance audits.
