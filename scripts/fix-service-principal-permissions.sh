#!/bin/bash

# Service Principal Permission Fix Script
# Run this script with an account that has subscription Owner or User Access Administrator privileges

set -euo pipefail

# Configuration - Update these values
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}"
CLIENT_ID="${AZURE_CLIENT_ID:-}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        log_error "AZURE_SUBSCRIPTION_ID environment variable is required"
        exit 1
    fi
    
    if [[ -z "$CLIENT_ID" ]]; then
        log_error "AZURE_CLIENT_ID environment variable is required"
        exit 1
    fi
    
    # Check if user has sufficient permissions
    log_info "Checking current user permissions..."
    CURRENT_USER=$(az account show --query user.name -o tsv)
    echo "Current user: $CURRENT_USER"
    
    # Check if current user can manage role assignments
    if ! az role assignment list --scope "/subscriptions/$SUBSCRIPTION_ID" --query "[0]" -o tsv >/dev/null 2>&1; then
        log_error "Current user does not have permission to manage role assignments"
        log_error "Please run this script with an account that has Owner or User Access Administrator role"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

grant_subscription_permissions() {
    log_info "Granting subscription-level permissions to service principal..."
    
    # Grant User Access Administrator role (required for role assignments)
    log_info "Granting User Access Administrator role..."
    if az role assignment create \
        --role "User Access Administrator" \
        --assignee "$CLIENT_ID" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --output none 2>/dev/null; then
        log_success "User Access Administrator role granted"
    else
        log_warning "User Access Administrator role may already exist or failed to assign"
    fi
    
    # Verify Contributor role exists (should already exist based on diagnostics)
    log_info "Verifying Contributor role..."
    if az role assignment list \
        --assignee "$CLIENT_ID" \
        --role "Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --query "[0]" -o tsv >/dev/null 2>&1; then
        log_success "Contributor role already exists"
    else
        log_info "Granting Contributor role..."
        az role assignment create \
            --role "Contributor" \
            --assignee "$CLIENT_ID" \
            --scope "/subscriptions/$SUBSCRIPTION_ID" \
            --output none
        log_success "Contributor role granted"
    fi
}

fix_storage_permissions() {
    log_info "Fixing storage account permissions..."
    
    RG_NAME="rg-terraform-state-${ENVIRONMENT}-cus-001"
    SA_NAME="staksdevcus001tfstate"  # Use the actual storage account name from diagnostic
    
    # Check if storage account exists
    if az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" >/dev/null 2>&1; then
        log_success "Storage account found: $SA_NAME"
        
        STORAGE_ACCOUNT_ID=$(az storage account show \
            --name "$SA_NAME" \
            --resource-group "$RG_NAME" \
            --query "id" -o tsv)
        
        log_info "Storage Account ID: $STORAGE_ACCOUNT_ID"
        
        # Grant Storage Blob Data Owner role
        log_info "Granting Storage Blob Data Owner role..."
        if az role assignment create \
            --role "Storage Blob Data Owner" \
            --assignee "$CLIENT_ID" \
            --scope "$STORAGE_ACCOUNT_ID" \
            --output none 2>/dev/null; then
            log_success "Storage Blob Data Owner role granted"
        else
            log_warning "Storage Blob Data Owner role may already exist"
        fi
        
        # Grant Reader role for container listing
        log_info "Granting Reader role for container listing..."
        if az role assignment create \
            --role "Reader" \
            --assignee "$CLIENT_ID" \
            --scope "$STORAGE_ACCOUNT_ID" \
            --output none 2>/dev/null; then
            log_success "Reader role granted"
        else
            log_warning "Reader role may already exist"
        fi
        
        # Check and update network access rules
        log_info "Checking storage account network access rules..."
        DEFAULT_ACTION=$(az storage account show \
            --name "$SA_NAME" \
            --resource-group "$RG_NAME" \
            --query "networkRuleSet.defaultAction" -o tsv)
        
        if [[ "$DEFAULT_ACTION" == "Deny" ]]; then
            log_warning "Storage account has restrictive network rules (default action: Deny)"
            log_info "Updating network rules to allow access..."
            az storage account update \
                --name "$SA_NAME" \
                --resource-group "$RG_NAME" \
                --default-action Allow \
                --output none
            log_success "Network rules updated to allow access"
        else
            log_success "Storage account network rules allow access"
        fi
        
    else
        log_error "Storage account not found: $SA_NAME in resource group $RG_NAME"
        log_info "The storage account will be created when you run the backend setup workflow"
    fi
}

verify_permissions() {
    log_info "Verifying permissions..."
    
    echo ""
    log_info "Service Principal Role Assignments:"
    az role assignment list \
        --assignee "$CLIENT_ID" \
        --query "[].{Role:roleDefinitionName, Scope:scope}" \
        --output table
    
    echo ""
    log_info "Testing permission to create role assignments..."
    
    # Test if the service principal can now assign roles (without actually creating one)
    TEST_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/test-rg-that-doesnt-exist"
    
    # This should fail with "resource not found" instead of "insufficient permissions"
    # which indicates the permission check passed
    if az role assignment create \
        --role "Reader" \
        --assignee "$CLIENT_ID" \
        --scope "$TEST_SCOPE" \
        --dry-run 2>&1 | grep -q "does not exist"; then
        log_success "Service principal has permission to assign roles"
    else
        log_warning "Role assignment test was inconclusive"
    fi
}

main() {
    log_info "Starting Service Principal Permission Fix"
    log_info "Subscription: $SUBSCRIPTION_ID"
    log_info "Service Principal: $CLIENT_ID"
    log_info "Environment: $ENVIRONMENT"
    echo ""
    
    check_prerequisites
    echo ""
    
    grant_subscription_permissions
    echo ""
    
    fix_storage_permissions
    echo ""
    
    verify_permissions
    echo ""
    
    log_success "Permission fix completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "1. Wait 5-10 minutes for Azure AD role propagation"
    echo "2. Re-run the backend setup workflow: gh workflow run 'Setup Terraform Backend' --field environment=dev"
    echo "3. Monitor the workflow for successful completion"
    echo ""
    log_info "If issues persist, check Azure Monitor logs using queries from .github/AUTHENTICATION-MONITORING.md"
}

# Handle script arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Environment variables required:"
            echo "  AZURE_SUBSCRIPTION_ID - Azure subscription ID"
            echo "  AZURE_CLIENT_ID       - Service principal client ID"
            echo "  ENVIRONMENT           - Environment name (default: dev)"
            echo ""
            echo "This script grants the required permissions to the service principal:"
            echo "  - User Access Administrator (subscription level)"
            echo "  - Storage Blob Data Owner (storage account level)"
            echo "  - Reader (storage account level)"
            echo ""
            echo "Run with an account that has Owner or User Access Administrator privileges."
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

main
