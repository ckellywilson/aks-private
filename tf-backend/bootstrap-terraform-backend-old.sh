#!/bin/bash

# Multi-Environment Terraform Backend Bootstrap Script
# This script creates Azure Storage accounts and supporting infrastructure
# for Terraform backends across dev, staging, and production environments
# with different security models per environment

set -e

# Configuration
LOCATION="East US"
LOCATION_SHORT="eus"
SUBSCRIPTION_ID=""
TENANT_ID=""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat <<EOF
Usage: $0 <environment> [options]

Bootstrap Terraform backend infrastructure for specified environment.

Arguments:
  environment    Target environment (dev, staging, prod)

Options:
  -s, --subscription-id    Azure subscription ID
  -t, --tenant-id         Azure tenant ID
  -r, --resource-group     Resource group name (optional)
  -l, --location          Azure location (default: East US)
  -h, --help              Show this help message

Examples:
  $0 dev -s 12345678-1234-1234-1234-123456789012
  $0 staging -s 12345678-1234-1234-1234-123456789012 -t 87654321-4321-4321-4321-210987654321
  $0 prod -s 12345678-1234-1234-1234-123456789012 -r custom-rg-name
  -l, --location          Azure region (default: East US)
  -h, --help              Show this help message
  --skip-vnet             Skip VNet creation (dev environment)
  --dry-run               Show what would be created without executing

Examples:
  # Bootstrap dev environment
  $0 dev --subscription-id 12345678-1234-1234-1234-123456789012

  # Bootstrap staging with custom location
  $0 staging --subscription-id 12345678-1234-1234-1234-123456789012 --location "Central US"

  # Bootstrap production (full private setup)
  $0 prod --subscription-id 12345678-1234-1234-1234-123456789012
EOF
}

# Parse command line arguments
ENVIRONMENT=""
SKIP_VNET=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -t|--tenant-id)
            TENANT_ID="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        --skip-vnet)
            SKIP_VNET=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        dev|staging|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        *)
            log_error "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$ENVIRONMENT" ]; then
    log_error "Environment is required"
    usage
    exit 1
fi

if [ -z "$SUBSCRIPTION_ID" ]; then
    log_error "Subscription ID is required"
    usage
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod"
    exit 1
fi

# Set location short code
case $LOCATION in
    "East US") LOCATION_SHORT="eus" ;;
    "Central US") LOCATION_SHORT="cus" ;;
    "West US") LOCATION_SHORT="wus" ;;
    "West US 2") LOCATION_SHORT="wus2" ;;
    *) 
        log_warning "Unknown location, using 'unk' as short code"
        LOCATION_SHORT="unk"
        ;;
esac

# Generate resource names
RG_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"
STORAGE_NAME="st${ENVIRONMENT}tf${LOCATION_SHORT}001"
VNET_NAME="vnet-terraform-${ENVIRONMENT}"
ACR_NAME="acrterraform${ENVIRONMENT}${LOCATION_SHORT}001"

log_info "Starting Terraform backend bootstrap for environment: $ENVIRONMENT"
log_info "Resource Group: $RG_NAME"
log_info "Storage Account: $STORAGE_NAME"
log_info "Location: $LOCATION"

if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No resources will be created"
fi

# Function to create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME"
    
    if [ "$DRY_RUN" = false ]; then
        az group create \
            --name "$RG_NAME" \
            --location "$LOCATION" \
            --subscription "$SUBSCRIPTION_ID" \
            --tags \
                Environment="$ENVIRONMENT" \
                Purpose="TerraformBackend" \
                ManagedBy="Script" \
                CreatedDate="$(date +%Y-%m-%d)"
        
        log_success "Resource group created successfully"
    else
        echo "Would create resource group: $RG_NAME"
    fi
}

# Function to setup development environment (public access)
configure_public_storage() {
    log_info "Configuring development storage with restricted public access"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with security features
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add GitHub Actions IP ranges for dev environment
        log_info "Adding GitHub Actions IP ranges for secure access"
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.1.128.0/17" \
            --subscription "$SUBSCRIPTION_ID"
        
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.20.140.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Development storage configured successfully"
    else
        echo "Would create storage account: $STORAGE_NAME with public GitHub Actions access"
    fi
}

# Function to setup private VNet for staging/prod
setup_private_vnet() {
    if [ "$SKIP_VNET" = true ]; then
        log_info "Skipping VNet creation"
        return
    fi
    
    log_info "Setting up private VNet for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create VNet
        az network vnet create \
            --name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --address-prefixes "10.100.0.0/16" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private subnet for self-hosted runners
        az network vnet subnet create \
            --name "snet-private" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.1.0/24" \
            --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private endpoints subnet
        az network vnet subnet create \
            --name "snet-private-endpoints" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.2.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private VNet configured successfully"
    else
        echo "Would create VNet: $VNET_NAME with private subnets"
    fi
}

