#!/bin/bash

# Terraform Backend Bootstrap Script
# This script sets up the Azure storage backend for Terraform state management
# Run this script once per environment with an account that has Owner privileges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_LOCATION="Central US"
DEFAULT_ENVIRONMENTS="dev staging prod"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               Terraform Backend Bootstrap                    ║${NC}"
echo -e "${BLUE}║          Azure Storage Account Setup Script                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}$1${NC}"
    echo "$(printf '=%.0s' {1..60})"
}

# Function to print step
print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
print_section "CHECKING PREREQUISITES"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
print_step "Azure CLI is installed"

# Check if user is logged in
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure CLI"
    echo "Please run 'az login' first"
    exit 1
fi
print_step "Logged in to Azure CLI"

# Show current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
USER_NAME=$(az account show --query user.name -o tsv)

echo ""
echo "Current context:"
echo "  Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "  User: $USER_NAME"
echo ""

# Confirm subscription
read -p "Continue with this subscription? (y/N): " CONFIRM_SUB
if [[ ! "$CONFIRM_SUB" =~ ^[Yy]$ ]]; then
    echo "Please switch to the correct subscription with 'az account set --subscription <subscription-id>'"
    exit 0
fi

# Check permissions
print_section "VERIFYING PERMISSIONS"

echo "Checking current user permissions..."
USER_ROLES=$(az role assignment list --assignee "$USER_NAME" --include-inherited --query '[].roleDefinitionName' -o tsv 2>/dev/null || echo "")

HAS_OWNER=false
HAS_CONTRIBUTOR=false
HAS_USER_ACCESS_ADMIN=false

if echo "$USER_ROLES" | grep -qi "Owner"; then
    HAS_OWNER=true
    print_step "Has Owner role"
fi

if echo "$USER_ROLES" | grep -qi "Contributor"; then
    HAS_CONTRIBUTOR=true
    print_step "Has Contributor role"
fi

if echo "$USER_ROLES" | grep -qi "User Access Administrator"; then
    HAS_USER_ACCESS_ADMIN=true
    print_step "Has User Access Administrator role"
fi

