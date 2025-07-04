#!/bin/bash

# GitHub Secrets Setup Script for Federated Identity
# Uses GitHub CLI to set repository secrets for OIDC authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 GitHub Repository Secrets Setup (Federated Identity)${NC}"
echo ""

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Check if Azure CLI is available and user is logged in
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure CLI${NC}"
    echo "Run: az login"
    exit 1
fi

# Get current repository info
REPO_INFO=$(gh repo view --json owner,name)
REPO_OWNER=$(echo $REPO_INFO | jq -r '.owner.login')
REPO_NAME=$(echo $REPO_INFO | jq -r '.name')

echo -e "${YELLOW}Repository: ${REPO_OWNER}/${REPO_NAME}${NC}"
echo ""

# Get Azure information
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Get managed identity client ID
MANAGED_IDENTITY_NAME="github-actions-terraform-aks"
RESOURCE_GROUP_NAME="rg-github-actions-identity"

echo -e "${BLUE}Looking for managed identity...${NC}"
CLIENT_ID=$(az identity show --name "$MANAGED_IDENTITY_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query clientId -o tsv 2>/dev/null || echo "")

if [ -z "$CLIENT_ID" ]; then
    echo -e "${RED}Error: Managed identity not found${NC}"
    echo "Please run the setup-federated-identity.sh script first"
    exit 1
fi
echo -e "${GREEN}✅ Found managed identity: ${CLIENT_ID}${NC}"
echo ""

# Display the values that will be set
echo -e "${YELLOW}The following secrets will be set in ${REPO_OWNER}/${REPO_NAME}:${NC}"
echo "- AZURE_CLIENT_ID: $CLIENT_ID"
echo "- AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "- AZURE_TENANT_ID: $TENANT_ID"
echo ""
echo -e "${BLUE}Note: No AZURE_CLIENT_SECRET needed for federated identity!${NC}"
echo ""

# Confirm before proceeding
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo -e "${BLUE}Setting GitHub repository secrets...${NC}"

# Set each secret
echo "Setting AZURE_CLIENT_ID..."
echo "$CLIENT_ID" | gh secret set AZURE_CLIENT_ID

echo "Setting AZURE_SUBSCRIPTION_ID..."
echo "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID

echo "Setting AZURE_TENANT_ID..."
echo "$TENANT_ID" | gh secret set AZURE_TENANT_ID

echo ""
echo -e "${GREEN}✅ All secrets have been set successfully!${NC}"

# Verify secrets were set
echo ""
echo -e "${BLUE}Verifying secrets...${NC}"
gh secret list

echo ""
echo -e "${GREEN}🎉 GitHub repository secrets setup complete!${NC}"
echo ""
echo -e "${YELLOW}✅ What was configured:${NC}"
echo "- Federated identity authentication (no client secrets!)"
echo "- 3 GitHub repository secrets for OIDC"
echo "- Secure, modern authentication following 2025 best practices"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run the 'Setup Terraform Backend' workflow"
echo "2. Deploy your infrastructure with Terraform!"
echo ""
echo -e "${BLUE}Environment-specific secrets (optional):${NC}"
echo "You may also want to set environment-specific secrets in:"
echo "- Repository Settings → Environments → dev/staging/prod"
echo "- This allows different Azure subscriptions per environment"
echo ""
echo -e "${GREEN}🔐 Security benefits achieved:${NC}"
echo "✅ No long-lived secrets to rotate"
echo "✅ OIDC tokens are automatically managed"
echo "✅ Scoped access to repository and branches"
echo "✅ Enhanced audit trail in Azure AD"
