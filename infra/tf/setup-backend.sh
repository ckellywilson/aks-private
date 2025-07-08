#!/bin/bash

# Backend Setup Script for AKS Terraform Deployment
# Configuration: aks-private in Central US (dev-001)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${ENVIRONMENT:-dev}"
RESOURCE_GROUP_NAME="rg-terraform-state-${ENVIRONMENT}-cus-001"
STORAGE_ACCOUNT_NAME="staks${ENVIRONMENT}cus001tfstate"
CONTAINER_NAME="terraform-state"
LOCATION="Central US"
FORCE_RECREATE="${FORCE_RECREATE:-false}"

echo -e "${YELLOW}Setting up Azure Storage backend for Terraform state...${NC}"
echo "Environment: ${ENVIRONMENT}"
echo "Force Recreate: ${FORCE_RECREATE}"

# Check if Azure CLI is installed and user is logged in
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure CLI. Run 'az login' first${NC}"
    exit 1
fi

# Show current subscription
echo -e "${YELLOW}Current Azure subscription:${NC}"
az account show --query '{name:name, id:id}' -o table

# Check for existing resources
echo -e "${YELLOW}Checking for existing resources...${NC}"

RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP_NAME" || echo "false")
if [ "$RG_EXISTS" == "true" ]; then
    echo -e "${GREEN}✅ Resource group already exists: ${RESOURCE_GROUP_NAME}${NC}"
    if [ "$FORCE_RECREATE" == "true" ]; then
        echo -e "${YELLOW}⚠️  Force recreate enabled - will update existing resources${NC}"
    fi
else
    echo -e "${YELLOW}📦 Resource group will be created: ${RESOURCE_GROUP_NAME}${NC}"
fi

SA_EXISTS=$(az storage account check-name --name "$STORAGE_ACCOUNT_NAME" --query 'nameAvailable' -o tsv || echo "true")
if [ "$SA_EXISTS" == "false" ]; then
    echo -e "${GREEN}✅ Storage account already exists: ${STORAGE_ACCOUNT_NAME}${NC}"
else
    echo -e "${YELLOW}📦 Storage account will be created: ${STORAGE_ACCOUNT_NAME}${NC}"
fi

# Create resource group
echo -e "${YELLOW}Creating resource group: ${RESOURCE_GROUP_NAME}${NC}"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags Environment=dev Project=aks-private ManagedBy=Terraform Owner="DevOps Team" CostCenter=IT-Infrastructure Purpose="Terraform State Storage" Instance=001 \
    --output table || true

# Create storage account
echo -e "${YELLOW}Creating storage account: ${STORAGE_ACCOUNT_NAME}${NC}"
az storage account create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --tags Environment=dev Project=aks-private ManagedBy=Terraform Owner="DevOps Team" CostCenter=IT-Infrastructure Purpose="Terraform State Storage" Instance=001 \
    --output table || true

# Enable versioning
echo -e "${YELLOW}Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable-versioning true \
    --output none || true

# Create container
echo -e "${YELLOW}Creating storage container: ${CONTAINER_NAME}${NC}"
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --public-access off \
    --auth-mode login \
    --output table || true

# Assign storage permissions to managed identity for OIDC access
echo -e "${YELLOW}Assigning storage permissions to managed identity...${NC}"
MANAGED_IDENTITY_PRINCIPAL_ID=$(az identity show \
    --name "id-terraform-backend-${ENVIRONMENT}-cus-001" \
    --resource-group "rg-terraform-backend-identity-cus-001" \
    --query principalId -o tsv 2>/dev/null || echo "")

if [ -n "$MANAGED_IDENTITY_PRINCIPAL_ID" ]; then
    echo "Found managed identity principal ID: $MANAGED_IDENTITY_PRINCIPAL_ID"
    
    # Get storage account resource ID
    STORAGE_ACCOUNT_ID=$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)
    
    echo "Assigning Storage Blob Data Contributor role..."
    az role assignment create \
        --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output table || echo "⚠️ Role assignment may already exist"
    
    echo "Assigning Storage Account Contributor role..."
    az role assignment create \
        --assignee "$MANAGED_IDENTITY_PRINCIPAL_ID" \
        --role "Storage Account Contributor" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output table || echo "⚠️ Role assignment may already exist"
    
    echo -e "${GREEN}✅ Storage permissions assigned to managed identity${NC}"
