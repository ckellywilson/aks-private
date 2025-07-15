#!/bin/bash

# Multi-Environment Terraform Backend Bootstrap Script
# This script creates Azure Storage accounts and supporting infrastructure
# for Terraform backends across dev, staging, and production environments
# with different security models per environment

set -e

# Configuration
LOCATION="East US"  # Default location - can be overridden with -l/--location parameter
LOCATION_SHORT="eus"  # Will be auto-generated based on LOCATION
SUBSCRIPTION_ID=""
TENANT_ID=""
RESOURCE_GROUP_NAME=""
DRY_RUN=false

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
  --dry-run               Show what would be done without executing
  -h, --help              Show this help message

Examples:
  $0 dev -s 12345678-1234-1234-1234-123456789012
  $0 staging -s 12345678-1234-1234-1234-123456789012 -l "Central US"
  $0 prod -s 12345678-1234-1234-1234-123456789012 -l "West Europe" -r custom-rg-name
  $0 dev -s 12345678-1234-1234-1234-123456789012 -l "East US 2" --dry-run

Supported regions:
  US: East US, East US 2, Central US, North Central US, South Central US, West US, West US 2, West Central US
  Europe: North Europe, West Europe, France Central, Germany West Central, UK South, UK West
  Asia: East Asia, Southeast Asia, Japan East, Japan West, Korea Central, Australia East
  Other: Canada Central, Brazil South

For unlisted regions, a short code will be auto-generated.
EOF
}

# Environment-specific security configurations
setup_environment_security() {
    local ENV=$1
    
    if [ "$ENV" = "dev" ]; then
        # Development: Controlled public access
        log_info "Configuring development environment with controlled public access..."
        configure_public_storage "$ENV"
        setup_monitoring "$ENV"
    else
        # Stage/Prod: Private access only
        log_info "Configuring ${ENV} environment with private access..."
        setup_private_vnet "$ENV"
        configure_private_storage "$ENV"
        setup_private_acr "$ENV"
        configure_private_endpoints "$ENV"
        setup_monitoring "$ENV"
    fi
}

# Configure public storage for development
configure_public_storage() {
    local ENV=$1
    local STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Creating public storage account for ${ENV} environment..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create storage account: $STORAGE_ACCOUNT_NAME"
        return 0
    fi
    
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
    
    # Add current IP address for container creation
    CURRENT_IP=$(curl -s ifconfig.me)
    if [[ -n "$CURRENT_IP" ]]; then
        log_info "Adding current IP address ($CURRENT_IP) for container creation..."
        az storage account network-rule add \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --ip-address "$CURRENT_IP" \
            --output none || log_warning "Failed to add current IP: $CURRENT_IP"
    fi
    
    # Wait for network rules to propagate
    sleep 5
    
    # Create terraform state container
    az storage container create \
        --name "tfstate" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --output none
    
    log_success "Public storage account configured for ${ENV}"
}

# Setup private VNet for staging/production
setup_private_vnet() {
    local ENV=$1
    local VNET_NAME="vnet-terraform-${ENV}"
    local VNET_ADDRESS="10.100.0.0/16"
    
    log_info "Creating private VNet for ${ENV} environment..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create VNet: $VNET_NAME"
        return 0
    fi
    
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
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create private storage account: $STORAGE_ACCOUNT_NAME"
        return 0
    fi
    
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
    
    # Create terraform state container
    az storage container create \
        --name "tfstate" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --output none
    
    log_success "Private storage account configured for ${ENV}"
}

# Setup private ACR for staging/production
setup_private_acr() {
    local ENV=$1
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Creating private ACR for ${ENV} environment..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create ACR: $ACR_NAME"
        return 0
    fi
    
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
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create private endpoints for storage and ACR"
        return 0
    fi
    
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
        --private-connection-resource-id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}" \
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
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create monitoring for ${ENV}"
        return 0
    fi
    
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
    
    log_success "Monitoring configured for ${ENV}"
}

