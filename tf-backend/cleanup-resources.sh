#!/bin/bash

# Resource Cleanup Script
# Cleans up orphaned resources and old backups to optimize costs

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
Usage: $0 [options]

Clean up orphaned resources and old backups across all environments.

Options:
  -s, --subscription-id    Azure subscription ID
  -d, --dry-run           Show what would be cleaned up without executing
  -a, --age-days          Age threshold in days for cleanup (default: 30)
  -e, --environment       Specific environment to clean (dev, staging, prod, all)
  -f, --force             Force cleanup without confirmation
  -v, --verbose           Verbose output
  -h, --help              Show this help message

Examples:
  $0 -s 12345678-1234-1234-1234-123456789012 --dry-run
  $0 -s 12345678-1234-1234-1234-123456789012 --age-days 7 --environment dev
  $0 -s 12345678-1234-1234-1234-123456789012 --force
EOF
}

cleanup_orphaned_container_instances() {
    local ENV=$1
    local AGE_DAYS=$2
    local DRY_RUN=$3
    
    log_info "Cleaning up orphaned container instances for $ENV environment (older than $AGE_DAYS days)..."
    
    local RG_NAME="rg-terraform-state-${ENV}-eus-001"
    local CUTOFF_TIME=$(date -d "${AGE_DAYS} days ago" --iso-8601)
    
    # Find container instances older than threshold
    local CONTAINER_INSTANCES=$(az container list \
        --resource-group "$RG_NAME" \
        --query "[?creationTime<'$CUTOFF_TIME' && contains(name, 'github-runner')].{name:name, created:creationTime}" \
        --output json 2>/dev/null || echo "[]")
    
    local COUNT=$(echo "$CONTAINER_INSTANCES" | jq length)
    
    if [ "$COUNT" -eq 0 ]; then
        log_info "No orphaned container instances found for $ENV"
        return 0
    fi
    
    log_warning "Found $COUNT orphaned container instances in $ENV"
    
    if [ "$VERBOSE" = true ]; then
        echo "$CONTAINER_INSTANCES" | jq -r '.[] | "  - \(.name) (created: \(.created))"'
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would delete $COUNT container instances"
        return 0
    fi
    
    # Delete orphaned container instances
    echo "$CONTAINER_INSTANCES" | jq -r '.[].name' | while read -r name; do
        if [ -n "$name" ]; then
            log_info "Deleting orphaned container instance: $name"
            az container delete --name "$name" --resource-group "$RG_NAME" --yes || log_warning "Failed to delete $name"
        fi
    done
    
    log_success "Completed container instance cleanup for $ENV"
}

cleanup_old_terraform_artifacts() {
    local ENV=$1
    local AGE_DAYS=$2
    local DRY_RUN=$3
    
    log_info "Cleaning up old Terraform artifacts for $ENV environment..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would clean up Terraform artifacts older than $AGE_DAYS days"
        find . -name "*.tfplan" -mtime +$AGE_DAYS 2>/dev/null || true
        find . -name ".terraform" -type d -mtime +$AGE_DAYS 2>/dev/null || true
        return 0
    fi
    
    # Clean up old terraform plan files
    local PLAN_COUNT=$(find . -name "*.tfplan" -mtime +$AGE_DAYS 2>/dev/null | wc -l)
    if [ "$PLAN_COUNT" -gt 0 ]; then
        log_info "Removing $PLAN_COUNT old Terraform plan files"
        find . -name "*.tfplan" -mtime +$AGE_DAYS -delete 2>/dev/null || true
    fi
    
    # Clean up old terraform directories
    local TERRAFORM_COUNT=$(find . -name ".terraform" -type d -mtime +$AGE_DAYS 2>/dev/null | wc -l)
    if [ "$TERRAFORM_COUNT" -gt 0 ]; then
        log_info "Removing $TERRAFORM_COUNT old .terraform directories"
        find . -name ".terraform" -type d -mtime +$AGE_DAYS -exec rm -rf {} + 2>/dev/null || true
    fi
    
    log_success "Completed Terraform artifacts cleanup"
}

