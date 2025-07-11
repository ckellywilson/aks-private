# Custom DNS Server and Application Gateway Integration Architecture

## Eraser.io Prompt

**Context**: Generate a comprehensive architecture diagram showing the integration between a custom DNS server (Infoblox), Azure Application Gateway with Web Application Firewall (WAF), and internal nginx-ingress load balancer within the AKS private cluster environment. Show the complete DNS resolution flow, network connectivity, and security boundaries across multiple VNets.

## Architecture Overview

Create a detailed diagram showing the complete DNS and traffic routing architecture with:

### DNS and Traffic Flow Architecture
- **Custom DNS Server (Infoblox)** in dedicated management VNet
- **Azure Application Gateway with WAF** in separate DMZ/gateway VNet
- **Internal nginx-ingress load balancer** within AKS private cluster VNet
- **DNS resolution chain** from external clients through custom DNS to Azure services
- **Network security boundaries** and private endpoint connectivity

### Multi-VNet Network Design
- **Management VNet**: Infoblox DNS servers and administrative services
- **Gateway VNet**: Azure Application Gateway with WAF and public endpoints
- **AKS VNet**: Private AKS cluster with internal nginx-ingress controller
- **VNet peering relationships** and routing configurations
- **Network Security Groups** and traffic filtering rules

## Detailed Network and DNS Architecture

### VNet Architecture and Connectivity

#### Management VNet - Custom DNS Infrastructure
**Infoblox DNS Server Configuration**:
- **Primary DNS Server**: Infoblox appliance with high availability
- **Secondary DNS Server**: Backup Infoblox instance for redundancy
- **DNS zones**: Custom internal zones and external zone delegation
- **Network connectivity**: Private connectivity to all VNets
- **Management access**: Secure administrative access and monitoring

**Management VNet Design**:
```yaml
# Management VNet Configuration
Management VNet (10.1.0.0/16):
├── DNS Subnet (10.1.1.0/24):
│   ├── Infoblox Primary DNS (10.1.1.10)
│   ├── Infoblox Secondary DNS (10.1.1.11)
│   └── DNS Management VM (10.1.1.20)
├── Management Subnet (10.1.2.0/24):
│   ├── Jump Host/Bastion (10.1.2.10)
│   ├── Monitoring Server (10.1.2.20)
│   └── Administrative Tools (10.1.2.30)
└── Private Endpoints Subnet (10.1.3.0/24):
    ├── Key Vault Private Endpoint
    ├── Storage Private Endpoint
    └── Log Analytics Private Endpoint
```

#### Gateway VNet - Application Gateway and WAF
**Azure Application Gateway Configuration**:
- **WAF enabled**: OWASP rule set with custom rules
- **Public IP**: Internet-facing entry point for applications
- **Backend pools**: Internal nginx-ingress load balancer targets
- **Health probes**: Application health monitoring and routing decisions
- **SSL termination**: Certificate management and TLS offloading

**Gateway VNet Design**:
```yaml
# Gateway VNet Configuration
Gateway VNet (10.2.0.0/16):
├── Application Gateway Subnet (10.2.1.0/24):
│   ├── Azure Application Gateway (10.2.1.10)
│   ├── Public IP for App Gateway
│   └── WAF Policy Configuration
├── WAF Subnet (10.2.2.0/24):
│   ├── WAF Log Analytics Integration
│   ├── Security Rule Processing
│   └── Threat Intelligence Feeds
└── Private Endpoints Subnet (10.2.3.0/24):
    ├── ACR Private Endpoint
    ├── Key Vault Private Endpoint
    └── Storage Private Endpoint
```

#### AKS VNet - Private Kubernetes Cluster
**Internal nginx-ingress Configuration**:
- **Internal load balancer**: Azure Internal Load Balancer with private IP
- **Ingress controller**: nginx-ingress deployed as DaemonSet or Deployment
- **Service configuration**: ClusterIP and LoadBalancer services
- **TLS termination**: Certificate management within the cluster
- **Backend applications**: Kubernetes services and pods

