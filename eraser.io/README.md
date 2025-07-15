# Eraser.io Azure Architecture Diagram Prompts

This folder contains carefully crafted prompts for generating Azure Architecture Diagrams using the generative AI capabilities of [Eraser.io](https://eraser.io).

## Overview

Eraser.io is a powerful diagramming tool that uses generative AI to create infrastructure diagrams from natural language descriptions. These prompts are specifically designed to generate comprehensive Azure architecture diagrams for our AKS Private Cluster project.

## How to Use

1. **Visit [Eraser.io](https://eraser.io)**
2. **Choose a prompt** from the files in this directory
3. **Copy the entire prompt** (including context and requirements)
4. **Paste into Eraser.io's AI prompt interface**
5. **Generate and refine** the diagram as needed
6. **Export** in your preferred format (PNG, SVG, PDF, etc.)

## Available Diagram Prompts

### Core Architecture Diagrams
- [`01-aks-private-cluster-overview.md`](./01-aks-private-cluster-overview.md) - Complete AKS private cluster architecture
- [`02-multi-environment-overview.md`](./02-multi-environment-overview.md) - Dev/Staging/Prod environment comparison
- [`03-networking-architecture.md`](./03-networking-architecture.md) - Detailed networking and security setup

### Infrastructure & Operations
- [`04-terraform-backend-architecture.md`](./04-terraform-backend-architecture.md) - Terraform state management infrastructure
- [`05-github-actions-infrastructure-deployment.md`](./05-github-actions-infrastructure-deployment.md) - GitHub Actions infrastructure deployment workflows
- [`06-monitoring-and-observability.md`](./06-monitoring-and-observability.md) - Monitoring stack architecture

### Security & Compliance
- [`07-security-architecture.md`](./07-security-architecture.md) - Security controls and data flow
- [`08-private-endpoints-topology.md`](./08-private-endpoints-topology.md) - Private connectivity architecture

### Detailed Component Views
- [`09-aks-cluster-internals.md`](./09-aks-cluster-internals.md) - Inside the AKS cluster components
- [`10-disaster-recovery-architecture.md`](./10-disaster-recovery-architecture.md) - Multi-region DR and business continuity

### Custom DNS and Application Gateway Integration
- [`11-custom-dns-application-gateway-architecture.md`](./11-custom-dns-application-gateway-architecture.md) - Infoblox DNS with Azure Application Gateway integration
- [`12-dns-traffic-flow-sequence-diagram.md`](./12-dns-traffic-flow-sequence-diagram.md) - Detailed DNS resolution and traffic flow sequences

### High-Level Architecture Overview
- [`13-high-level-aks-architecture-overview.md`](./13-high-level-aks-architecture-overview.md) - Executive-level overview with primary components: Private AKS cluster (2 system + 2 user node pools), nginx-ingress load balancer, ACR with private link, Application Gateway, Infoblox DNS, and GitHub Actions CI/CD. Includes specific IP addresses and DNS A records.

### Simplified Architecture
- [`14-simplified-aks-private-cluster.md`](./14-simplified-aks-private-cluster.md) - Streamlined single application landing zone architecture focused on production only. Consolidated VNet design without hub-spoke complexity, core components, and simplified network topology for straightforward implementation.

## Best Practices for Eraser.io

### Prompt Structure
Each prompt follows this structure:
1. **Context** - Background about the project
2. **Architecture Overview** - High-level description
3. **Detailed Components** - Specific Azure services and configurations
4. **Relationships** - How components connect and interact
5. **Security Requirements** - Private networking and access controls
6. **Visual Guidelines** - Styling and layout preferences

### Tips for Better Results
- **Be Specific**: Include exact Azure service names and SKUs
- **Use Azure Icons**: Reference official Azure service icons when possible  
- **Define Relationships**: Clearly describe connections between components
- **Include Security**: Highlight private endpoints, NSGs, and security boundaries
- **Specify Layout**: Suggest logical grouping and flow direction

### Iterating on Diagrams
- Start with the overview diagrams
- Use detailed prompts for specific areas that need clarification
- Combine multiple diagrams for comprehensive documentation
- Export in multiple formats for different use cases

## Project Context

This AKS Private Cluster project includes:
- **Multi-environment setup** (dev, staging, production)
- **Private AKS clusters** with secure networking
- **Azure Container Registry** with private endpoints
- **Terraform-based infrastructure** as code
- **GitHub Actions CI/CD** pipelines
- **Comprehensive monitoring** and observability
- **Enterprise security** controls and compliance

## Diagram Export Formats

Eraser.io supports multiple export formats:
- **PNG** - For documentation and presentations
- **SVG** - For scalable web graphics
- **PDF** - For formal documentation
- **JSON** - For programmatic access
- **Mermaid** - For integration with markdown docs

## Contributing

When adding new prompts:
1. Follow the established naming convention (`##-descriptive-name.md`)
2. Include comprehensive context and requirements
3. Test the prompt in Eraser.io before committing
4. Update this README with the new prompt description
5. Consider cross-references to related diagrams

## Support

For issues with:
- **Prompts**: Create an issue in this repository
- **Eraser.io platform**: Visit [Eraser.io support](https://eraser.io/support)
- **Azure architecture**: Refer to [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