# Function to configure private storage for staging/prod
configure_private_storage() {
    log_info "Configuring private storage for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with enhanced security
        local sku="Standard_ZRS"
        if [ "$ENVIRONMENT" = "prod" ]; then
            sku="Standard_GZRS"
        fi
        
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku "$sku" \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Enable advanced security features
        az storage account blob-service-properties update \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --enable-versioning true \
            --enable-delete-retention true \
            --delete-retention-days 30 \
            --enable-container-delete-retention true \
            --container-delete-retention-days 7 \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add VNet rules if VNet was created
        if [ "$SKIP_VNET" = false ]; then
            az storage account network-rule add \
                --account-name "$STORAGE_NAME" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private storage configured successfully"
    else
        echo "Would create private storage account: $STORAGE_NAME"
    fi
}

# Function to setup private ACR for staging/prod
setup_private_acr() {
    if [ "$ENVIRONMENT" = "dev" ]; then
        log_info "Skipping ACR setup for dev environment"
        return
    fi
    
    log_info "Setting up private Azure Container Registry"
    
    if [ "$DRY_RUN" = false ]; then
        # Create private ACR
        az acr create \
            --name "$ACR_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Premium \
            --public-network-enabled false \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private ACR configured successfully"
    else
        echo "Would create private ACR: $ACR_NAME"
    fi
}

# Function to configure private endpoints for staging/prod
configure_private_endpoints() {
    if [ "$ENVIRONMENT" = "dev" ] || [ "$SKIP_VNET" = true ]; then
        log_info "Skipping private endpoints for $ENVIRONMENT environment"
        return
    fi
    
    log_info "Configuring private endpoints"
    
    if [ "$DRY_RUN" = false ]; then
        # Storage private endpoint
        az network private-endpoint create \
            --name "pe-storage-terraform-$ENVIRONMENT" \
            --resource-group "$RG_NAME" \
            --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
            --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME" \
            --group-id blob \
            --connection-name "storage-connection" \
            --subscription "$SUBSCRIPTION_ID"
        
        # ACR private endpoint
        if [ "$ENVIRONMENT" != "dev" ]; then
            az network private-endpoint create \
                --name "pe-acr-terraform-$ENVIRONMENT" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
                --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" \
                --group-id registry \
                --connection-name "acr-connection" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        log_success "Private endpoints configured successfully"
    else
        echo "Would create private endpoints for storage and ACR"
    fi
}

# Function to setup environment-specific security
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Controlled public access
        log_info "Configuring development environment with controlled public access..."
        configure_public_storage "$ENV"
        setup_public_container_instances "$ENV"
    else
        # Stage/Prod: Private access only
        log_info "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_private_container_instances "$ENV"
    fi
}

# Configure public storage for development
configure_public_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating public storage account for ${ENV} environment..."
    
    # Create storage account with controlled public access
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --https-only true \
        --min-tls-version TLS1_2 \
        --default-action Deny \
        --bypass AzureServices \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Add GitHub Actions IP ranges for dev (more secure than full public access)
    log_info "Adding GitHub Actions IP ranges for controlled access..."
    
    # GitHub Actions IP ranges (updated as of 2024)
    local GITHUB_IP_RANGES=(
        "4.175.114.0/23"
        "20.1.128.0/17"
        "20.20.140.0/24"
        "20.81.0.0/17"
        "185.199.108.0/22"
        "140.82.112.0/20"
        "143.55.64.0/20"
        "192.30.252.0/22"
    )
    
    for ip_range in "${GITHUB_IP_RANGES[@]}"; do
        az storage account network-rule add \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --ip-address "$ip_range" \
            --output none || log_warning "Failed to add IP range: $ip_range"
    done
    
    log_success "Public storage account configured for ${ENV}"
}

# Setup private VNet for staging/production
setup_private_vnet() {
    local ENV=$1
    local VNET_NAME="vnet-terraform-${ENV}"
    local VNET_ADDRESS="10.100.0.0/16"
    
    log_info "Creating private VNet for ${ENV} environment..."
    
    # Create VNet for private environment
    az network vnet create \
        --name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --address-prefixes "$VNET_ADDRESS" \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Private subnet for self-hosted runners
    az network vnet subnet create \
        --name "snet-private" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.1.0/24" \
        --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
        --output none
    
    # Private endpoints subnet
    az network vnet subnet create \
        --name "snet-private-endpoints" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.2.0/24" \
        --output none
    
    log_success "Private VNet configured for ${ENV}"
}

# Configure private storage for staging/production
configure_private_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating private storage account for ${ENV} environment..."
    
    # Create storage account with enhanced security
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
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
        --enable-local-user false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Enable advanced security features
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-versioning true \
        --enable-delete-retention true \
        --delete-retention-days 30 \
        --enable-container-delete-retention true \
        --container-delete-retention-days 7 \
        --output none
    
    # Add VNet rules for private subnet access
    az storage account network-rule add \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private" \
        --output none
    
    log_success "Private storage account configured for ${ENV}"
}