# Parse command line arguments
ENVIRONMENT=""
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
        -r|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
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
    # US Regions
    "East US") LOCATION_SHORT="eus" ;;
    "East US 2") LOCATION_SHORT="eus2" ;;
    "Central US") LOCATION_SHORT="cus" ;;
    "North Central US") LOCATION_SHORT="ncus" ;;
    "South Central US") LOCATION_SHORT="scus" ;;
    "West US") LOCATION_SHORT="wus" ;;
    "West US 2") LOCATION_SHORT="wus2" ;;
    "West Central US") LOCATION_SHORT="wcus" ;;
    
    # Europe Regions
    "North Europe") LOCATION_SHORT="neu" ;;
    "West Europe") LOCATION_SHORT="weu" ;;
    "France Central") LOCATION_SHORT="frc" ;;
    "France South") LOCATION_SHORT="frs" ;;
    "Germany West Central") LOCATION_SHORT="dewc" ;;
    "Germany North") LOCATION_SHORT="den" ;;
    "UK South") LOCATION_SHORT="uks" ;;
    "UK West") LOCATION_SHORT="ukw" ;;
    "Switzerland North") LOCATION_SHORT="chn" ;;
    "Switzerland West") LOCATION_SHORT="chw" ;;
    
    # Asia Pacific Regions
    "East Asia") LOCATION_SHORT="ea" ;;
    "Southeast Asia") LOCATION_SHORT="sea" ;;
    "Japan East") LOCATION_SHORT="jpe" ;;
    "Japan West") LOCATION_SHORT="jpw" ;;
    "Korea Central") LOCATION_SHORT="krc" ;;
    "Korea South") LOCATION_SHORT="krs" ;;
    "Australia East") LOCATION_SHORT="aue" ;;
    "Australia Southeast") LOCATION_SHORT="ause" ;;
    "Australia Central") LOCATION_SHORT="auc" ;;
    "Central India") LOCATION_SHORT="inc" ;;
    "South India") LOCATION_SHORT="ins" ;;
    "West India") LOCATION_SHORT="inw" ;;
    
    # Other Regions
    "Canada Central") LOCATION_SHORT="cac" ;;
    "Canada East") LOCATION_SHORT="cae" ;;
    "Brazil South") LOCATION_SHORT="brs" ;;
    "South Africa North") LOCATION_SHORT="zan" ;;
    "UAE North") LOCATION_SHORT="aen" ;;
    
    *) 
        log_warning "Unknown location '$LOCATION', generating short code automatically"
        # Generate short code from location name (first 3-4 characters, lowercase, no spaces)
        LOCATION_SHORT=$(echo "$LOCATION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g' | cut -c1-4)
        log_info "Generated location short code: $LOCATION_SHORT"
        ;;
esac

# Generate resource names
STORAGE_ACCOUNT_NAME_PREFIX="staks"
if [ -z "$RESOURCE_GROUP_NAME" ]; then
    RESOURCE_GROUP_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"
fi

# Display configuration
log_info "Configuration:"
log_info "  Environment: $ENVIRONMENT"
log_info "  Subscription ID: $SUBSCRIPTION_ID"
log_info "  Resource Group: $RESOURCE_GROUP_NAME"
log_info "  Location: $LOCATION ($LOCATION_SHORT)"
log_info "  Storage Account: ${STORAGE_ACCOUNT_NAME_PREFIX}${ENVIRONMENT}${LOCATION_SHORT}001tfstate"
log_info "  Dry Run: $DRY_RUN"

# Confirm before proceeding
if [ "$DRY_RUN" = false ]; then
    echo
    read -p "Do you want to proceed with the bootstrap? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Bootstrap cancelled by user"
        exit 0
    fi
fi

# Set up Azure CLI
log_info "Setting up Azure CLI..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group
log_info "Creating resource group: $RESOURCE_GROUP_NAME"
if [ "$DRY_RUN" = false ]; then
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags "Environment=${ENVIRONMENT}" "Project=aks-private" "ManagedBy=Terraform" \
        --output none
fi

# Setup environment-specific security
setup_environment_security "$ENVIRONMENT"

# Display completion message
log_success "Bootstrap completed successfully!"
log_info "Environment: $ENVIRONMENT"
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: ${STORAGE_ACCOUNT_NAME_PREFIX}${ENVIRONMENT}${LOCATION_SHORT}001tfstate"

if [ "$ENVIRONMENT" != "dev" ]; then
    log_info "VNet: vnet-terraform-${ENVIRONMENT}"
    log_info "ACR: acrterraform${ENVIRONMENT}${LOCATION_SHORT}001"
    log_info "Log Analytics: law-terraform-${ENVIRONMENT}-${LOCATION_SHORT}-001"
fi

echo
log_info "Next steps:"
log_info "1. Update your providers.tf files with the new backend configuration"
log_info "2. Run 'terraform init' to initialize the backend"
log_info "3. For staging/prod: Build and push runner images to ACR"
log_info "4. Configure GitHub Actions secrets and variables"