cleanup_old_container_images() {
    local ENV=$1
    local AGE_DAYS=$2
    local DRY_RUN=$3
    
    if [ "$ENV" = "dev" ]; then
        log_info "Skipping container image cleanup for dev environment (no ACR)"
        return 0
    fi
    
    log_info "Cleaning up old container images for $ENV environment..."
    
    local ACR_NAME="acrterraform${ENV}eus001"
    
    # Check if ACR exists
    if ! az acr show --name "$ACR_NAME" &>/dev/null; then
        log_warning "ACR $ACR_NAME not found, skipping image cleanup"
        return 0
    fi
    
    # Get old images
    local OLD_IMAGES=$(az acr repository list --name "$ACR_NAME" --output tsv 2>/dev/null || echo "")
    
    if [ -z "$OLD_IMAGES" ]; then
        log_info "No repositories found in ACR $ACR_NAME"
        return 0
    fi
    
    for repo in $OLD_IMAGES; do
        log_info "Checking repository: $repo"
        
        # List tags older than threshold
        local OLD_TAGS=$(az acr repository show-manifests \
            --name "$ACR_NAME" \
            --repository "$repo" \
            --query "[?lastUpdateTime<'$(date -d "${AGE_DAYS} days ago" --iso-8601)'].tags[0]" \
            --output tsv 2>/dev/null || echo "")
        
        if [ -n "$OLD_TAGS" ]; then
            local TAG_COUNT=$(echo "$OLD_TAGS" | wc -w)
            log_info "Found $TAG_COUNT old tags in $repo"
            
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would delete old tags: $OLD_TAGS"
            else
                for tag in $OLD_TAGS; do
                    if [ -n "$tag" ] && [ "$tag" != "latest" ]; then
                        log_info "Deleting old image tag: $repo:$tag"
                        az acr repository delete --name "$ACR_NAME" --image "$repo:$tag" --yes 2>/dev/null || log_warning "Failed to delete $repo:$tag"
                    fi
                done
            fi
        fi
    done
    
    log_success "Completed container image cleanup for $ENV"
}

cleanup_old_log_data() {
    local ENV=$1
    local AGE_DAYS=$2
    local DRY_RUN=$3
    
    log_info "Log data is automatically managed by Azure Log Analytics retention policies"
    log_info "Current retention for $ENV environment: configured via workspace settings"
}

# Parse command line arguments
SUBSCRIPTION_ID=""
DRY_RUN=false
AGE_DAYS=30
ENVIRONMENT="all"
FORCE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -a|--age-days)
            AGE_DAYS="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$SUBSCRIPTION_ID" ]; then
    log_error "Subscription ID is required"
    usage
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod|all)$ ]]; then
    log_error "Environment must be one of: dev, staging, prod, all"
    exit 1
fi

# Validate age days
if [ "$AGE_DAYS" -lt 1 ]; then
    log_error "Age days must be at least 1"
    exit 1
fi

# Set up Azure CLI
log_info "Setting up Azure CLI for subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Display configuration
log_info "Cleanup Configuration:"
log_info "  Subscription: $SUBSCRIPTION_ID"
log_info "  Environment: $ENVIRONMENT"
log_info "  Age Threshold: $AGE_DAYS days"
log_info "  Dry Run: $DRY_RUN"
log_info "  Force: $FORCE"

# Confirm before proceeding
if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ]; then
    echo
    log_warning "This will permanently delete resources older than $AGE_DAYS days!"
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
fi

# Determine environments to process
if [ "$ENVIRONMENT" = "all" ]; then
    ENVIRONMENTS=("dev" "staging" "prod")
else
    ENVIRONMENTS=("$ENVIRONMENT")
fi

# Process each environment
for env in "${ENVIRONMENTS[@]}"; do
    log_info "Processing $env environment..."
    
    cleanup_orphaned_container_instances "$env" "$AGE_DAYS" "$DRY_RUN"
    cleanup_old_container_images "$env" "$AGE_DAYS" "$DRY_RUN"
    cleanup_old_log_data "$env" "$AGE_DAYS" "$DRY_RUN"
done

# Global cleanup (not environment-specific)
cleanup_old_terraform_artifacts "global" "$AGE_DAYS" "$DRY_RUN"

# Summary
echo
log_success "Resource cleanup completed!"
log_info "Processed environments: ${ENVIRONMENTS[*]}"
log_info "Age threshold: $AGE_DAYS days"

if [ "$DRY_RUN" = true ]; then
    log_info "This was a dry run - no resources were actually deleted"
    log_info "Run without --dry-run to perform actual cleanup"
fi

echo
log_info "Cleanup recommendations:"
log_info "1. Run cleanup regularly (weekly/monthly)"
log_info "2. Monitor costs after cleanup"
log_info "3. Adjust age thresholds based on your needs"
log_info "4. Review backup retention policies"
