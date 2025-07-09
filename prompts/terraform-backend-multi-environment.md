# Multi-Environment Terraform Backend with GitHub Actions

## Context
Implementing a comprehensive multi-environment Terraform backend strategy with different security models for development (public access) vs staging/production (private access with VNet integration). The solution includes Azure Container Registry, self-hosted GitHub Actions runners, and environment-specific deployment workflows.

## Task
Design and implement a complete infrastructure-as-code solution for Terraform backend with Azure Storage, GitHub Actions workflows, and container-based deployment across dev, stage, and prod environments with appropriate security controls for each.

## Architecture Overview

### Development Environment (Public Access)
```
Development Environment
├── Azure Storage Account (Public Access)
│   ├── Allow public blob access: true
│   ├── Network default action: Allow
│   └── Terraform state container
├── GitHub Actions (Hosted Runners)
│   ├── Standard GitHub-hosted runners
│   ├── Public internet connectivity
│   └── Direct access to storage account
└── Container Instance (Self-hosted Runner)
    ├── Public subnet deployment
    ├── Docker container with Terraform tools
    └── Direct Azure Storage access
```

### Staging/Production Environment (Private Access)
```
Staging/Production Environment
├── Virtual Network (10.100.0.0/16)
│   ├── Private Subnet (10.100.1.0/24)
│   │   ├── Self-hosted runner container instances
│   │   └── Service endpoints: Storage, ACR
│   └── Private Endpoints Subnet (10.100.2.0/24)
│       ├── Storage account private endpoint
│       └── ACR private endpoint
├── Azure Container Registry (Private)
│   ├── Public network access: Disabled
│   ├── Private endpoint enabled
│   ├── VNet integration
│   └── Custom runner images
├── Azure Storage Account (Private)
│   ├── Public blob access: false
│   ├── Network default action: Deny
│   ├── VNet rules for private subnet
│   └── Private endpoint enabled
└── GitHub Actions Workflows
    ├── Container build and push to ACR
    ├── Self-hosted runner deployment
    └── Terraform plan/apply execution
```

## Implementation Requirements

### 1. Storage Account Configuration

#### Development Environment
```bash
# Dev storage with controlled public access (best practice: still restrict by IP)
az storage account create \
  --name "staksdevevus001tfstate" \
  --resource-group "rg-terraform-state-dev-eus-001" \
  --location "East US" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --https-only true \
  --min-tls-version TLS1_2 \
  --default-action Deny \
  --bypass AzureServices

# Add GitHub Actions IP ranges for dev (more secure than full public access)
az storage account network-rule add \
  --account-name "staksdevevus001tfstate" \
  --ip-address "20.1.128.0/17" \
  --ip-address "20.20.140.0/24" \
  --ip-address "20.81.0.0/17"
```

#### Staging/Production Environment
```bash
# Stage/Prod storage with enhanced security features
az storage account create \
  --name "staksstageeus001tfstate" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --location "East US" \
  --sku Standard_ZRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --https-only true \
  --min-tls-version TLS1_2 \
  --default-action Deny \
  --bypass AzureServices \
  --enable-hierarchical-namespace false \
  --enable-sftp false \
  --enable-local-user false

# Enable advanced security features
az storage account blob-service-properties update \
  --account-name "staksstageeus001tfstate" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7

# Enable diagnostic logging
az monitor diagnostic-settings create \
  --name "storage-security-logs" \
  --resource "/subscriptions/.../storageAccounts/staksstageeus001tfstate" \
  --logs '[
    {
      "category": "StorageRead",
      "enabled": true,
      "retentionPolicy": {"enabled": true, "days": 90}
    },
    {
      "category": "StorageWrite", 
      "enabled": true,
      "retentionPolicy": {"enabled": true, "days": 90}
    }
  ]' \
  --workspace "/subscriptions/.../workspaces/log-analytics-security"

# Add VNet rules for private subnet access
az storage account network-rule add \
  --account-name "staksstageeus001tfstate" \
  --subnet "/subscriptions/.../virtualNetworks/vnet-terraform-stage/subnets/snet-private"
```

### 2. Azure Container Registry Setup

#### Stage/Production Only
```bash
# Create private ACR for custom runner images
az acr create \
  --name "acrterraformstageeus001" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --location "East US" \
  --sku Premium \
  --public-network-enabled false

# Enable private endpoint
az network private-endpoint create \
  --name "pe-acr-terraform-stage" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --subnet "/subscriptions/.../virtualNetworks/vnet-terraform-stage/subnets/snet-private-endpoints" \
  --private-connection-resource-id "/subscriptions/.../registries/acrterraformstageeus001" \
  --group-id registry \
  --connection-name "acr-connection"
```

