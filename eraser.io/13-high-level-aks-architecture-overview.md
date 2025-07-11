# High-Level AKS Private Cluster Architecture Overview

## Eraser.io Prompt

**Context**: Generate a high-level architecture diagram showing the primary components of the AKS private cluster environment with their key connections, focusing on the main infrastructure elements, CI/CD pipeline, and DNS resolution flow with specific IP addresses and A records.

## Architecture Overview

Create a simplified, high-level diagram showing the core components and their relationships:

### Primary Infrastructure Components
- **Private AKS Cluster** with 2 system node pools and 2 user node pools
- **Azure Container Registry (ACR)** with private endpoint connectivity
- **Azure Application Gateway** as the internet-facing entry point
- **Custom DNS Server (Infoblox)** for domain resolution
- **Internal nginx-ingress Load Balancer** for cluster traffic routing
- **GitHub Actions CI/CD Pipeline** for infrastructure automation

### Key Connectivity and DNS Configuration
- **DNS A Records** mapping domains to Application Gateway public IP
- **Private endpoint connections** between AKS and ACR
- **Internal load balancer** with private IP for nginx-ingress
- **GitHub Actions workflows** for Terraform-based infrastructure deployment

## Detailed Component Architecture

### Private AKS Cluster Configuration
**AKS Cluster Design**:
- **Cluster Name**: aks-private-prod
- **Private API Server**: No public endpoint access
- **Network Plugin**: Azure CNI with pod subnet delegation
- **Outbound Type**: Load balancer with private connectivity
- **Authorized IP Ranges**: Disabled (private cluster)

**Node Pool Configuration**:
```yaml
# AKS Node Pool Architecture
Private AKS Cluster (aks-private-prod):
├── System Node Pools:
│   ├── System Pool 1 (system-pool-1):
│   │   ├── VM Size: Standard_D4s_v4 (4 vCPU, 16 GB RAM)
│   │   ├── Node Count: 3 nodes
│   │   ├── Availability Zone: Zone 1
│   │   ├── OS Disk: 128 GB Premium SSD
│   │   └── IP Range: 10.3.1.10 - 10.3.1.12
│   └── System Pool 2 (system-pool-2):
│       ├── VM Size: Standard_D4s_v4 (4 vCPU, 16 GB RAM)
│       ├── Node Count: 3 nodes
│       ├── Availability Zone: Zone 2
│       ├── OS Disk: 128 GB Premium SSD
│       └── IP Range: 10.3.1.13 - 10.3.1.15
├── User Node Pools:
│   ├── User Pool 1 (user-pool-1):
│   │   ├── VM Size: Standard_D8s_v4 (8 vCPU, 32 GB RAM)
│   │   ├── Node Count: 3-10 nodes (auto-scaling)
│   │   ├── Availability Zone: Zone 1
│   │   ├── OS Disk: 256 GB Premium SSD
│   │   └── IP Range: 10.3.1.20 - 10.3.1.50
│   └── User Pool 2 (user-pool-2):
│       ├── VM Size: Standard_D8s_v4 (8 vCPU, 32 GB RAM)
│       ├── Node Count: 3-10 nodes (auto-scaling)
│       ├── Availability Zone: Zone 2
│       ├── OS Disk: 256 GB Premium SSD
│       └── IP Range: 10.3.1.51 - 10.3.1.80
└── Private API Server:
    ├── Private Endpoint: 10.3.3.10
    ├── Private DNS Zone: privatelink.eastus.azmk8s.io
    └── FQDN: aks-private-prod-dns-12345678.privatelink.eastus.azmk8s.io
```

### nginx-ingress Internal Load Balancer
**Internal Load Balancer Configuration**:
- **Service Type**: LoadBalancer with Azure internal annotation
- **Private IP**: 10.3.2.100 (static assignment)
- **Subnet**: Internal Load Balancer subnet (10.3.2.0/24)
- **Backend**: nginx-ingress controller pods across both user node pools
- **Health Probes**: HTTP health checks on /healthz endpoint

