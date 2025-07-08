# Additional Documentation

This directory contains supplementary documentation for the AKS private cluster deployment.

## 📋 Current Configuration

- **Project**: `aks-private`
- **Primary Environment**: `dev`
- **Region**: `Central US` (`cus`)
- **Instance**: `001`

## 🏷️ Resource Naming Convention

All resources follow Azure best practices:
```
<type>-<workload>-<env>-<region>-<instance>
```

**Examples**:
- Resource Group: `rg-aks-dev-cus-001`
- AKS Cluster: `aks-cluster-dev-cus-001`
- Container Registry: `craksdevcus001`
- VNet: `vnet-aks-dev-cus-001`

## 🗄️ Backend Storage Configuration

Terraform state is stored in:
- **Resource Group**: `rg-terraform-state-dev-cus-001`
- **Storage Account**: `staksdevcus001tfstate`
- **Container**: `terraform-state`
- **State File**: `dev.tfstate`

## 📍 Quick Links

- **Main Documentation**: [`../README.md`](../README.md)
- **Terraform Guide**: [`../infra/tf/README.md`](../infra/tf/README.md)
- **Scripts Documentation**: [`../scripts/README.md`](../scripts/README.md)

## 💡 Additional Resources

For detailed deployment instructions, architecture diagrams, and troubleshooting guides, see the main repository documentation.