### 3. Virtual Network Configuration

#### Stage/Production VNet Setup
```bash
# Create VNet for private environment
az network vnet create \
  --name "vnet-terraform-stage" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --location "East US" \
  --address-prefixes "10.100.0.0/16"

# Private subnet for self-hosted runners
az network vnet subnet create \
  --name "snet-private" \
  --vnet-name "vnet-terraform-stage" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --address-prefixes "10.100.1.0/24" \
  --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry"

# Private endpoints subnet
az network vnet subnet create \
  --name "snet-private-endpoints" \
  --vnet-name "vnet-terraform-stage" \
  --resource-group "rg-terraform-state-stage-eus-001" \
  --address-prefixes "10.100.2.0/24"
```

### 4. Self-Hosted Runner Container Images

#### Dockerfile for Terraform Runner
```dockerfile
# Multi-stage build for security and size optimization
FROM ubuntu:22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ARG TERRAFORM_VERSION=1.7.0
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x terraform

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl and helm
RUN curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl" \
    && chmod +x kubectl
RUN curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz \
    && chmod +x linux-amd64/helm

# Production stage
FROM ghcr.io/actions/actions-runner:latest

# Create non-root user for security
USER root
RUN groupadd -r terraform && useradd -r -g terraform -s /bin/bash terraform

# Copy binaries from builder stage
COPY --from=builder /terraform /usr/local/bin/terraform
COPY --from=builder /opt/az /opt/az
COPY --from=builder /kubectl /usr/local/bin/kubectl
COPY --from=builder /linux-amd64/helm /usr/local/bin/helm

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set up symlinks for Azure CLI
RUN ln -s /opt/az/bin/az /usr/local/bin/az

# Security hardening
RUN chmod -R 755 /usr/local/bin \
    && chown -R root:root /usr/local/bin

# Create secure working directory
RUN mkdir -p /home/terraform && chown terraform:terraform /home/terraform

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD terraform version && az version --output none

# Set up runner user with restricted permissions
USER runner
WORKDIR /home/runner

# Labels for metadata
LABEL org.opencontainers.image.title="Terraform GitHub Actions Runner"
LABEL org.opencontainers.image.description="Secure self-hosted runner for Terraform deployments"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Organization"

# Entry point script
COPY --chown=runner:runner entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

### 5. GitHub Actions Workflows

#### Development Environment Workflow
```yaml
# .github/workflows/terraform-dev.yml
name: 'Terraform Dev Deployment'

on:
  push:
    branches: [ develop ]
  pull_request:
    branches: [ develop ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read
  pull-requests: write  # For PR comments
  security-events: write  # For security scanning

env:
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
  ARM_SKIP_PROVIDER_REGISTRATION: true

jobs:
  terraform-dev:
    name: 'Terraform Dev'
    runs-on: ubuntu-latest
    environment: dev
    concurrency:
      group: terraform-dev-${{ github.ref }}
      cancel-in-progress: false  # Don't cancel infrastructure changes
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Configure Git (Security)
      run: |
        git config --global user.email "actions@github.com"
        git config --global user.name "GitHub Actions"
        git config --global init.defaultBranch main

    - name: Azure Login
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: "1.7.0"
        terraform_wrapper: false  # For better output handling

    - name: Security Scan - Terraform
      uses: bridgecrewio/checkov-action@master
      with:
        directory: infra/tf
        framework: terraform
        output_format: sarif
        output_file_path: reports/checkov.sarif

    - name: Upload Security Scan Results
      uses: github/codeql-action/upload-sarif@v3
      if: success() || failure()
      with:
        sarif_file: reports/checkov.sarif

    - name: Cache Terraform
      uses: actions/cache@v4
      with:
        path: |
          ~/.terraform.d/plugin-cache
          **/.terraform
        key: terraform-dev-${{ hashFiles('**/.terraform.lock.hcl') }}
        restore-keys: terraform-dev-

    - name: Terraform Init (Dev)
      working-directory: infra/tf
      run: |
        cp environments/dev/backend.tf .
        terraform init -input=false

    - name: Terraform Validate
      working-directory: infra/tf
      run: terraform validate

    - name: Terraform Plan (Dev)
      working-directory: infra/tf
      run: |
        terraform plan \
          -var-file="environments/dev/terraform.tfvars" \
          -out=dev.tfplan \
          -input=false

    - name: Comment PR with Plan
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('infra/tf/dev.tfplan.txt', 'utf8');
          const body = `## Terraform Plan (Dev)\n\`\`\`\n${plan}\n\`\`\``;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: body
          });

    - name: Terraform Apply (Dev)
      if: github.ref == 'refs/heads/develop' && github.event_name != 'pull_request'
      working-directory: infra/tf
      run: terraform apply dev.tfplan

    - name: Post-deployment Validation
      if: github.ref == 'refs/heads/develop' && github.event_name != 'pull_request'
      run: |
        # Validate deployed resources
        az aks check-acr --name ${{ vars.AKS_CLUSTER_NAME }} --resource-group ${{ vars.RESOURCE_GROUP_NAME }} --acr ${{ vars.ACR_NAME }}