# Setup private ACR for staging/production
setup_private_acr() {
    local ENV=$1
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private ACR for ${ENV} environment..."
    
    # Create private ACR for custom runner images
    az acr create \
        --name "$ACR_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Premium \
        --public-network-enabled false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    log_success "Private ACR configured for ${ENV}"
}

# Configure private endpoints for staging/production
configure_private_endpoints() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private endpoints for ${ENV} environment..."
    
    # Enable private endpoint for storage account
    az network private-endpoint create \
        --name "pe-storage-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --group-id blob \
        --connection-name "storage-connection" \
        --output none
    
    # Enable private endpoint for ACR
    az network private-endpoint create \
        --name "pe-acr-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${ACR_NAME}" \
        --group-id registry \
        --connection-name "acr-connection" \
        --output none
    
    log_success "Private endpoints configured for ${ENV}"
}

# Setup monitoring and logging
setup_monitoring() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local LAW_NAME="law-terraform-${ENV}-${LOCATION_SHORT}-001"
    
    log_info "Setting up monitoring for ${ENV} environment..."
    
    # Create Log Analytics workspace
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --location "$LOCATION" \
        --sku PerGB2018 \
        --retention-time 90 \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Get Log Analytics workspace ID
    local WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --query "id" \
        --output tsv)
    
    # Configure diagnostic settings for storage
    az monitor diagnostic-settings create \
        --name "terraform-backend-diagnostics" \
        --resource "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {"category": "StorageRead", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageWrite", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageDelete", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}}
        ]' \
        --metrics '[
            {"category": "Transaction", "enabled": true},
            {"category": "Capacity", "enabled": true}
        ]' \
        --output none
    
    # Set up alerts for suspicious activity
    az monitor metrics alert create \
        --name "terraform-backend-unauthorized-access" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --condition "count 'Microsoft.Storage/storageAccounts' 'Transactions' 'ResponseType' = 'ClientOtherError' aggregation Total total 5 PT5M" \
        --description "Alert on unauthorized access attempts to Terraform backend storage" \
        --severity 2 \
        --output none
    
    log_success "Monitoring configured for ${ENV}"
}

# Setup container instances placeholders
setup_public_container_instances() {
    local ENV=$1
    log_info "Public container instances will be managed by GitHub Actions for ${ENV}"
}

setup_private_container_instances() {
    local ENV=$1
    log_info "Private container instances will be managed by GitHub Actions for ${ENV}"
}

# Generate resource names
RG_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"
STORAGE_NAME="st${ENVIRONMENT}tf${LOCATION_SHORT}001"
VNET_NAME="vnet-terraform-${ENVIRONMENT}"
ACR_NAME="acrterraform${ENVIRONMENT}${LOCATION_SHORT}001"

log_info "Starting Terraform backend bootstrap for environment: $ENVIRONMENT"
log_info "Resource Group: $RG_NAME"
log_info "Storage Account: $STORAGE_NAME"
log_info "Location: $LOCATION"

if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No resources will be created"
fi

# Function to create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME"
    
    if [ "$DRY_RUN" = false ]; then
        az group create \
            --name "$RG_NAME" \
            --location "$LOCATION" \
            --subscription "$SUBSCRIPTION_ID" \
            --tags \
                Environment="$ENVIRONMENT" \
                Purpose="TerraformBackend" \
                ManagedBy="Script" \
                CreatedDate="$(date +%Y-%m-%d)"
        
        log_success "Resource group created successfully"
    else
        echo "Would create resource group: $RG_NAME"
    fi
}

# Function to setup development environment (public access)
configure_public_storage() {
    log_info "Configuring development storage with restricted public access"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with security features
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add GitHub Actions IP ranges for dev environment
        log_info "Adding GitHub Actions IP ranges for secure access"
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.1.128.0/17" \
            --subscription "$SUBSCRIPTION_ID"
        
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.20.140.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Development storage configured successfully"
    else
        echo "Would create storage account: $STORAGE_NAME with public GitHub Actions access"
    fi
}

# Function to setup private VNet for staging/prod
setup_private_vnet() {
    if [ "$SKIP_VNET" = true ]; then
        log_info "Skipping VNet creation"
        return
    fi
    
    log_info "Setting up private VNet for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create VNet
        az network vnet create \
            --name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --address-prefixes "10.100.0.0/16" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private subnet for self-hosted runners
        az network vnet subnet create \
            --name "snet-private" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.1.0/24" \
            --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private endpoints subnet
        az network vnet subnet create \
            --name "snet-private-endpoints" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.2.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private VNet configured successfully"
    else
        echo "Would create VNet: $VNET_NAME with private subnets"
    fi
}

