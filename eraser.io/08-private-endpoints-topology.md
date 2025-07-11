# Private Endpoints Network Topology

## Eraser.io Prompt

**Context**: Generate a detailed network topology diagram focusing specifically on private endpoint connectivity for AKS private clusters, showing how Azure PaaS services are securely connected through private networking without internet exposure.

## Architecture Overview

Create a comprehensive network topology diagram emphasizing private endpoint connectivity with:

### Private Connectivity Strategy
- **Azure Private Link** for secure access to Azure PaaS services
- **Private DNS zones** for internal name resolution of private endpoints
- **Network interface cards (NICs)** for private endpoint IP allocation
- **Hub-spoke private connectivity** across multiple environments
- **Cross-region private endpoint** connectivity for disaster recovery

### Zero Internet Exposure Model
- **No public endpoints** for any Azure PaaS services in staging/production
- **All service communication** through private Azure backbone
- **DNS resolution** pointing to private IP addresses
- **Network security groups** allowing only private network traffic
- **Audit and compliance** for fully private connectivity

## Detailed Private Endpoint Architecture

### Azure Container Registry (ACR) Private Endpoints

#### Per-Environment Private Endpoint Configuration
**Development Environment**:
- **ACR SKU**: Standard with public endpoint (IP-restricted)
- **Network access**: Public endpoint with developer IP allowlist
- **Private endpoint**: Optional (cost optimization consideration)
- **DNS resolution**: Public DNS with conditional private resolution

**Staging Environment**:
- **ACR SKU**: Standard with private endpoint
- **Network access**: Private endpoint only, no public access
- **Private endpoint subnet**: Dedicated /28 subnet (10.2.8.0/28)
- **DNS integration**: Private DNS zone with VNet linking

**Production Environment**:
- **ACR SKU**: Premium with geo-replication and private endpoints
- **Network access**: Private endpoints in multiple regions
- **Primary region**: East US with private endpoint (10.3.8.0/28)
- **Secondary region**: West US with private endpoint for DR
- **DNS integration**: Multi-region private DNS with failover

#### ACR Private Endpoint Network Configuration
```
ACR Private Endpoint Details:
├── Resource: mycompany-prod-acr.azurecr.io
├── Private IP: 10.3.8.4 (in ACR PE subnet)
├── Network Interface: acr-pe-nic-001
├── Private DNS Zone: privatelink.azurecr.io
├── DNS Records:
│   ├── mycompany-prod-acr.privatelink.azurecr.io → 10.3.8.4
│   └── mycompany-prod-acr.region.data.privatelink.azurecr.io → 10.3.8.5
└── Connected VNets:
    ├── Production VNet (10.3.0.0/16)
    ├── Hub VNet (10.0.0.0/16)
    └── Management VNet (10.10.0.0/16)
```

### Azure Key Vault Private Endpoints

#### Multi-Environment Key Vault Strategy
**Environment-Specific Key Vaults**:
- **Development**: `mycompany-dev-kv` with restricted public access
- **Staging**: `mycompany-staging-kv` with private endpoint
- **Production**: `mycompany-prod-kv` with private endpoint and HSM

**Private Endpoint Configuration**:
```
Key Vault Private Endpoint Topology:
├── Development KV (public with restrictions)
│   ├── Public endpoint: mycompany-dev-kv.vault.azure.net
│   ├── Network ACLs: Developer IP ranges allowed
│   └── Service endpoints: AKS subnet access
├── Staging KV (private endpoint)
│   ├── Private IP: 10.2.8.16 (in KV PE subnet)
│   ├── Private DNS: privatelink.vaultcore.azure.net
│   └── VNet integration: Staging and Hub VNets
└── Production KV (private endpoint + HSM)
    ├── Private IP: 10.3.8.16 (in KV PE subnet)
    ├── Private DNS: privatelink.vaultcore.azure.net
    ├── HSM integration: Hardware security module
    └── VNet integration: Production, Hub, and DR VNets
```

### Azure Storage Private Endpoints

#### Storage Account Private Endpoint Strategy
**Multi-Service Private Endpoints**:
- **Blob storage**: For container image layers and application data
- **File storage**: For persistent volume claims and shared storage
- **Table storage**: For application metadata and configuration
- **Queue storage**: For asynchronous processing and messaging