```

#### Stage/Production Container Build Workflow
```yaml
# .github/workflows/container-build-stage-prod.yml
name: 'Container Build for Stage/Prod'

on:
  push:
    branches: [ main, release/* ]
    paths: [ 'docker/**', '.github/workflows/container-build-stage-prod.yml' ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  build-runner-image:
    name: 'Build Self-Hosted Runner Image'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Login to ACR
      run: |
        az acr login --name acrterraformstageeus001

    - name: Build and Push Runner Image
      run: |
        docker build -t acrterraformstageeus001.azurecr.io/terraform-runner:${{ github.sha }} \
                    -t acrterraformstageeus001.azurecr.io/terraform-runner:latest \
                    ./docker/terraform-runner/
        
        docker push acrterraformstageeus001.azurecr.io/terraform-runner:${{ github.sha }}
        docker push acrterraformstageeus001.azurecr.io/terraform-runner:latest
```

#### Stage/Production Deployment Workflow
```yaml
# .github/workflows/terraform-stage-prod.yml
name: 'Terraform Stage/Prod Deployment'

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'stage'
        type: choice
        options:
        - stage
        - prod

permissions:
  id-token: write
  contents: read

jobs:
  terraform-private:
    name: 'Terraform Private Environment'
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'stage' }}
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Deploy Private Self-Hosted Runner
      run: |
        ENV="${{ github.event.inputs.environment || 'stage' }}"
        
        # Create container instance in private VNet
        az container create \
          --resource-group "rg-terraform-state-${ENV}-eus-001" \
          --name "github-runner-${ENV}-${{ github.run_id }}" \
          --image "acrterraformstageeus001.azurecr.io/terraform-runner:latest" \
          --subnet "/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/rg-terraform-state-${ENV}-eus-001/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private" \
          --environment-variables \
            GITHUB_TOKEN="${{ secrets.GH_PAT }}" \
            GITHUB_REPOSITORY="${{ github.repository }}" \
            RUNNER_NAME="${ENV}-runner-${{ github.run_id }}" \
            ENVIRONMENT="${ENV}" \
          --assign-identity "${{ secrets.AZURE_CLIENT_ID }}" \
          --registry-login-server "acrterraformstageeus001.azurecr.io" \
          --restart-policy Never

    - name: Wait for Runner Registration
      run: |
        echo "Waiting for self-hosted runner to register..."
        sleep 60
        
        # Verify runner is available
        for i in {1..10}; do
          if curl -H "Authorization: token ${{ secrets.GH_PAT }}" \
                  "https://api.github.com/repos/${{ github.repository }}/actions/runners" \
                  | jq -r '.runners[].name' | grep -q "${ENV}-runner-${{ github.run_id }}"; then
            echo "Runner registered successfully"
            break
          fi
          echo "Waiting for runner registration... (attempt $i)"
          sleep 30
        done

  terraform-deploy:
    name: 'Terraform Deploy on Self-Hosted'
    needs: terraform-private
    runs-on: [ self-hosted, '${{ github.event.inputs.environment || 'stage' }}-runner-${{ github.run_id }}' ]
    environment: ${{ github.event.inputs.environment || 'stage' }}
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Environment
      run: |
        ENV="${{ github.event.inputs.environment || 'stage' }}"
        echo "ENVIRONMENT=${ENV}" >> $GITHUB_ENV

    - name: Terraform Init
      working-directory: infra/tf
      run: |
        cp "environments/${ENVIRONMENT}/backend.tf" .
        terraform init

    - name: Terraform Plan
      working-directory: infra/tf
      run: |
        terraform plan \
          -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
          -out="${ENVIRONMENT}.tfplan"

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      working-directory: infra/tf
      run: |
        terraform apply "${ENVIRONMENT}.tfplan"

    - name: Cleanup
      if: always()
      run: |
        # Self-cleanup - runner will terminate after job
        echo "Job completed, runner will terminate"

  cleanup-runner:
    name: 'Cleanup Runner Resources'
    needs: [ terraform-private, terraform-deploy ]
    if: always()
    runs-on: ubuntu-latest
    
    steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    - name: Remove Container Instance
      run: |
        ENV="${{ github.event.inputs.environment || 'stage' }}"
        az container delete \
          --resource-group "rg-terraform-state-${ENV}-eus-001" \
          --name "github-runner-${ENV}-${{ github.run_id }}" \
          --yes || true
```

### 6. Environment-Specific Configuration

#### Bootstrap Script Enhancement
```bash
# Enhanced bootstrap for multi-environment setup
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Public access allowed
        echo "Configuring development environment with public access..."
        configure_public_storage "$ENV"
        setup_public_container_instances "$ENV"
    else
        # Stage/Prod: Private access only
        echo "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_private_container_instances "$ENV"
    fi
}
```

## Infrastructure-as-Code Best Practices

### 1. Terraform State Management
```hcl
# backend.tf - Enhanced backend configuration
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.84.0"
    }
    azuread = {
      source  = "hashicorp/azuread" 
      version = "~> 2.46.0"
    }
  }

  backend "azurerm" {
    # Use environment-specific values
    use_oidc                 = true
    use_azuread_auth         = true
    storage_use_azuread      = true
    skip_provider_registration = true
  }
}

# Configure providers with security features
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    storage {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
  }
  
  # Environment-specific configuration
  skip_provider_registration = true
  use_oidc                  = true
}
```

### 2. Resource Naming and Tagging Strategy
```hcl
# locals.tf - Consistent naming and tagging
locals {
  # Environment-aware naming
  name_prefix = "${var.environment}-${var.location_short}"
  
  # Comprehensive tagging strategy
  common_tags = {
    Environment   = var.environment
    Project       = "aks-private"
    ManagedBy     = "Terraform"
    Owner         = var.owner_email
    CostCenter    = var.cost_center
    Purpose       = "Infrastructure Backend"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    GitRepo       = var.git_repository
    GitCommit     = var.git_commit_sha
    TerraformPath = path.module
    
    # Security and compliance tags
    DataClassification = var.data_classification
    ComplianceScope   = var.compliance_scope
    BackupRequired    = "true"
    MonitoringEnabled = "true"
  }
  
  # Security configurations per environment
  security_config = {
    dev = {
      network_access_default = "Deny"
      allow_public_access    = false
      log_retention_days     = 30
      backup_retention_days  = 7
    }
    stage = {
      network_access_default = "Deny"
      allow_public_access    = false
      log_retention_days     = 90
      backup_retention_days  = 30
    }
    prod = {
      network_access_default = "Deny"
      allow_public_access    = false
      log_retention_days     = 365
      backup_retention_days  = 90
    }
  }
}
```

### 3. Environment-Specific Variable Validation
```hcl
# variables.tf - Enhanced validation
variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  
  validation {
    condition = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "ZRS"
  
  validation {
    condition = contains(["LRS", "ZRS", "GRS", "GZRS"], var.storage_account_replication)
    error_message = "Storage replication must be LRS, ZRS, GRS, or GZRS."
  }
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for storage account access"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for ip in var.allowed_ip_ranges : can(cidrhost(ip, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}
```

## Security Considerations

### Development Environment
- Public storage access for simplified development
- Standard GitHub-hosted runners
- Managed identity authentication only
- Minimal network restrictions

### Stage/Production Environment
- Zero public access to storage and registry
- Private VNet with service endpoints and private endpoints
- Private endpoints for all critical services
- Self-hosted runners in controlled environment
- Network security groups with restrictive rules
- Container image scanning before deployment
- Advanced threat protection enabled
- Immutable infrastructure patterns
- Zero-trust network architecture

## Monitoring and Observability

### 1. Infrastructure Monitoring
```bash
# Enable monitoring for all resources
az monitor log-analytics workspace create \
  --resource-group "rg-terraform-state-${ENV}-eus-001" \
  --workspace-name "law-terraform-${ENV}-eus-001" \
  --location "East US" \
  --sku PerGB2018

# Configure diagnostic settings for storage
az monitor diagnostic-settings create \
  --name "terraform-backend-diagnostics" \
  --resource "/subscriptions/.../storageAccounts/staks${ENV}eus001tfstate" \
  --workspace "/subscriptions/.../workspaces/law-terraform-${ENV}-eus-001" \
  --logs '[
    {"category": "StorageRead", "enabled": true},
    {"category": "StorageWrite", "enabled": true},
    {"category": "StorageDelete", "enabled": true}
  ]' \
  --metrics '[
    {"category": "Transaction", "enabled": true},
    {"category": "Capacity", "enabled": true}
  ]'

# Set up alerts for suspicious activity
az monitor metrics alert create \
  --name "terraform-backend-unauthorized-access" \
  --resource-group "rg-terraform-state-${ENV}-eus-001" \
  --scopes "/subscriptions/.../storageAccounts/staks${ENV}eus001tfstate" \
  --condition "count 'Microsoft.Storage/storageAccounts' 'Transactions' 'ResponseType' = 'ClientOtherError' aggregation Total total 5 PT5M" \
  --description "Alert on unauthorized access attempts to Terraform backend storage"
```

### 2. GitHub Actions Monitoring
```yaml
# Add to workflows for observability
- name: Workflow Telemetry
  run: |
    echo "::notice title=Deployment Started::Environment: ${{ env.ENVIRONMENT }}"
    echo "::set-output name=start-time::$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    # Send metrics to Azure Monitor (if configured)
    az rest \
      --method POST \
      --url "https://management.azure.com/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/rg-monitoring/providers/Microsoft.Insights/metrics" \
      --body '{
        "time": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
        "data": {
          "baseData": {
            "metric": "deployment.started",
            "namespace": "GitHubActions/Terraform",
            "dimNames": ["environment", "repository"],
            "series": [{
              "dimValues": ["'${{ env.ENVIRONMENT }}'", "'${{ github.repository }}'"],
              "sum": 1,
              "count": 1
            }]
          }
        }
      }'

- name: Post-Deployment Monitoring Setup
  if: success()
  run: |
    # Configure monitoring for deployed resources
    RESOURCE_IDS=$(terraform output -json resource_ids)
    
    for resource_id in $(echo $RESOURCE_IDS | jq -r '.[]'); do
      az monitor diagnostic-settings create \
        --name "auto-diagnostics" \
        --resource "$resource_id" \
        --workspace "${{ vars.LOG_ANALYTICS_WORKSPACE_ID }}" \
        --logs '[{"category": "AllLogs", "enabled": true}]' \
        --metrics '[{"category": "AllMetrics", "enabled": true}]' || true
    done
```

## Cost Optimization Strategies

### 1. Environment-Specific Sizing
```hcl
# variables.tf - Cost-optimized configurations
locals {
  environment_config = {
    dev = {
      storage_tier = "Hot"
      storage_replication = "LRS"
      container_instance_cpu = 1
      container_instance_memory = 1.5
      log_retention_days = 30
    }
    stage = {
      storage_tier = "Hot" 
      storage_replication = "ZRS"
      container_instance_cpu = 2
      container_instance_memory = 4
      log_retention_days = 90
    }
    prod = {
      storage_tier = "Hot"
      storage_replication = "GZRS"
      container_instance_cpu = 4
      container_instance_memory = 8
      log_retention_days = 365
    }
  }
}
```

### 2. Automated Resource Cleanup
```yaml
# .github/workflows/cleanup-resources.yml
name: 'Cleanup Orphaned Resources'

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
    - name: Cleanup Orphaned Container Instances
      run: |
        # Find and delete container instances older than 24 hours
        CUTOFF_TIME=$(date -d '24 hours ago' --iso-8601)
        
        az container list \
          --query "[?creationTime<'$CUTOFF_TIME' && contains(name, 'github-runner')].{name:name, resourceGroup:resourceGroup}" \
          --output tsv | \
        while read name rg; do
          echo "Deleting orphaned container: $name"
          az container delete --name "$name" --resource-group "$rg" --yes
        done
    
    - name: Cleanup Old Terraform Plans
      run: |
        # Clean up old terraform plan artifacts
        find . -name "*.tfplan" -mtime +7 -delete
        find . -name ".terraform" -type d -mtime +7 -exec rm -rf {} +
```

## Expected Deliverables
- Multi-environment bootstrap script with security controls
- Custom Dockerfile for Terraform runners
- GitHub Actions workflows for each environment type
- VNet and private endpoint configurations
- Documentation for environment-specific deployment procedures
- Monitoring and alerting setup for private environments
- Disaster recovery procedures for each environment

## Testing and Validation
- Unit tests for Terraform configurations
- Integration tests for network connectivity
- Security compliance validation
- Performance testing for container deployments
- Automated validation of private endpoint connectivity
- Regular security assessments and penetration testing

## Additional Context
- Support for GitOps workflows with ArgoCD/Flux
- Integration with Azure Monitor for comprehensive logging
- Cost optimization strategies for container instances
- Backup and disaster recovery procedures
- Compliance with organizational security policies
- Integration with existing CI/CD toolchains