# Function to configure private storage for staging/prod
configure_private_storage() {
    log_info "Configuring private storage for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with enhanced security
        local sku="Standard_ZRS"
        if [ "$ENVIRONMENT" = "prod" ]; then
            sku="Standard_GZRS"
        fi
        
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku "$sku" \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Enable advanced security features
        az storage account blob-service-properties update \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --enable-versioning true \
            --enable-delete-retention true \
            --delete-retention-days 30 \
            --enable-container-delete-retention true \
            --container-delete-retention-days 7 \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add VNet rules if VNet was created
        if [ "$SKIP_VNET" = false ]; then
            az storage account network-rule add \
                --account-name "$STORAGE_NAME" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private storage configured successfully"
    else
        echo "Would create private storage account: $STORAGE_NAME"
    fi
}

# Function to setup private ACR for staging/prod
setup_private_acr() {
    if [ "$ENVIRONMENT" = "dev" ]; then
        log_info "Skipping ACR setup for dev environment"
        return
    fi
    
    log_info "Setting up private Azure Container Registry"
    
    if [ "$DRY_RUN" = false ]; then
        # Create private ACR
        az acr create \
            --name "$ACR_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Premium \
            --public-network-enabled false \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private ACR configured successfully"
    else
        echo "Would create private ACR: $ACR_NAME"
    fi
}

# Function to configure private endpoints for staging/prod
configure_private_endpoints() {
    if [ "$ENVIRONMENT" = "dev" ] || [ "$SKIP_VNET" = true ]; then
        log_info "Skipping private endpoints for $ENVIRONMENT environment"
        return
    fi
    
    log_info "Configuring private endpoints"
    
    if [ "$DRY_RUN" = false ]; then
        # Storage private endpoint
        az network private-endpoint create \
            --name "pe-storage-terraform-$ENVIRONMENT" \
            --resource-group "$RG_NAME" \
            --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
            --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME" \
            --group-id blob \
            --connection-name "storage-connection" \
            --subscription "$SUBSCRIPTION_ID"
        
        # ACR private endpoint
        if [ "$ENVIRONMENT" != "dev" ]; then
            az network private-endpoint create \
                --name "pe-acr-terraform-$ENVIRONMENT" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
                --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" \
                --group-id registry \
                --connection-name "acr-connection" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        log_success "Private endpoints configured successfully"
    else
        echo "Would create private endpoints for storage and ACR"
    fi
}

# Function to setup environment-specific security
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Controlled public access
        log_info "Configuring development environment with controlled public access..."
        configure_public_storage "$ENV"
        setup_public_container_instances "$ENV"
    else
        # Stage/Prod: Private access only
        log_info "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_private_container_instances "$ENV"
    fi
}

# Configure public storage for development
configure_public_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating public storage account for ${ENV} environment..."
    
    # Create storage account with controlled public access
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --https-only true \
        --min-tls-version TLS1_2 \
        --default-action Deny \
        --bypass AzureServices \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Add GitHub Actions IP ranges for dev (more secure than full public access)
    log_info "Adding GitHub Actions IP ranges for controlled access..."
    
    # GitHub Actions IP ranges (updated as of 2024)
    local GITHUB_IP_RANGES=(
        "4.175.114.0/23"
        "20.1.128.0/17"
        "20.20.140.0/24"
        "20.81.0.0/17"
        "185.199.108.0/22"
        "140.82.112.0/20"
        "143.55.64.0/20"
        "192.30.252.0/22"
    )
    
    for ip_range in "${GITHUB_IP_RANGES[@]}"; do
        az storage account network-rule add \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --ip-address "$ip_range" \
            --output none || log_warning "Failed to add IP range: $ip_range"
    done
    
    log_success "Public storage account configured for ${ENV}"
}

# Setup private VNet for staging/production
setup_private_vnet() {
    local ENV=$1
    local VNET_NAME="vnet-terraform-${ENV}"
    local VNET_ADDRESS="10.100.0.0/16"
    
    log_info "Creating private VNet for ${ENV} environment..."
    
    # Create VNet for private environment
    az network vnet create \
        --name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --address-prefixes "$VNET_ADDRESS" \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Private subnet for self-hosted runners
    az network vnet subnet create \
        --name "snet-private" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.1.0/24" \
        --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
        --output none
    
    # Private endpoints subnet
    az network vnet subnet create \
        --name "snet-private-endpoints" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.2.0/24" \
        --output none
    
    log_success "Private VNet configured for ${ENV}"
}

# Configure private storage for staging/production
configure_private_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating private storage account for ${ENV} environment..."
    
    # Create storage account with enhanced security
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
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
        --enable-local-user false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Enable advanced security features
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-versioning true \
        --enable-delete-retention true \
        --delete-retention-days 30 \
        --enable-container-delete-retention true \
        --container-delete-retention-days 7 \
        --output none
    
    # Add VNet rules for private subnet access
    az storage account network-rule add \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private" \
        --output none
    
    log_success "Private storage account configured for ${ENV}"
}