**AKS VNet Design**:
```yaml
# AKS VNet Configuration
AKS VNet (10.3.0.0/16):
├── AKS Nodes Subnet (10.3.1.0/24):
│   ├── System Node Pool (10.3.1.10-50)
│   └── User Node Pool (10.3.1.51-200)
├── Pod Subnet (10.3.4.0/22):
│   ├── Application Pods (10.3.4.1-10.3.7.254)
│   └── nginx-ingress Pods
├── Internal Load Balancer Subnet (10.3.2.0/24):
│   ├── nginx-ingress Internal LB (10.3.2.10)
│   ├── Additional Internal Services
│   └── Health Check Endpoints
└── Private Endpoints Subnet (10.3.3.0/24):
    ├── ACR Private Endpoint
    ├── Key Vault Private Endpoint
    └── SQL Database Private Endpoint
```

### DNS Resolution Flow and Configuration

#### Custom DNS Server (Infoblox) Configuration
**DNS Zone Structure**:
- **External zones**: Public DNS delegation for internet-facing domains
- **Internal zones**: Private DNS zones for internal service resolution
- **Conditional forwarding**: Azure Private DNS zone integration
- **DNS policies**: Traffic management and load balancing
- **DNSSEC**: Security validation and cryptographic signatures

**Infoblox DNS Zone Configuration**:
```yaml
# Infoblox DNS Zone Configuration
DNS Zones:
├── External Zone (example.com):
│   ├── A Records:
│   │   ├── app.example.com → App Gateway Public IP
│   │   ├── api.example.com → App Gateway Public IP
│   │   └── www.example.com → App Gateway Public IP
│   ├── CNAME Records:
│   │   ├── portal.example.com → app.example.com
│   │   └── dashboard.example.com → app.example.com
│   └── MX Records for email routing
├── Internal Zone (internal.example.com):
│   ├── A Records:
│   │   ├── nginx-ingress.internal.example.com → 10.3.2.10
│   │   ├── app-service.internal.example.com → 10.3.2.10
│   │   └── api-service.internal.example.com → 10.3.2.10
│   └── PTR Records for reverse DNS
└── Azure Private DNS Integration:
    ├── Conditional Forwarder: privatelink.azurecr.io → 168.63.129.16
    ├── Conditional Forwarder: privatelink.vaultcore.azure.net → 168.63.129.16
    └── Conditional Forwarder: privatelink.database.windows.net → 168.63.129.16
```

#### Azure Application Gateway DNS Integration
**Public DNS Configuration**:
- **Public IP DNS name**: Azure-provided FQDN for Application Gateway
- **Custom domain mapping**: CNAME records pointing to Application Gateway
- **SSL certificate validation**: Domain validation for TLS certificates
- **Health check DNS**: DNS-based health monitoring endpoints

**Application Gateway DNS Settings**:
```yaml
# Application Gateway DNS Configuration
Application Gateway Public Configuration:
├── Public IP: 52.x.x.x (Azure-assigned)
├── Azure DNS Name: myappgw-12345.eastus.cloudapp.azure.com
├── Custom Domain Mapping:
│   ├── app.example.com (CNAME to Azure DNS name)
│   ├── api.example.com (CNAME to Azure DNS name)
│   └── www.example.com (CNAME to Azure DNS name)
└── SSL Certificates:
    ├── Wildcard cert: *.example.com
    ├── Specific cert: app.example.com
    └── API cert: api.example.com
```

### Network Connectivity and Routing

#### VNet Peering Configuration
**Multi-VNet Connectivity**:
- **Management to Gateway VNet**: Bidirectional peering for DNS resolution
- **Gateway to AKS VNet**: Bidirectional peering for application traffic
- **Management to AKS VNet**: Bidirectional peering for administrative access
- **Route table configuration**: Custom routing for traffic optimization
- **Network security groups**: Inter-VNet communication controls

**VNet Peering Architecture**:
```yaml
# VNet Peering Configuration
VNet Peering Relationships:
├── Management VNet ↔ Gateway VNet:
│   ├── Allow virtual network access: Yes
│   ├── Allow forwarded traffic: Yes
│   ├── Allow gateway transit: No
│   └── Use remote gateways: No
├── Gateway VNet ↔ AKS VNet:
│   ├── Allow virtual network access: Yes
│   ├── Allow forwarded traffic: Yes
│   ├── Allow gateway transit: No
│   └── Use remote gateways: No
└── Management VNet ↔ AKS VNet:
    ├── Allow virtual network access: Yes
    ├── Allow forwarded traffic: Yes
    ├── Allow gateway transit: No
    └── Use remote gateways: No
```