else
    echo -e "${YELLOW}⚠️ Managed identity not found - permissions may need to be assigned manually${NC}"
    echo "Run this command manually:"
    echo "az role assignment create --assignee <managed-identity-principal-id> --role 'Storage Blob Data Contributor' --scope '$STORAGE_ACCOUNT_ID'"
fi

# Also assign permissions to GitHub Actions service principal for workflow testing
if [ -n "${AZURE_CLIENT_ID:-}" ]; then
    echo -e "${YELLOW}Assigning storage permissions to GitHub Actions service principal for testing...${NC}"
    
    # Get storage account resource ID if not already set
    STORAGE_ACCOUNT_ID=${STORAGE_ACCOUNT_ID:-$(az storage account show \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query id -o tsv)}
    
    echo "GitHub Actions service principal: $AZURE_CLIENT_ID"
    echo "Assigning Storage Blob Data Reader role for testing..."
    az role assignment create \
        --assignee "$AZURE_CLIENT_ID" \
        --role "Storage Blob Data Reader" \
        --scope "$STORAGE_ACCOUNT_ID" \
        --output table || echo "⚠️ Role assignment may already exist or insufficient permissions"
    
    echo -e "${GREEN}✅ GitHub Actions service principal permissions configured${NC}"
else
    echo -e "${YELLOW}⚠️ AZURE_CLIENT_ID not set - GitHub Actions testing permissions not configured${NC}"
    echo "For testing access in workflows, manually assign 'Storage Blob Data Reader' role to the GitHub Actions service principal"
fi

# Enable diagnostic logging for authentication troubleshooting
echo -e "${YELLOW}Enabling Azure Monitor diagnostic logging...${NC}"
LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace list \
    --query "[0].id" -o tsv 2>/dev/null || echo "")

if [ -n "$LOG_ANALYTICS_WORKSPACE_ID" ]; then
    echo "Found Log Analytics workspace: $LOG_ANALYTICS_WORKSPACE_ID"
    
    # Create diagnostic setting for storage account
    az monitor diagnostic-settings create \
        --name "terraform-backend-diagnostics" \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" \
        --workspace "$LOG_ANALYTICS_WORKSPACE_ID" \
        --logs '[
            {
                "category": "StorageRead",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageWrite", 
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageDelete",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --metrics '[
            {
                "category": "Transaction",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --output table || echo "⚠️ Could not create diagnostic settings (may already exist)"
    
    # Also enable blob service diagnostics
    az monitor diagnostic-settings create \
        --name "terraform-backend-blob-diagnostics" \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default" \
        --workspace "$LOG_ANALYTICS_WORKSPACE_ID" \
        --logs '[
            {
                "category": "StorageRead",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageWrite",
                "enabled": true, 
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageDelete",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --output table || echo "⚠️ Could not create blob diagnostic settings (may already exist)"
    
    echo -e "${GREEN}✅ Diagnostic logging enabled for authentication troubleshooting${NC}"
    echo -e "${YELLOW}📋 You can query logs in Azure Monitor with:${NC}"
    echo "StorageBlobLogs | where TimeGenerated > ago(1h) | where StatusCode >= 400"
    echo "StorageAccountLogs | where TimeGenerated > ago(1h) | where StatusCode >= 400"
else
    echo -e "${YELLOW}⚠️ No Log Analytics workspace found - creating basic logging${NC}"
    echo -e "${YELLOW}💡 Consider creating a Log Analytics workspace for better diagnostics${NC}"
fi

# Create backend configuration file
echo -e "${YELLOW}Creating backend configuration...${NC}"
cat > backend-config.txt << EOF
# Backend Configuration for aks-private Terraform State
# Generated on: $(date)

resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "${ENVIRONMENT}.tfstate"
EOF

echo -e "${GREEN}Backend setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Backend Configuration Details:${NC}"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "State File: ${ENVIRONMENT}.tfstate"
echo ""
echo -e "${YELLOW}Backend configuration saved to: backend-config.txt${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Review the backend.tf file in your Terraform configuration"
echo "2. Run 'terraform init' to initialize with the backend"
echo "3. Run 'terraform plan' to create your deployment plan"
echo ""
echo -e "${YELLOW}To migrate existing local state to the backend:${NC}"
echo "terraform init -migrate-state"
echo ""
echo -e "${GREEN}Backend setup is ready for aks-private deployment!${NC}"