**nginx-ingress Load Balancer Details**:
```yaml
# nginx-ingress Internal Load Balancer
Internal Load Balancer Configuration:
├── Load Balancer Details:
│   ├── Name: nginx-ingress-internal-lb
│   ├── Type: Azure Internal Load Balancer
│   ├── Private IP: 10.3.2.100 (static)
│   ├── Subnet: 10.3.2.0/24 (internal-lb-subnet)
│   └── SKU: Standard
├── Backend Pool:
│   ├── nginx-ingress pods on user-pool-1 nodes
│   ├── nginx-ingress pods on user-pool-2 nodes
│   ├── Health Check: HTTP:80/healthz
│   └── Session Affinity: None
├── Load Balancing Rules:
│   ├── HTTP Rule: 80 → 80 (nginx-ingress)
│   ├── HTTPS Rule: 443 → 443 (nginx-ingress)
│   └── Distribution: Round Robin
└── Network Security:
    ├── Source: Application Gateway subnet
    ├── Destination: nginx-ingress pods
    └── Protocols: HTTP/HTTPS only
```

### Azure Container Registry (ACR) with Private Endpoint
**ACR Private Connectivity**:
- **Registry Name**: acrprodeastus.azurecr.io
- **Private Endpoint**: 10.3.3.20
- **Private DNS Zone**: privatelink.azurecr.io
- **Network Access**: Disabled public access, private endpoint only
- **Authentication**: Azure AD service principal integration

**ACR Configuration Details**:
```yaml
# Azure Container Registry Configuration
ACR Private Endpoint Setup:
├── Registry Information:
│   ├── Name: acrprodeastus
│   ├── SKU: Premium (geo-replication enabled)
│   ├── Public Access: Disabled
│   └── Admin User: Disabled (Azure AD only)
├── Private Endpoint:
│   ├── Private IP: 10.3.3.20
│   ├── Subnet: 10.3.3.0/24 (private-endpoints-subnet)
│   ├── Private DNS Zone: privatelink.azurecr.io
│   └── DNS Record: acrprodeastus.privatelink.azurecr.io → 10.3.3.20
├── AKS Integration:
│   ├── Authentication: Managed Identity
│   ├── Image Pull: Private endpoint connectivity
│   ├── Network Path: AKS nodes → Private endpoint
│   └── DNS Resolution: CoreDNS → Azure Private DNS
└── Security Configuration:
    ├── Network Rules: Private endpoint only
    ├── Firewall: Disabled (private access)
    ├── Trust Policy: Azure services allowed
    └── Vulnerability Scanning: Enabled
```

### Azure Application Gateway
**Application Gateway Configuration**:
- **Public IP**: 52.168.1.100
- **Subnet**: 10.2.1.0/24 (separate gateway VNet)
- **Backend Pool**: nginx-ingress internal load balancer (10.3.2.100)
- **WAF**: Enabled with OWASP 3.2 rules
- **SSL Termination**: *.example.com wildcard certificate

**Application Gateway Details**:
```yaml
# Azure Application Gateway Configuration
Application Gateway Setup:
├── Gateway Information:
│   ├── Name: app-gateway-prod
│   ├── SKU: WAF_v2 (Web Application Firewall)
│   ├── Public IP: 52.168.1.100
│   ├── Subnet: 10.2.1.0/24 (gateway-subnet)
│   └── Capacity: Auto-scaling (2-10 instances)
├── Frontend Configuration:
│   ├── Public IP Listener: 52.168.1.100:443 (HTTPS)
│   ├── SSL Certificate: *.example.com (wildcard)
│   ├── HTTP Redirect: Port 80 → 443
│   └── Custom Domains: app.example.com, api.example.com
├── Backend Pool Configuration:
│   ├── Backend Type: IP Address
│   ├── Target: 10.3.2.100 (nginx-ingress internal LB)
│   ├── Port: 443 (HTTPS backend)
│   └── Health Probe: HTTPS:/10.3.2.100/healthz
├── WAF Protection:
│   ├── Rule Set: OWASP 3.2
│   ├── Mode: Prevention
│   ├── Custom Rules: Rate limiting, geo-blocking
│   └── Exclusions: Application-specific exceptions
└── Routing Rules:
    ├── app.example.com → nginx-ingress backend
    ├── api.example.com → nginx-ingress backend
    └── Default: nginx-ingress backend pool
```