**Storage Private Endpoint Configuration**:
```
Storage Account Private Endpoints:
├── Blob Storage Private Endpoint
│   ├── Service: blob
│   ├── Private IP: 10.3.8.32
│   ├── Private DNS: privatelink.blob.core.windows.net
│   └── Purpose: Container data and backups
├── File Storage Private Endpoint
│   ├── Service: file
│   ├── Private IP: 10.3.8.33
│   ├── Private DNS: privatelink.file.core.windows.net
│   └── Purpose: Kubernetes persistent volumes
├── Table Storage Private Endpoint
│   ├── Service: table
│   ├── Private IP: 10.3.8.34
│   ├── Private DNS: privatelink.table.core.windows.net
│   └── Purpose: Application configuration data
└── Queue Storage Private Endpoint
    ├── Service: queue
    ├── Private IP: 10.3.8.35
    ├── Private DNS: privatelink.queue.core.windows.net
    └── Purpose: Event-driven processing
```

### Database Private Endpoints (if applicable)

#### Azure SQL Database Private Connectivity
**Production Database Configuration**:
- **Azure SQL Database**: Premium tier with private endpoint
- **Private endpoint subnet**: Dedicated /28 for database connectivity
- **Always Encrypted**: Column-level encryption for sensitive data
- **Backup encryption**: Customer-managed keys for backup encryption

**Database Private Endpoint Details**:
```
SQL Database Private Endpoint:
├── Database Server: mycompany-prod-sql.database.windows.net
├── Private IP: 10.3.8.48
├── Private DNS Zone: privatelink.database.windows.net
├── DNS Record: mycompany-prod-sql.privatelink.database.windows.net → 10.3.8.48
├── Connection Security:
│   ├── TLS 1.2 required
│   ├── Azure AD authentication
│   └── Connection encryption: Always Encrypted
└── Network Access:
    ├── Private endpoint only
    ├── No public access
    └── VNet integration: Production and Hub VNets
```

## Private DNS Architecture

### DNS Zone Management Strategy
**Centralized Private DNS**:
- **Hub VNet**: Hosts all private DNS zones
- **Spoke VNet linking**: All spoke VNets linked to private DNS zones
- **Conditional forwarding**: On-premises DNS integration
- **Zone redundancy**: Multi-region DNS for high availability

**Private DNS Zone Structure**:
```
Private DNS Zones (hosted in Hub VNet):
├── privatelink.azurecr.io
│   ├── Linked VNets: Hub, Dev, Staging, Prod
│   └── Records: ACR private endpoints across environments
├── privatelink.vaultcore.azure.net
│   ├── Linked VNets: Hub, Staging, Prod
│   └── Records: Key Vault private endpoints
├── privatelink.blob.core.windows.net
│   ├── Linked VNets: Hub, Dev, Staging, Prod
│   └── Records: Storage blob private endpoints
├── privatelink.file.core.windows.net
│   ├── Linked VNets: Hub, Dev, Staging, Prod
│   └── Records: Storage file private endpoints
├── privatelink.database.windows.net
│   ├── Linked VNets: Hub, Prod
│   └── Records: SQL Database private endpoints
└── privatelink.azmk8s.io
    ├── Linked VNets: Hub, Dev, Staging, Prod
    └── Records: AKS private cluster API endpoints
```

### DNS Resolution Flow
**Private Endpoint DNS Resolution Process**:
1. **Pod queries** for service FQDN (e.g., myacr.azurecr.io)
2. **Azure DNS resolver** processes query within VNet
3. **CNAME resolution** points to privatelink.azurecr.io
4. **Private DNS zone** returns private endpoint IP address
5. **Traffic flows** directly to private endpoint over Azure backbone
6. **No internet exposure** - all communication remains private

## Network Security for Private Endpoints

### Network Security Group (NSG) Rules
**Private Endpoint Subnet NSGs**:
```yaml
# NSG Rules for ACR Private Endpoint Subnet
Inbound Rules:
- Name: Allow-AKS-to-ACR
  Priority: 100
  Source: AKS subnets (10.3.1.0/24, 10.3.2.0/23)
  Destination: ACR PE subnet (10.3.8.0/28)
  Port: 443 (HTTPS)
  Action: Allow

- Name: Allow-Management-to-ACR
  Priority: 110
  Source: Management subnet (10.0.5.0/27)
  Destination: ACR PE subnet (10.3.8.0/28)
  Port: 443 (HTTPS)
  Action: Allow

- Name: Deny-All-Other-Inbound
  Priority: 4096
  Source: Any
  Destination: ACR PE subnet (10.3.8.0/28)
  Port: Any
  Action: Deny

Outbound Rules:
- Name: Allow-to-Azure-Backbone
  Priority: 100
  Source: ACR PE subnet (10.3.8.0/28)
  Destination: Internet (Azure Services)
  Port: 443 (HTTPS)
  Action: Allow

- Name: Deny-All-Other-Outbound
  Priority: 4096
  Source: ACR PE subnet (10.3.8.0/28)
  Destination: Any
  Port: Any
  Action: Deny
```