# Setup private ACR for staging/production
setup_private_acr() {
    local ENV=$1
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private ACR for ${ENV} environment..."
    
    # Create private ACR for custom runner images
    az acr create \
        --name "$ACR_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Premium \
        --public-network-enabled false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    log_success "Private ACR configured for ${ENV}"
}

# Configure private endpoints for staging/production
configure_private_endpoints() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private endpoints for ${ENV} environment..."
    
    # Enable private endpoint for storage account
    az network private-endpoint create \
        --name "pe-storage-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --group-id blob \
        --connection-name "storage-connection" \
        --output none
    
    # Enable private endpoint for ACR
    az network private-endpoint create \
        --name "pe-acr-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${ACR_NAME}" \
        --group-id registry \
        --connection-name "acr-connection" \
        --output none
    
    log_success "Private endpoints configured for ${ENV}"
}

# Setup monitoring and logging
setup_monitoring() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local LAW_NAME="law-terraform-${ENV}-${LOCATION_SHORT}-001"
    
    log_info "Setting up monitoring for ${ENV} environment..."
    
    # Create Log Analytics workspace
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --location "$LOCATION" \
        --sku PerGB2018 \
        --retention-time 90 \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Get Log Analytics workspace ID
    local WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --query "id" \
        --output tsv)
    
    # Configure diagnostic settings for storage
    az monitor diagnostic-settings create \
        --name "terraform-backend-diagnostics" \
        --resource "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {"category": "StorageRead", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageWrite", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageDelete", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}}
        ]' \
        --metrics '[
            {"category": "Transaction", "enabled": true},
            {"category": "Capacity", "enabled": true}
        ]' \
        --output none
    
    # Set up alerts for suspicious activity
    az monitor metrics alert create \
        --name "terraform-backend-unauthorized-access" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --condition "count 'Microsoft.Storage/storageAccounts' 'Transactions' 'ResponseType' = 'ClientOtherError' aggregation Total total 5 PT5M" \
        --description "Alert on unauthorized access attempts to Terraform backend storage" \
        --severity 2 \
        --output none
    
    log_success "Monitoring configured for ${ENV}"
}

# Setup container instances placeholders
setup_public_container_instances() {
    local ENV=$1
    log_info "Public container instances will be managed by GitHub Actions for ${ENV}"
}

setup_private_container_instances() {
    local ENV=$1
    log_info "Private container instances will be managed by GitHub Actions for ${ENV}"
}

# Generate resource names
RG_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"
STORAGE_NAME="st${ENVIRONMENT}tf${LOCATION_SHORT}001"
VNET_NAME="vnet-terraform-${ENVIRONMENT}"
ACR_NAME="acrterraform${ENVIRONMENT}${LOCATION_SHORT}001"

log_info "Starting Terraform backend bootstrap for environment: $ENVIRONMENT"
log_info "Resource Group: $RG_NAME"
log_info "Storage Account: $STORAGE_NAME"
log_info "Location: $LOCATION"

if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No resources will be created"
fi

# Function to create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME"
    
    if [ "$DRY_RUN" = false ]; then
        az group create \
            --name "$RG_NAME" \
            --location "$LOCATION" \
            --subscription "$SUBSCRIPTION_ID" \
            --tags \
                Environment="$ENVIRONMENT" \
                Purpose="TerraformBackend" \
                ManagedBy="Script" \
                CreatedDate="$(date +%Y-%m-%d)"
        
        log_success "Resource group created successfully"
    else
        echo "Would create resource group: $RG_NAME"
    fi
}

# Function to setup development environment (public access)
configure_public_storage() {
    log_info "Configuring development storage with restricted public access"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with security features
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add GitHub Actions IP ranges for dev environment
        log_info "Adding GitHub Actions IP ranges for secure access"
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.1.128.0/17" \
            --subscription "$SUBSCRIPTION_ID"
        
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.20.140.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Development storage configured successfully"
    else
        echo "Would create storage account: $STORAGE_NAME with public GitHub Actions access"
    fi
}

# Function to setup private VNet for staging/prod
setup_private_vnet() {
    if [ "$SKIP_VNET" = true ]; then
        log_info "Skipping VNet creation"
        return
    fi
    
    log_info "Setting up private VNet for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create VNet
        az network vnet create \
            --name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --address-prefixes "10.100.0.0/16" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private subnet for self-hosted runners
        az network vnet subnet create \
            --name "snet-private" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.1.0/24" \
            --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private endpoints subnet
        az network vnet subnet create \
            --name "snet-private-endpoints" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.2.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private VNet configured successfully"
    else
        echo "Would create VNet: $VNET_NAME with private subnets"
    fi
}