if [ "$HAS_OWNER" = false ] && ([ "$HAS_CONTRIBUTOR" = false ] || [ "$HAS_USER_ACCESS_ADMIN" = false ]); then
    print_warning "You may not have sufficient permissions"
    echo "Required: Owner OR (Contributor + User Access Administrator)"
    echo "Current roles:"
    echo "$USER_ROLES" | sed 's/^/  - /'
    echo ""
    read -p "Continue anyway? (y/N): " CONTINUE_ANYWAY
    if [[ ! "$CONTINUE_ANYWAY" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Get configuration
print_section "CONFIGURATION"

# Environment selection
echo "Available environments: $DEFAULT_ENVIRONMENTS"
echo "You can set up multiple environments in one run."
echo ""
read -p "Enter environments to set up (space-separated) [$DEFAULT_ENVIRONMENTS]: " ENVIRONMENTS
ENVIRONMENTS=${ENVIRONMENTS:-$DEFAULT_ENVIRONMENTS}

# Location
read -p "Enter Azure region [$DEFAULT_LOCATION]: " LOCATION
LOCATION=${LOCATION:-$DEFAULT_LOCATION}

# GitHub Actions Service Principal (optional)
echo ""
echo "GitHub Actions Service Principal Configuration (optional):"
echo "If you want to configure GitHub Actions permissions, provide the service principal ID."
echo "This is the AZURE_CLIENT_ID from your GitHub repository secrets."
echo ""
read -p "GitHub Actions Client ID (optional): " GITHUB_CLIENT_ID

echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  Environments: $ENVIRONMENTS"
echo "  Location: $LOCATION"
echo "  GitHub Actions SP: ${GITHUB_CLIENT_ID:-Not configured}"
echo ""
read -p "Proceed with this configuration? (y/N): " CONFIRM_CONFIG
if [[ ! "$CONFIRM_CONFIG" =~ ^[Yy]$ ]]; then
    echo "Configuration cancelled"
    exit 0
fi

# Setup function for each environment
setup_environment() {
    local ENV=$1
    
    print_section "SETTING UP ENVIRONMENT: $ENV"
    
    # Resource names
    local RESOURCE_GROUP_NAME="rg-terraform-state-${ENV}-cus-001"
    local STORAGE_ACCOUNT_NAME="staks${ENV}cus001tfstate"
    local CONTAINER_NAME="terraform-state"
    local MANAGED_IDENTITY_NAME="id-terraform-${ENV}-cus-001"
    local STATE_KEY="${ENV}/terraform.tfstate"
    
    echo "Resource Configuration:"
    echo "  Resource Group: $RESOURCE_GROUP_NAME"
    echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "  Container: $CONTAINER_NAME"
    echo "  Managed Identity: $MANAGED_IDENTITY_NAME"
    echo "  State Key: $STATE_KEY"
    echo ""
    
    # Create resource group
    echo "Creating resource group..."
    if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
        print_step "Resource group already exists"
    else
        az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output table
        print_step "Resource group created"
    fi
    
    # Create storage account
    echo "Creating storage account..."
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        print_step "Storage account already exists"
    else
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
            --output table
        print_step "Storage account created with security features enabled"
    fi
    
    # Enable versioning
    echo "Enabling blob versioning..."
    az storage account blob-service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --enable-versioning true \
        --output none
    print_step "Blob versioning enabled"
    
    # Create container
    echo "Creating blob container..."
    CONTAINER_EXISTS=$(az storage container exists \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login \
        --query exists -o tsv 2>/dev/null || echo "false")
    
    if [ "$CONTAINER_EXISTS" = "true" ]; then
        print_step "Container already exists"
    else
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --auth-mode login \
            --output table
        print_step "Container created"
    fi
    
    # Create managed identity
    echo "Creating managed identity..."
    if az identity show --name "$MANAGED_IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
        print_step "Managed identity already exists"
    else
        az identity create \
            --name "$MANAGED_IDENTITY_NAME" \
            --resource-group "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --output table
        print_step "Managed identity created"
    fi
    
    # Get managed identity principal ID
    MANAGED_IDENTITY_PRINCIPAL_ID=$(az identity show \
        --name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query principalId -o tsv)
    
    MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
        --name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query clientId -o tsv)
    
    # Get storage account resource ID
    STORAGE_ACCOUNT_ID=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    # Assign storage permissions to managed identity
    echo "Assigning storage permissions to managed identity..."
    
    # Storage Blob Data Contributor
    az role assignment create \
        --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output table 2>/dev/null || print_warning "Storage Blob Data Contributor role may already be assigned"
    
    # Storage Account Contributor
    az role assignment create \
        --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
        --role "Storage Account Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output table 2>/dev/null || print_warning "Storage Account Contributor role may already be assigned"
    
    print_step "Managed identity permissions configured"
    
    # Assign minimal permissions to GitHub Actions service principal (if provided)
    if [ -n "$GITHUB_CLIENT_ID" ]; then
        echo "Configuring GitHub Actions service principal permissions..."
        
        # Storage Blob Data Reader (minimal for testing)
        az role assignment create \
            --assignee "$GITHUB_CLIENT_ID" \
            --role "Storage Blob Data Reader" \
            --scope "$STORAGE_ACCOUNT_ID" \
            --output table 2>/dev/null || print_warning "GitHub Actions role may already be assigned"
        
        # Reader role at resource group level
        az role assignment create \
            --assignee "$GITHUB_CLIENT_ID" \
            --role "Reader" \
            --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME" \
            --output table 2>/dev/null || print_warning "GitHub Actions Reader role may already be assigned"
        
        print_step "GitHub Actions service principal permissions configured"
    fi
    
    # Generate backend configuration
    echo "Generating backend configuration..."
    
    local BACKEND_CONFIG_DIR="../../infra/tf/environments/$ENV"
    mkdir -p "$BACKEND_CONFIG_DIR"
    
    cat > "$BACKEND_CONFIG_DIR/backend.tf" << EOF
# Terraform Backend Configuration for $ENV environment
# Generated by bootstrap script on $(date)

terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$STATE_KEY"
    use_oidc             = true
  }
}
EOF

    cat > "$BACKEND_CONFIG_DIR/backend-config.txt" << EOF
resource_group_name = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name = "$CONTAINER_NAME"
key = "$STATE_KEY"
managed_identity_client_id = "$MANAGED_IDENTITY_CLIENT_ID"
EOF

    cat > "$BACKEND_CONFIG_DIR/terraform.tfvars" << EOF
