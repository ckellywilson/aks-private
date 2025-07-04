# AKS Private Cluster Documentation

This directory contains documentation for the AKS private cluster deployment.

## Current Configuration

- **Project**: `aks-private`
- **Environment**: `dev`
- **Region**: `Central US` (`cus`)
- **Instance**: `001`

## Resource Naming Convention

All resources follow Azure best practices:
```
<type>-<workload>-<env>-<region>-<instance>
```

Examples:
- Resource Group: `rg-aks-dev-cus-001`
- AKS Cluster: `aks-cluster-dev-cus-001`
- Container Registry: `craksdevcus001`
- VNet: `vnet-aks-dev-cus-001`

## Deployment

Navigate to `/infra/tf/` directory for Terraform configuration and deployment instructions.

## Backend Storage

Backend state is stored in:
- Resource Group: `rg-terraform-state-dev-cus-001`
- Storage Account: `staksdevcus001tfstate`
- Container: `terraform-state`
- State File: `dev.tfstate`