# Function to configure private storage for staging/prod
configure_private_storage() {
    log_info "Configuring private storage for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with enhanced security
        local sku="Standard_ZRS"
        if [ "$ENVIRONMENT" = "prod" ]; then
            sku="Standard_GZRS"
        fi
        
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku "$sku" \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Enable advanced security features
        az storage account blob-service-properties update \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --enable-versioning true \
            --enable-delete-retention true \
            --delete-retention-days 30 \
            --enable-container-delete-retention true \
            --container-delete-retention-days 7 \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add VNet rules if VNet was created
        if [ "$SKIP_VNET" = false ]; then
            az storage account network-rule add \
                --account-name "$STORAGE_NAME" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private storage configured successfully"
    else
        echo "Would create private storage account: $STORAGE_NAME"
    fi
}

# Function to setup private ACR for staging/prod
setup_private_acr() {
    if [ "$ENVIRONMENT" = "dev" ]; then
        log_info "Skipping ACR setup for dev environment"
        return
    fi
    
    log_info "Setting up private Azure Container Registry"
    
    if [ "$DRY_RUN" = false ]; then
        # Create private ACR
        az acr create \
            --name "$ACR_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Premium \
            --public-network-enabled false \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private ACR configured successfully"
    else
        echo "Would create private ACR: $ACR_NAME"
    fi
}

# Function to configure private endpoints for staging/prod
configure_private_endpoints() {
    if [ "$ENVIRONMENT" = "dev" ] || [ "$SKIP_VNET" = true ]; then
        log_info "Skipping private endpoints for $ENVIRONMENT environment"
        return
    fi
    
    log_info "Configuring private endpoints"
    
    if [ "$DRY_RUN" = false ]; then
        # Storage private endpoint
        az network private-endpoint create \
            --name "pe-storage-terraform-$ENVIRONMENT" \
            --resource-group "$RG_NAME" \
            --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
            --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME" \
            --group-id blob \
            --connection-name "storage-connection" \
            --subscription "$SUBSCRIPTION_ID"
        
        # ACR private endpoint
        if [ "$ENVIRONMENT" != "dev" ]; then
            az network private-endpoint create \
                --name "pe-acr-terraform-$ENVIRONMENT" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
                --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" \
                --group-id registry \
                --connection-name "acr-connection" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        log_success "Private endpoints configured successfully"
    else
        echo "Would create private endpoints for storage and ACR"
    fi
}

# Function to setup environment-specific security
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Controlled public access
        log_info "Configuring development environment with controlled public access..."
        configure_public_storage "$ENV"
        setup_public_container_instances "$ENV"
    else
        # Stage/Prod: Private access only
        log_info "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_private_container_instances "$ENV"
    fi
}

# Configure public storage for development
configure_public_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating public storage account for ${ENV} environment..."
    
    # Create storage account with controlled public access
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --https-only true \
        --min-tls-version TLS1_2 \
        --default-action Deny \
        --bypass AzureServices \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Add GitHub Actions IP ranges for dev (more secure than full public access)
    log_info "Adding GitHub Actions IP ranges for controlled access..."
    
    # GitHub Actions IP ranges (updated as of 2024)
    local GITHUB_IP_RANGES=(
        "4.175.114.0/23"
        "20.1.128.0/17"
        "20.20.140.0/24"
        "20.81.0.0/17"
        "185.199.108.0/22"
        "140.82.112.0/20"
        "143.55.64.0/20"
        "192.30.252.0/22"
    )
    
    for ip_range in "${GITHUB_IP_RANGES[@]}"; do
        az storage account network-rule add \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --ip-address "$ip_range" \
            --output none || log_warning "Failed to add IP range: $ip_range"
    done
    
    log_success "Public storage account configured for ${ENV}"
}

# Setup private VNet for staging/production
setup_private_vnet() {
    local ENV=$1
    local VNET_NAME="vnet-terraform-${ENV}"
    local VNET_ADDRESS="10.100.0.0/16"
    
    log_info "Creating private VNet for ${ENV} environment..."
    
    # Create VNet for private environment
    az network vnet create \
        --name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --address-prefixes "$VNET_ADDRESS" \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Private subnet for self-hosted runners
    az network vnet subnet create \
        --name "snet-private" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.1.0/24" \
        --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
        --output none
    
    # Private endpoints subnet
    az network vnet subnet create \
        --name "snet-private-endpoints" \
        --vnet-name "$VNET_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --address-prefixes "10.100.2.0/24" \
        --output none
    
    log_success "Private VNet configured for ${ENV}"
}

# Configure private storage for staging/production
configure_private_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating private storage account for ${ENV} environment..."
    
    # Create storage account with enhanced security
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
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
        --enable-local-user false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Enable advanced security features
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-versioning true \
        --enable-delete-retention true \
        --delete-retention-days 30 \
        --enable-container-delete-retention true \
        --container-delete-retention-days 7 \
        --output none
    
    # Add VNet rules for private subnet access
    az storage account network-rule add \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private" \
        --output none
    
    log_success "Private storage account configured for ${ENV}"
}