# Terraform Variables for $ENV environment
# Generated by bootstrap script on $(date)

environment = "$ENV"
location = "$LOCATION"
managed_identity_client_id = "$MANAGED_IDENTITY_CLIENT_ID"
EOF

    print_step "Backend configuration files generated in $BACKEND_CONFIG_DIR"
    
    # Create environment summary
    local SUMMARY_FILE="terraform-backend-summary-$ENV.md"
    cat > "$SUMMARY_FILE" << EOF
# Terraform Backend Summary - $ENV Environment

**Created:** $(date)
**Location:** $LOCATION
**Subscription:** $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)

## Resources Created

| Resource Type | Name | Resource ID |
|---------------|------|-------------|
| Resource Group | $RESOURCE_GROUP_NAME | /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME |
| Storage Account | $STORAGE_ACCOUNT_NAME | $STORAGE_ACCOUNT_ID |
| Blob Container | $CONTAINER_NAME | $STORAGE_ACCOUNT_ID/blobServices/default/containers/$CONTAINER_NAME |
| Managed Identity | $MANAGED_IDENTITY_NAME | /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$MANAGED_IDENTITY_NAME |

## Configuration

### Backend Configuration
\`\`\`hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$STATE_KEY"
    use_oidc             = true
  }
}
\`\`\`

### Managed Identity
- **Client ID:** $MANAGED_IDENTITY_CLIENT_ID
- **Principal ID:** $MANAGED_IDENTITY_PRINCIPAL_ID

### GitHub Secrets Required
\`\`\`
AZURE_CLIENT_ID = "$MANAGED_IDENTITY_CLIENT_ID"
AZURE_SUBSCRIPTION_ID = "$SUBSCRIPTION_ID"
AZURE_TENANT_ID = "$(az account show --query tenantId -o tsv)"
\`\`\`

## Security Features Enabled

- ✅ **Encryption at rest:** Enabled by default
- ✅ **Blob versioning:** Enabled
- ✅ **HTTPS only:** Enforced
- ✅ **Public blob access:** Disabled
- ✅ **Shared key access:** Disabled
- ✅ **Minimum TLS version:** 1.2

## Next Steps

1. **Update GitHub Secrets:** Add the secrets listed above to your GitHub repository
2. **Copy backend.tf:** Use the generated file in \`infra/tf/environments/$ENV/backend.tf\`
3. **Initialize Terraform:** Run \`terraform init\` in your Terraform directory
4. **Test the setup:** Run \`terraform plan\` to verify everything works

## Permissions Assigned

### Managed Identity ($MANAGED_IDENTITY_NAME)
- Storage Blob Data Contributor (on storage account)
- Storage Account Contributor (on storage account)

$(if [ -n "$GITHUB_CLIENT_ID" ]; then
echo "### GitHub Actions Service Principal"
echo "- Storage Blob Data Reader (on storage account)"
echo "- Reader (on resource group)"
fi)

---
Generated by Terraform Backend Bootstrap Script
EOF

    print_step "Summary document created: $SUMMARY_FILE"
    
    echo ""
    echo -e "${GREEN}🎉 Environment $ENV setup completed successfully!${NC}"
    echo ""
}

# Main execution
print_section "EXECUTING BOOTSTRAP"

# Process each environment
for ENV in $ENVIRONMENTS; do
    setup_environment "$ENV"
done

# Final summary
print_section "BOOTSTRAP COMPLETED"

echo -e "${GREEN}🎉 All environments have been set up successfully!${NC}"
echo ""
echo "Generated files:"
for ENV in $ENVIRONMENTS; do
    echo "  📁 infra/tf/environments/$ENV/"
    echo "    - backend.tf"
    echo "    - backend-config.txt"
    echo "    - terraform.tfvars"
    echo "  📄 terraform-backend-summary-$ENV.md"
done
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the generated summary documents"
echo "2. Update GitHub repository secrets with the managed identity details"
echo "3. Copy the backend.tf files to your Terraform configurations"
echo "4. Test the setup by running terraform init and terraform plan"
echo ""
echo -e "${BLUE}Happy Terraforming! 🚀${NC}"
