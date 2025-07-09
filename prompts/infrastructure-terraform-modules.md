# Terraform Module Development and Organization

## Context
Developing, organizing, and maintaining Terraform modules for a private AKS cluster project. The modules should be reusable, well-structured, and follow best practices for infrastructure-as-code.

## Task
Create, refactor, and optimize Terraform modules for AKS infrastructure including networking, identity, storage, monitoring, and security components.

## Requirements
- Modular architecture with clear separation of concerns
- Reusable modules across multiple environments
- Proper variable validation and type constraints
- Comprehensive outputs for module consumers
- Documentation and examples for each module
- Testing and validation procedures
- Version management and semantic versioning
- Security best practices and compliance

## Current Module Structure
```
infra/tf/modules/
├── aks/           # AKS cluster configuration
├── identity/      # Managed identities and RBAC
├── networking/    # VNet, subnets, NSGs, Bastion
├── monitoring/    # Log Analytics, Application Insights
└── registry/      # Azure Container Registry
```

## Module Design Patterns
- **Input Variables**: Clear naming, validation, and documentation
- **Local Values**: Computed values and resource naming
- **Data Sources**: External resource references
- **Resources**: Azure resource definitions
- **Outputs**: Values for module consumers
- **Dependencies**: Module interdependencies and ordering

## Common Module Requirements
- Consistent tagging strategy across all resources
- Environment-specific configuration support
- Security hardening and compliance controls
- Cost optimization and resource sizing
- Monitoring and alerting integration
- Backup and disaster recovery considerations

## Best Practices to Implement
- Use semantic versioning for module releases
- Implement proper variable validation with descriptions
- Create comprehensive output values
- Document module usage with examples
- Use locals for computed values and naming conventions
- Implement conditional resource creation
- Follow Azure naming conventions
- Use data sources for external references

## Testing and Validation
- Unit tests with Terraform validate
- Integration tests with real Azure resources
- Security scanning with Checkov or similar tools
- Documentation generation and updates
- Example configurations and usage patterns

## Expected Outcomes
- Well-structured, reusable Terraform modules
- Consistent resource naming and tagging
- Comprehensive documentation and examples
- Automated testing and validation procedures
- Version management and release processes
- Security and compliance controls
- Performance optimization and cost management

## Sample Module Structure
```hcl
# variables.tf
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) <= 63
    error_message = "Cluster name must be 63 characters or less."
  }
}

# main.tf
locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "aks"
  })
}

# outputs.tf
output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}
```

## Additional Context
- Using Azure provider for Terraform
- Following HashiCorp module structure conventions
- Integration with Azure DevOps or GitHub Actions
- Multiple environment deployment (dev, staging, prod)
- Compliance with Azure security benchmarks