# Setup private ACR for staging/production
setup_private_acr() {
    local ENV=$1
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private ACR for ${ENV} environment..."
    
    # Create private ACR for custom runner images
    az acr create \
        --name "$ACR_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Premium \
        --public-network-enabled false \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    log_success "Private ACR configured for ${ENV}"
}

# Configure private endpoints for staging/production
configure_private_endpoints() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private endpoints for ${ENV} environment..."
    
    # Enable private endpoint for storage account
    az network private-endpoint create \
        --name "pe-storage-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --group-id blob \
        --connection-name "storage-connection" \
        --output none
    
    # Enable private endpoint for ACR
    az network private-endpoint create \
        --name "pe-acr-terraform-${ENV}" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --subnet "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Network/virtualNetworks/vnet-terraform-${ENV}/subnets/snet-private-endpoints" \
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${ACR_NAME}" \
        --group-id registry \
        --connection-name "acr-connection" \
        --output none
    
    log_success "Private endpoints configured for ${ENV}"
}

# Setup monitoring and logging
setup_monitoring() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local LAW_NAME="law-terraform-${ENV}-${LOCATION_SHORT}-001"
    
    log_info "Setting up monitoring for ${ENV} environment..."
    
    # Create Log Analytics workspace
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --location "$LOCATION" \
        --sku PerGB2018 \
        --retention-time 90 \
        --tags "Environment=${ENV}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
    
    # Get Log Analytics workspace ID
    local WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --workspace-name "$LAW_NAME" \
        --query "id" \
        --output tsv)
    
    # Configure diagnostic settings for storage
    az monitor diagnostic-settings create \
        --name "terraform-backend-diagnostics" \
        --resource "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {"category": "StorageRead", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageWrite", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}},
            {"category": "StorageDelete", "enabled": true, "retentionPolicy": {"enabled": true, "days": 90}}
        ]' \
        --metrics '[
            {"category": "Transaction", "enabled": true},
            {"category": "Capacity", "enabled": true}
        ]' \
        --output none
    
    # Set up alerts for suspicious activity
    az monitor metrics alert create \
        --name "terraform-backend-unauthorized-access" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}" \
        --condition "count 'Microsoft.Storage/storageAccounts' 'Transactions' 'ResponseType' = 'ClientOtherError' aggregation Total total 5 PT5M" \
        --description "Alert on unauthorized access attempts to Terraform backend storage" \
        --severity 2 \
        --output none
    
    log_success "Monitoring configured for ${ENV}"
}

# Setup container instances placeholders
setup_public_container_instances() {
    local ENV=$1
    log_info "Public container instances will be managed by GitHub Actions for ${ENV}"
}

setup_private_container_instances() {
    local ENV=$1
    log_info "Private container instances will be managed by GitHub Actions for ${ENV}"
}

# Generate resource names
RG_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"
STORAGE_NAME="st${ENVIRONMENT}tf${LOCATION_SHORT}001"
VNET_NAME="vnet-terraform-${ENVIRONMENT}"
ACR_NAME="acrterraform${ENVIRONMENT}${LOCATION_SHORT}001"

log_info "Starting Terraform backend bootstrap for environment: $ENVIRONMENT"
log_info "Resource Group: $RG_NAME"
log_info "Storage Account: $STORAGE_NAME"
log_info "Location: $LOCATION"

if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No resources will be created"
fi

# Function to create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME"
    
    if [ "$DRY_RUN" = false ]; then
        az group create \
            --name "$RG_NAME" \
            --location "$LOCATION" \
            --subscription "$SUBSCRIPTION_ID" \
            --tags \
                Environment="$ENVIRONMENT" \
                Purpose="TerraformBackend" \
                ManagedBy="Script" \
                CreatedDate="$(date +%Y-%m-%d)"
        
        log_success "Resource group created successfully"
    else
        echo "Would create resource group: $RG_NAME"
    fi
}

# Function to setup development environment (public access)
configure_public_storage() {
    log_info "Configuring development storage with restricted public access"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with security features
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add GitHub Actions IP ranges for dev environment
        log_info "Adding GitHub Actions IP ranges for secure access"
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.1.128.0/17" \
            --subscription "$SUBSCRIPTION_ID"
        
        az storage account network-rule add \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --ip-address "20.20.140.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Development storage configured successfully"
    else
        echo "Would create storage account: $STORAGE_NAME with public GitHub Actions access"
    fi
}