#### Route Table Configuration
**Custom Routing Rules**:
- **Default route**: Internet traffic through Application Gateway VNet
- **Internal routes**: Cross-VNet communication optimization
- **DNS traffic routing**: Ensure DNS queries reach Infoblox servers
- **Load balancer routing**: Direct Application Gateway to nginx-ingress
- **Management traffic**: Administrative access routing

### Application Gateway to nginx-ingress Integration

#### Backend Pool Configuration
**Application Gateway Backend Configuration**:
- **Backend pool members**: Internal nginx-ingress load balancer IP
- **Health probe configuration**: HTTP/HTTPS health checks to nginx-ingress
- **Load balancing algorithm**: Round robin or weighted distribution
- **Session affinity**: Cookie-based or IP-based session persistence
- **Connection draining**: Graceful connection handling during maintenance

**Backend Pool Settings**:
```yaml
# Application Gateway Backend Pool Configuration
Backend Pools:
├── nginx-ingress-backend:
│   ├── Backend Type: IP address
│   ├── IP Address: 10.3.2.10 (nginx-ingress Internal LB)
│   ├── Port: 80 (HTTP) / 443 (HTTPS)
│   └── Health Probe: /healthz endpoint
├── Health Probe Configuration:
│   ├── Protocol: HTTP/HTTPS
│   ├── Host: nginx-ingress.internal.example.com
│   ├── Path: /healthz
│   ├── Interval: 30 seconds
│   ├── Timeout: 20 seconds
│   └── Unhealthy threshold: 3
└── Load Balancing Rules:
    ├── HTTP Rule: Port 80 → nginx-ingress:80
    ├── HTTPS Rule: Port 443 → nginx-ingress:443
    └── Session Affinity: ClientIP or Cookie
```

#### nginx-ingress Internal Load Balancer Configuration
**Internal Load Balancer Setup**:
- **Service type**: LoadBalancer with internal annotation
- **Private IP assignment**: Static IP from designated subnet
- **Backend service routing**: Kubernetes service discovery and routing
- **Health check configuration**: Kubernetes readiness and liveness probes
- **TLS termination**: Certificate management within the cluster

**nginx-ingress Service Configuration**:
```yaml
# nginx-ingress Internal Load Balancer Configuration
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "internal-lb-subnet"
    service.beta.kubernetes.io/azure-load-balancer-ipv4: "10.3.2.10"
spec:
  type: LoadBalancer
  loadBalancerIP: 10.3.2.10
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
```

## Traffic Flow and DNS Resolution Process

### External Client to Application Flow

#### Complete Request Flow
1. **Client DNS Query**: External client queries DNS for app.example.com
2. **DNS Resolution**: Infoblox DNS server returns Application Gateway public IP
3. **Application Gateway**: WAF processing and backend routing decision
4. **Internal Routing**: Traffic routed to nginx-ingress internal load balancer
5. **nginx-ingress Processing**: Ingress rules evaluation and backend service routing
6. **Application Response**: Response flows back through the same path

**Traffic Flow Diagram**:
```yaml
# Complete Traffic Flow
External Client Request Flow:
├── 1. DNS Query:
│   ├── Client → Infoblox DNS: app.example.com?
│   └── Infoblox DNS → Client: 52.x.x.x (App Gateway Public IP)
├── 2. HTTPS Request:
│   ├── Client → App Gateway (52.x.x.x:443): HTTPS request
│   ├── WAF Processing: Security rule evaluation
│   └── SSL Termination: Certificate validation and decryption
├── 3. Backend Routing:
│   ├── App Gateway → nginx-ingress (10.3.2.10:443): Internal HTTPS
│   ├── Health Check: /healthz endpoint validation
│   └── Load Balancing: Traffic distribution algorithm
├── 4. Ingress Processing:
│   ├── nginx-ingress → Backend Service: Kubernetes service routing
│   ├── Ingress Rules: Host and path-based routing
│   └── TLS Re-encryption: Internal certificate validation
└── 5. Response Flow:
    ├── Backend Service → nginx-ingress: Application response
    ├── nginx-ingress → App Gateway: Response forwarding
    ├── App Gateway → Client: SSL encryption and response
    └── Monitoring: Log Analytics and metrics collection
```

### DNS Record Requirements

#### Required A Records for Integration
**External DNS Records (Infoblox)**:
- **Application domains**: Point to Application Gateway public IP
- **Administrative domains**: Point to management interfaces
- **Monitoring domains**: Point to observability endpoints
- **API domains**: Point to API gateway interfaces

