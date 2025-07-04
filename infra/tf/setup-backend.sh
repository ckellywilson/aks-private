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
    --output table || true

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

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
echo -e "${YELLOW}Environment Variables (optional):${NC}"
echo "export ARM_ACCESS_KEY=\"$STORAGE_KEY\""
echo ""
echo -e "${GREEN}Backend setup is ready for aks-private deployment!${NC}"
