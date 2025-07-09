# Terraform Backend Storage Account Network Configuration

## Context
Working with Azure Storage account used for Terraform state management in a private AKS cluster project. The storage account needs proper network configuration to allow secure access from GitHub Actions while maintaining security.

## Task
Configure Azure Storage account network rules and VNet integration for Terraform backend access, troubleshoot 403 AuthorizationFailure errors, and implement secure access patterns.

## Requirements
- Storage account: `staksdevcus001tfstate` in resource group `rg-terraform-state-dev-cus-001`
- Use VNet integration instead of IP-based rules for better reliability
- Maintain security with `defaultAction: "Deny"`
- Support GitHub Actions with managed identity authentication
- Enable service endpoints for Azure Storage
- Configure appropriate network security groups

## Current Configuration
```json
{
  "defaultAction": "Deny",
  "bypass": "AzureServices", 
  "ipRules": [],
  "virtualNetworkRules": []
}
```

## Common Issues
- GitHub Actions getting 403 AuthorizationFailure errors
- `AzureServices` bypass not working for GitHub Actions with OIDC
- IP-based rules being too brittle due to changing GitHub IP ranges
- Network connectivity issues from VNet resources

## Sample Network Architecture
```
VNet (10.250.0.0/16)
├── Terraform Backend Subnet (10.250.1.0/24)
│   ├── Service Endpoint: Microsoft.Storage
│   ├── GitHub Actions Container Instances
│   └── CI/CD Runners
└── Storage Account VNet Rules
    └── Allow access from subnet 10.250.1.0/24
```

## Expected Solutions
- VNet configuration scripts for automated setup
- GitHub Actions workflow modifications for VNet integration
- Troubleshooting guides for network connectivity
- Security best practices for storage account access
- Alternative approaches (Container Instances, Self-hosted runners)

## Additional Context
- Using Azure CLI and Terraform for infrastructure management
- Bootstrap script creates storage account outside of main Terraform deployment
- Managed identity `id-terraform-dev-cus-001` is used for authentication
- Storage account has security features: no shared key access, HTTPS only, TLS 1.2+