### Custom DNS Server (Infoblox)
**Infoblox DNS Configuration**:
- **Primary DNS**: 203.0.113.10 (public-facing for external domains)
- **Secondary DNS**: 203.0.113.11 (backup/redundancy)
- **Management IP**: 10.1.1.10 (internal management interface)
- **Zone Authority**: example.com (external domain)
- **Integration**: Conditional forwarding to Azure Private DNS

**DNS Configuration and A Records**:
```yaml
# Infoblox DNS Server Configuration
Custom DNS Server (Infoblox):
├── DNS Server Details:
│   ├── Primary Server: dns1.example.com (203.0.113.10)
│   ├── Secondary Server: dns2.example.com (203.0.113.11)
│   ├── Management Interface: 10.1.1.10
│   └── Zone Transfer: Secured with TSIG keys
├── External DNS Zone (example.com):
│   ├── SOA Record: dns1.example.com
│   ├── NS Records: dns1.example.com, dns2.example.com
│   ├── A Records (Public Domain → App Gateway):
│   │   ├── app.example.com → 52.168.1.100
│   │   ├── api.example.com → 52.168.1.100
│   │   ├── www.example.com → 52.168.1.100
│   │   └── portal.example.com → 52.168.1.100
│   └── MX Records: mail.example.com (if applicable)
├── Internal DNS Zone (internal.example.com):
│   ├── A Records (Internal Services):
│   │   ├── nginx-ingress.internal.example.com → 10.3.2.100
│   │   ├── aks-api.internal.example.com → 10.3.3.10
│   │   ├── acr.internal.example.com → 10.3.3.20
│   │   └── management.internal.example.com → 10.1.1.10
│   └── CNAME Records: app-internal.internal.example.com → nginx-ingress.internal.example.com
└── Azure Private DNS Integration:
    ├── Conditional Forwarder: privatelink.azurecr.io → 168.63.129.16
    ├── Conditional Forwarder: privatelink.eastus.azmk8s.io → 168.63.129.16
    └── Conditional Forwarder: privatelink.vaultcore.azure.net → 168.63.129.16
```

### GitHub Actions CI/CD Pipeline
**Infrastructure Automation**:
- **Repository**: github.com/myorg/aks-private-infrastructure
- **Workflow Triggers**: Push to main, PR creation, release tags
- **Authentication**: GitHub OIDC to Azure (passwordless)
- **Terraform Backend**: Azure Storage with state locking
- **Environments**: Development, Staging, Production with approval gates

**CI/CD Pipeline Architecture**:
```yaml
# GitHub Actions Infrastructure CI/CD
GitHub Actions Pipeline:
├── Repository Structure:
│   ├── Source: github.com/myorg/aks-private-infrastructure
│   ├── Terraform Modules: /infra/tf/modules/
│   ├── Environments: /infra/tf/environments/
│   └── Workflows: /.github/workflows/
├── Workflow Triggers:
│   ├── Push to main: Auto-deploy to dev
│   ├── Pull Request: Terraform plan + security scan
│   ├── Release Tag: Deploy to staging/production
│   └── Schedule: Daily drift detection
├── Authentication:
│   ├── Method: GitHub OIDC (passwordless)
│   ├── Azure Integration: Federated credentials
│   ├── Service Principal: Per-environment principals
│   └── Permissions: Minimal required access
├── Deployment Stages:
│   ├── Development: Fully automated
│   ├── Staging: Manual approval required
│   ├── Production: Multiple approvals + change management
│   └── Rollback: Automated on failure detection
└── Infrastructure Components Deployed:
    ├── AKS Private Cluster: Terraform azurerm_kubernetes_cluster
    ├── ACR with Private Endpoint: Terraform azurerm_container_registry
    ├── Application Gateway: Terraform azurerm_application_gateway
    ├── VNet and Networking: Terraform azurerm_virtual_network
    └── Monitoring and Security: Azure Monitor, Key Vault, NSGs
```

## Network Connectivity Flow