### Application Security Groups (ASGs)
**ASG-Based Security Rules**:
- **AKS-Nodes ASG**: Contains all AKS node NICs
- **ACR-PrivateEndpoints ASG**: Contains ACR private endpoint NICs
- **KeyVault-PrivateEndpoints ASG**: Contains Key Vault private endpoint NICs
- **Storage-PrivateEndpoints ASG**: Contains storage private endpoint NICs

## Cross-Region Private Connectivity

### Disaster Recovery Private Endpoints
**Multi-Region Strategy**:
- **Primary region**: East US with full private endpoint deployment
- **Secondary region**: West US with disaster recovery private endpoints
- **Cross-region replication**: ACR geo-replication with private endpoints
- **DNS failover**: Automated DNS failover for DR scenarios

**DR Private Endpoint Configuration**:
```
Disaster Recovery Private Endpoints:
├── Primary Region (East US)
│   ├── ACR Primary: 10.3.8.4
│   ├── Key Vault Primary: 10.3.8.16
│   └── Storage Primary: 10.3.8.32-35
├── Secondary Region (West US)
│   ├── ACR Secondary: 10.4.8.4
│   ├── Key Vault Secondary: 10.4.8.16
│   └── Storage Secondary: 10.4.8.32-35
└── Cross-Region Connectivity
    ├── VNet Peering: Primary ↔ Secondary
    ├── Private DNS: Multi-region zone linking
    └── Failover: Automated DNS updates
```

## Visual Guidelines

### Network Topology Layout
- **Hub-and-spoke structure**: Central hub with radiating spoke VNets
- **Private endpoint placement**: Dedicated subnets clearly marked
- **DNS flow visualization**: Arrows showing name resolution paths
- **Security boundaries**: NSG and firewall icons at network boundaries

### Private Endpoint Visualization
- **Service icons**: Azure service icons (ACR, Key Vault, Storage, SQL)
- **Private endpoint indicators**: Lock icons with private IP addresses
- **Network interfaces**: NIC icons showing private endpoint connections
- **DNS integration**: DNS icons with resolution flow arrows

### Connectivity Patterns
- **Private traffic flows**: Green arrows for private connectivity
- **DNS resolution flows**: Blue arrows for name resolution
- **Cross-region connections**: Orange arrows for DR connectivity
- **Management access**: Yellow arrows for administrative access

### Security Indicators
- **Private-only zones**: Shaded areas showing no internet access
- **NSG protection**: Shield icons at subnet boundaries
- **Encryption in transit**: Lock icons on connection lines
- **Audit points**: Eye icons at monitoring and logging points

## Color Coding Strategy
- **Dark Blue**: Hub VNet and shared services
- **Light Blue**: Spoke VNets (Dev, Staging, Prod)
- **Green**: Private endpoints and secure connectivity
- **Red**: Security controls and restrictions
- **Purple**: DNS services and name resolution
- **Orange**: Cross-region and disaster recovery
- **Gray**: Network infrastructure (NSGs, routes, etc.)

## Specific Requirements

1. **Show complete private endpoint topology** across all environments
2. **Highlight DNS resolution flows** for private endpoint names
3. **Illustrate security boundaries** and network isolation
4. **Display cross-region connectivity** for disaster recovery
5. **Include monitoring and audit** touchpoints for compliance
6. **Show traffic flows** and communication patterns

## Expected Output

A comprehensive private endpoint network topology diagram that clearly demonstrates:
- Complete private connectivity strategy without internet exposure
- DNS architecture supporting private endpoint name resolution
- Multi-environment private endpoint deployment patterns
- Security controls and network isolation mechanisms
- Cross-region connectivity for business continuity
- Compliance and audit capabilities for private networking

This diagram should serve as the definitive reference for private endpoint implementation and be suitable for network security reviews and compliance audits.