**Internal DNS Records (Infoblox)**:
- **nginx-ingress endpoints**: Point to internal load balancer IP
- **Kubernetes services**: Point to service cluster IPs
- **Administrative services**: Point to management and monitoring tools

**Complete DNS Record Configuration**:
```yaml
# Required DNS Records Configuration
External A Records (Public):
├── app.example.com → 52.x.x.x (App Gateway Public IP)
├── api.example.com → 52.x.x.x (App Gateway Public IP)
├── www.example.com → 52.x.x.x (App Gateway Public IP)
├── portal.example.com → 52.x.x.x (App Gateway Public IP)
└── admin.example.com → 52.x.x.x (App Gateway Public IP)

Internal A Records (Private):
├── nginx-ingress.internal.example.com → 10.3.2.10
├── app-internal.internal.example.com → 10.3.2.10
├── api-internal.internal.example.com → 10.3.2.10
├── monitoring.internal.example.com → 10.1.2.20
└── dns-admin.internal.example.com → 10.1.1.10

Health Check Records:
├── healthz.app.example.com → 52.x.x.x
├── status.nginx.internal.example.com → 10.3.2.10
└── probe.internal.example.com → 10.3.2.10
```

## Security and Network Controls

### Network Security Groups (NSG) Configuration
**Inter-VNet Security Rules**:
- **Management to Gateway**: Administrative access and DNS resolution
- **Gateway to AKS**: Application traffic and health checks only
- **Management to AKS**: Administrative and monitoring access
- **Internet to Gateway**: HTTPS traffic only through WAF
- **Internal subnet isolation**: Micro-segmentation within VNets

### Web Application Firewall (WAF) Rules
**WAF Protection Layers**:
- **OWASP Core Rule Set**: Protection against common web attacks
- **Custom rules**: Organization-specific threat protection
- **Geo-blocking**: Geographic access restrictions
- **Rate limiting**: DDoS protection and traffic shaping
- **Bot protection**: Automated threat detection and mitigation

## Visual Guidelines

### Network Topology Layout
- **Left side**: External clients and internet connectivity
- **Center-left**: Custom DNS server (Infoblox) in management VNet
- **Center**: Azure Application Gateway with WAF in gateway VNet
- **Center-right**: nginx-ingress load balancer in AKS VNet
- **Right side**: Internal Kubernetes services and applications

### DNS Flow Visualization
- **Blue arrows**: DNS query and response flows
- **Green arrows**: Successful traffic routing and responses
- **Red arrows**: Security filtering and WAF processing
- **Purple arrows**: Internal service discovery and routing

### Security Boundary Indicators
- **Solid boxes**: VNet boundaries and network isolation
- **Dashed boxes**: Subnet boundaries within VNets
- **Shield icons**: WAF and security policy enforcement points
- **Lock icons**: Private endpoints and secure connectivity

### Component Hierarchy
- **Top level**: External clients and public internet
- **Middle level**: DMZ and gateway services (App Gateway, WAF)
- **Bottom level**: Internal services (nginx-ingress, AKS applications)
- **Side panel**: Management services (Infoblox DNS, monitoring)

## Color Coding Strategy
- **Blue**: DNS services and resolution components
- **Green**: Application Gateway and WAF services
- **Orange**: nginx-ingress and load balancing components
- **Purple**: Internal Kubernetes services and applications
- **Red**: Security controls and policy enforcement
- **Gray**: Network infrastructure and connectivity
- **Yellow**: Monitoring and observability components

## Specific Requirements

1. **Show complete DNS resolution flow** from external clients through Infoblox to Azure services
2. **Illustrate VNet connectivity** and peering relationships clearly
3. **Display Application Gateway integration** with nginx-ingress load balancer
4. **Include all required DNS records** for proper connectivity
5. **Show security boundaries** and WAF protection layers
6. **Highlight traffic flow paths** and routing decisions

## Expected Output

A comprehensive DNS and Application Gateway integration architecture diagram that clearly demonstrates:
- Complete multi-VNet network topology with proper connectivity
- DNS resolution flow from Infoblox through Application Gateway to nginx-ingress
- Required A records and DNS configuration for all components
- Security boundaries, WAF protection, and network controls
- Traffic routing and load balancing mechanisms
- Integration points between custom DNS, Azure services, and Kubernetes

This diagram should serve as the definitive reference for DNS and Application Gateway integration and be suitable for network architecture reviews and implementation guidance.