# Function to setup private VNet for staging/prod
setup_private_vnet() {
    if [ "$SKIP_VNET" = true ]; then
        log_info "Skipping VNet creation"
        return
    fi
    
    log_info "Setting up private VNet for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create VNet
        az network vnet create \
            --name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --address-prefixes "10.100.0.0/16" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private subnet for self-hosted runners
        az network vnet subnet create \
            --name "snet-private" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.1.0/24" \
            --service-endpoints "Microsoft.Storage" "Microsoft.ContainerRegistry" \
            --subscription "$SUBSCRIPTION_ID"
        
        # Private endpoints subnet
        az network vnet subnet create \
            --name "snet-private-endpoints" \
            --vnet-name "$VNET_NAME" \
            --resource-group "$RG_NAME" \
            --address-prefixes "10.100.2.0/24" \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private VNet configured successfully"
    else
        echo "Would create VNet: $VNET_NAME with private subnets"
    fi
}

# Function to configure private storage for staging/prod
configure_private_storage() {
    log_info "Configuring private storage for $ENVIRONMENT environment"
    
    if [ "$DRY_RUN" = false ]; then
        # Create storage account with enhanced security
        local sku="Standard_ZRS"
        if [ "$ENVIRONMENT" = "prod" ]; then
            sku="Standard_GZRS"
        fi
        
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku "$sku" \
            --kind StorageV2 \
            --allow-blob-public-access false \
            --allow-shared-key-access false \
            --https-only true \
            --min-tls-version TLS1_2 \
            --default-action Deny \
            --bypass AzureServices \
            --subscription "$SUBSCRIPTION_ID"
        
        # Enable advanced security features
        az storage account blob-service-properties update \
            --account-name "$STORAGE_NAME" \
            --resource-group "$RG_NAME" \
            --enable-versioning true \
            --enable-delete-retention true \
            --delete-retention-days 30 \
            --enable-container-delete-retention true \
            --container-delete-retention-days 7 \
            --subscription "$SUBSCRIPTION_ID"
        
        # Add VNet rules if VNet was created
        if [ "$SKIP_VNET" = false ]; then
            az storage account network-rule add \
                --account-name "$STORAGE_NAME" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        # Create terraform state container
        az storage container create \
            --name "terraform-state" \
            --account-name "$STORAGE_NAME" \
            --auth-mode login \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private storage configured successfully"
    else
        echo "Would create private storage account: $STORAGE_NAME"
    fi
}

# Function to setup private ACR for staging/prod
setup_private_acr() {
    if [ "$ENVIRONMENT" = "dev" ]; then
        log_info "Skipping ACR setup for dev environment"
        return
    fi
    
    log_info "Setting up private Azure Container Registry"
    
    if [ "$DRY_RUN" = false ]; then
        # Create private ACR
        az acr create \
            --name "$ACR_NAME" \
            --resource-group "$RG_NAME" \
            --location "$LOCATION" \
            --sku Premium \
            --public-network-enabled false \
            --subscription "$SUBSCRIPTION_ID"
        
        log_success "Private ACR configured successfully"
    else
        echo "Would create private ACR: $ACR_NAME"
    fi
}

# Function to configure private endpoints for staging/prod
configure_private_endpoints() {
    if [ "$ENVIRONMENT" = "dev" ] || [ "$SKIP_VNET" = true ]; then
        log_info "Skipping private endpoints for $ENVIRONMENT environment"
        return
    fi
    
    log_info "Configuring private endpoints"
    
    if [ "$DRY_RUN" = false ]; then
        # Storage private endpoint
        az network private-endpoint create \
            --name "pe-storage-terraform-$ENVIRONMENT" \
            --resource-group "$RG_NAME" \
            --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
            --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME" \
            --group-id blob \
            --connection-name "storage-connection" \
            --subscription "$SUBSCRIPTION_ID"
        
        # ACR private endpoint
        if [ "$ENVIRONMENT" != "dev" ]; then
            az network private-endpoint create \
                --name "pe-acr-terraform-$ENVIRONMENT" \
                --resource-group "$RG_NAME" \
                --subnet "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/snet-private-endpoints" \
                --private-connection-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" \
                --group-id registry \
                --connection-name "acr-connection" \
                --subscription "$SUBSCRIPTION_ID"
        fi
        
        log_success "Private endpoints configured successfully"
    else
        echo "Would create private endpoints for storage and ACR"
    fi
}

# Function to setup environment-specific security
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Controlled public access
        log_info "Configuring development environment with controlled public access..."
        configure_public_storage "$ENV"
        setup_public_container_instances "$ENV"
    else
        # Stage/Prod: Private access only
        log_info "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_private_container_instances "$ENV"
    fi
}

# Configure public storage for development
configure_public_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating public storage account for ${ENV} environment..."
    
    # Create storage account with controlled public access
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-blob-public-access false \
        --allow-shared-key-access false \
        --https-only true \
        --min-tls-version TLS1_2 \
        --default-action Deny \
        --bypass AzureServices \
        --tags "Environment=${ENV}"