### Complete Traffic and DNS Flow
**End-to-End Connection Flow**:
1. **External Client** queries DNS for app.example.com
2. **Infoblox DNS** returns Application Gateway public IP (52.168.1.100)
3. **Application Gateway** receives HTTPS traffic and processes through WAF
4. **Backend Routing** forwards traffic to nginx-ingress (10.3.2.100)
5. **nginx-ingress** routes to appropriate Kubernetes services in AKS
6. **Response** flows back through the same path

### Network Architecture Summary
```yaml
# High-Level Network Flow
Complete Connection Architecture:
├── External Client:
│   ├── DNS Query: app.example.com → Infoblox DNS
│   ├── DNS Response: 52.168.1.100 (App Gateway)
│   └── HTTPS Request: Client → 52.168.1.100:443
├── Azure Application Gateway (52.168.1.100):
│   ├── WAF Processing: Security rule evaluation
│   ├── SSL Termination: *.example.com certificate
│   ├── Backend Selection: nginx-ingress-backend
│   └── Forward Request: → 10.3.2.100:443
├── nginx-ingress Load Balancer (10.3.2.100):
│   ├── Ingress Rule Evaluation: Host/path-based routing
│   ├── Service Discovery: Kubernetes services
│   ├── Load Balancing: Round-robin to pods
│   └── Forward Request: → Application pods
├── AKS Private Cluster:
│   ├── nginx-ingress Pods: Running on user node pools
│   ├── Application Pods: Backend services
│   ├── System Pods: Cluster management (system node pools)
│   └── Container Images: Pulled from ACR (10.3.3.20)
└── Supporting Services:
    ├── ACR Private Endpoint: 10.3.3.20
    ├── AKS API Server: 10.3.3.10
    ├── DNS Management: 10.1.1.10
    └── CI/CD: GitHub Actions automation
```

## Visual Guidelines

### Component Layout
- **Top Level**: External clients and DNS resolution
- **Upper Middle**: Custom DNS server (Infoblox) and Application Gateway
- **Lower Middle**: Private AKS cluster with node pools clearly separated
- **Bottom Level**: Supporting services (ACR, monitoring, CI/CD pipeline)
- **Side Panel**: GitHub Actions workflow visualization

### Connection Visualization
- **Blue Lines**: DNS queries and resolution
- **Green Lines**: HTTPS traffic flow (external to internal)
- **Orange Lines**: Internal cluster communication
- **Purple Lines**: Private endpoint connectivity
- **Red Lines**: CI/CD deployment flows

### IP Address and DNS Labeling
- **Clear IP Labels**: Show all key IP addresses on components
- **DNS Record Examples**: Display sample A records with actual IPs
- **Network Boundaries**: VNet boundaries and subnet separations
- **Security Zones**: Public, DMZ, and private zone indicators

### Node Pool Distinction
- **System Node Pools**: Different color/shape from user node pools
- **User Node Pools**: Clearly labeled with auto-scaling indicators
- **Pod Distribution**: Show nginx-ingress running on user pools
- **Resource Allocation**: VM sizes and capacity indicators

## Color Coding Strategy
- **Blue**: DNS services and domain resolution
- **Green**: Application Gateway and external connectivity
- **Orange**: AKS cluster and Kubernetes components
- **Purple**: Private endpoints and secure connectivity
- **Red**: CI/CD pipeline and automation
- **Gray**: Network infrastructure and subnets
- **Yellow**: Security controls and monitoring

## Specific Requirements

1. **Show all primary components** with clear connectivity lines
2. **Label key IP addresses** and DNS A records prominently
3. **Distinguish node pool types** (system vs user) clearly
4. **Display private endpoint connections** to ACR
5. **Include CI/CD pipeline** integration with infrastructure
6. **Show DNS resolution flow** from external to internal

## Expected Output

A high-level architecture diagram that clearly demonstrates:
- Private AKS cluster with distinct system and user node pools
- Complete DNS resolution from Infoblox to Application Gateway to nginx-ingress
- Private endpoint connectivity between AKS and ACR
- Application Gateway as the internet-facing entry point with WAF
- GitHub Actions CI/CD pipeline for infrastructure automation
- Key IP addresses and DNS A records for all major components
- Network flow from external clients through all components to applications

This diagram should serve as the primary reference for understanding the complete AKS private cluster architecture and be suitable for executive presentations and high-level technical reviews.
