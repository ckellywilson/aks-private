#!/bin/bash

# Environment Validation Script
# Validates that all required infrastructure is in place for Terraform deployments

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

Validate Terraform backend infrastructure for specified environment.

Arguments:
  environment    Target environment (dev, staging, prod)

Options:
  -s, --subscription-id    Azure subscription ID
  -v, --verbose           Verbose output
  -h, --help              Show this help message

Examples:
  $0 dev -s 12345678-1234-1234-1234-123456789012
  $0 staging -s 12345678-1234-1234-1234-123456789012 --verbose
EOF
}

validate_dev_environment() {
    local ENV=$1
    local STORAGE_ACCOUNT="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    
    log_info "Validating development environment infrastructure..."
    
    # Check resource group
    if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "Resource group exists: $RESOURCE_GROUP_NAME"
    else
        log_error "Resource group not found: $RESOURCE_GROUP_NAME"
        return 1
    fi
    
    # Check storage account
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "Storage account exists: $STORAGE_ACCOUNT"
        
        # Check container
        if az storage container show --name "tfstate" --account-name "$STORAGE_ACCOUNT" --auth-mode login &>/dev/null; then
            log_success "Terraform state container exists"
        else
            log_warning "Terraform state container not found, creating..."
            az storage container create --name "tfstate" --account-name "$STORAGE_ACCOUNT" --auth-mode login
        fi
    else
        log_error "Storage account not found: $STORAGE_ACCOUNT"
        return 1
    fi
    
    # Check network rules for GitHub Actions
    local IP_RULES=$(az storage account show --name "$STORAGE_ACCOUNT" --query "networkRuleSet.ipRules" -o tsv)
    if [ -n "$IP_RULES" ]; then
        log_success "Network access rules configured"
    else
        log_warning "No network access rules found - this may prevent GitHub Actions access"
    fi
}

validate_private_environment() {
    local ENV=$1
    local STORAGE_ACCOUNT="${STORAGE_ACCOUNT_NAME_PREFIX}${ENV}${LOCATION_SHORT}001tfstate"
    local VNET_NAME="vnet-terraform-${ENV}"
    local ACR_NAME="acrterraform${ENV}${LOCATION_SHORT}001"
    
    log_info "Validating private environment infrastructure for $ENV..."
    
    # Check resource group
    if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "Resource group exists: $RESOURCE_GROUP_NAME"
    else
        log_error "Resource group not found: $RESOURCE_GROUP_NAME"
        return 1
    fi
    
    # Check VNet
    if az network vnet show --name "$VNET_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "VNet exists: $VNET_NAME"
        
        # Check subnets
        if az network vnet subnet show --name "snet-private" --vnet-name "$VNET_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
            log_success "Private subnet exists"
        else
            log_error "Private subnet not found"
            return 1
        fi
        
        if az network vnet subnet show --name "snet-private-endpoints" --vnet-name "$VNET_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
            log_success "Private endpoints subnet exists"
        else
            log_error "Private endpoints subnet not found"
            return 1
        fi
    else
        log_error "VNet not found: $VNET_NAME"
        return 1
    fi
    
    # Check storage account
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "Storage account exists: $STORAGE_ACCOUNT"
        
        # Check if public access is disabled
        local PUBLIC_ACCESS=$(az storage account show --name "$STORAGE_ACCOUNT" --query "allowBlobPublicAccess" -o tsv)
        if [ "$PUBLIC_ACCESS" = "false" ]; then
            log_success "Public blob access is disabled (secure)"
        else
            log_warning "Public blob access is enabled (security risk)"
        fi
    else
        log_error "Storage account not found: $STORAGE_ACCOUNT"
        return 1
    fi
    
    # Check ACR
    if az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        log_success "Azure Container Registry exists: $ACR_NAME"
        
        # Check if public access is disabled
        local ACR_PUBLIC=$(az acr show --name "$ACR_NAME" --query "publicNetworkAccess" -o tsv)
        if [ "$ACR_PUBLIC" = "Disabled" ]; then
            log_success "ACR public access is disabled (secure)"
        else
            log_warning "ACR public access is enabled"
        fi
    else
        log_error "Azure Container Registry not found: $ACR_NAME"
        return 1
    fi
    
    # Check private endpoints
    local PE_COUNT=$(az network private-endpoint list --resource-group "$RESOURCE_GROUP_NAME" --query "length([?contains(name, 'terraform-${ENV}')])" -o tsv)
    if [ "$PE_COUNT" -gt 0 ]; then
        log_success "Private endpoints configured: $PE_COUNT found"
    else
        log_warning "No private endpoints found for $ENV environment"
    fi
}

validate_monitoring() {
    local ENV=$1
    local LAW_NAME="law-terraform-${ENV}-${LOCATION_SHORT}-001"
    
    log_info "Validating monitoring infrastructure for $ENV..."
    
    if az monitor log-analytics workspace show --resource-group "$RESOURCE_GROUP_NAME" --workspace-name "$LAW_NAME" &>/dev/null; then
        log_success "Log Analytics workspace exists: $LAW_NAME"
    else
        log_warning "Log Analytics workspace not found: $LAW_NAME"
    fi
}

# Parse command line arguments
ENVIRONMENT=""
SUBSCRIPTION_ID=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
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

# Set up variables
LOCATION="East US"
LOCATION_SHORT="eus"
STORAGE_ACCOUNT_NAME_PREFIX="staks"
RESOURCE_GROUP_NAME="rg-terraform-state-${ENVIRONMENT}-${LOCATION_SHORT}-001"

# Set up Azure CLI
log_info "Setting up Azure CLI for subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

log_info "Validating $ENVIRONMENT environment..."
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Location: $LOCATION"

# Run validation based on environment type
if [ "$ENVIRONMENT" = "dev" ]; then
    validate_dev_environment "$ENVIRONMENT"
    VALIDATION_STATUS=$?
else
    validate_private_environment "$ENVIRONMENT"
    VALIDATION_STATUS=$?
fi

# Validate monitoring for all environments
validate_monitoring "$ENVIRONMENT"

# Summary
echo
if [ $VALIDATION_STATUS -eq 0 ]; then
    log_success "Environment validation completed successfully!"
    log_info "Environment '$ENVIRONMENT' is ready for Terraform deployments"
else
    log_error "Environment validation failed!"
    log_error "Please run the bootstrap script to create missing infrastructure"
    exit 1
fi

echo
log_info "Next steps:"
log_info "1. Ensure GitHub Actions secrets are configured"
log_info "2. Update Terraform provider configuration"
log_info "3. Test Terraform init/plan operations"

if [ "$ENVIRONMENT" != "dev" ]; then
    log_info "4. Build and push runner container images"
    log_info "5. Test private network connectivity"
fi
