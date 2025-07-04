#!/bin/bash

# Federated Identity Setup Script for GitHub Actions
# This script creates a User-Assigned Managed Identity with Federated Credentials
# for secure GitHub Actions authentication to Azure (no secrets required)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MANAGED_IDENTITY_NAME="github-actions-terraform-aks"
RESOURCE_GROUP_NAME="rg-github-actions-identity"
REPO_NAME=""  # Will be prompted
SUBSCRIPTION_ID=""  # Will be detected
LOCATION="Central US"

echo -e "${BLUE}🔐 Azure Federated Identity Setup for GitHub Actions${NC}"
echo -e "${YELLOW}Using User-Assigned Managed Identity (Best Practice)${NC}"
echo ""

# Check if Azure CLI is installed and user is logged in
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure CLI. Run 'az login' first${NC}"
    exit 1
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "${YELLOW}Current Azure subscription:${NC}"
echo "Name: $SUBSCRIPTION_NAME"
echo "ID: $SUBSCRIPTION_ID"
echo "Tenant: $TENANT_ID"
echo ""

# Prompt for repository name
read -p "Enter your GitHub repository name (owner/repo): " REPO_NAME
if [ -z "$REPO_NAME" ]; then
    echo -e "${RED}Error: Repository name is required${NC}"
    exit 1
fi

# Extract owner and repo
REPO_OWNER=$(echo $REPO_NAME | cut -d'/' -f1)
REPO=$(echo $REPO_NAME | cut -d'/' -f2)

echo ""
echo -e "${YELLOW}Creating Resource Group for Managed Identity...${NC}"

# Create resource group for the managed identity
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags Purpose="GitHub Actions Identity" Project="aks-private" ManagedBy="Terraform" \
    --output table || true

echo ""
echo -e "${YELLOW}Creating User-Assigned Managed Identity...${NC}"

# Create User-Assigned Managed Identity
IDENTITY_OUTPUT=$(az identity create \
    --name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags Purpose="GitHub Actions Authentication" Project="aks-private" Repository="$REPO_NAME" \
    --output json)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Managed Identity created successfully!${NC}"
else
    echo -e "${RED}❌ Failed to create Managed Identity${NC}"
    exit 1
fi

# Extract values from output
CLIENT_ID=$(echo $IDENTITY_OUTPUT | jq -r '.clientId')
PRINCIPAL_ID=$(echo $IDENTITY_OUTPUT | jq -r '.principalId')
IDENTITY_ID=$(echo $IDENTITY_OUTPUT | jq -r '.id')

echo ""
echo -e "${YELLOW}📋 Managed Identity Details:${NC}"
echo "Name: $MANAGED_IDENTITY_NAME"
echo "Client ID: $CLIENT_ID"
echo "Principal ID: $PRINCIPAL_ID"
echo "Resource ID: $IDENTITY_ID"
echo ""

echo -e "${YELLOW}Assigning Contributor role to Managed Identity...${NC}"

# Assign Contributor role to the managed identity
az role assignment create \
    --assignee-object-id "$PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --description "GitHub Actions access for $REPO_NAME" \
    --output table

echo ""
echo -e "${YELLOW}Creating Federated Identity Credentials...${NC}"

# Create federated credential for main branch
echo "Creating credential for main branch..."
az identity federated-credential create \
    --name "github-main-branch" \
    --identity-name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --issuer "https://token.actions.githubusercontent.com" \
    --subject "repo:$REPO_NAME:ref:refs/heads/main" \
    --description "GitHub Actions main branch access" \
    --audiences "api://AzureADTokenExchange" \
    --output table

# Create federated credential for pull requests
echo "Creating credential for pull requests..."
az identity federated-credential create \
    --name "github-pull-requests" \
    --identity-name "$MANAGED_IDENTITY_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --issuer "https://token.actions.githubusercontent.com" \
    --subject "repo:$REPO_NAME:pull_request" \
    --description "GitHub Actions pull request access" \
    --audiences "api://AzureADTokenExchange" \
    --output table

# Create federated credential for environment deployments
for env in dev staging prod; do
    echo "Creating credential for $env environment..."
    az identity federated-credential create \
        --name "github-env-$env" \
        --identity-name "$MANAGED_IDENTITY_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --issuer "https://token.actions.githubusercontent.com" \
        --subject "repo:$REPO_NAME:environment:$env" \
        --description "GitHub Actions $env environment access" \
        --audiences "api://AzureADTokenExchange" \
        --output table || true
done

echo ""
echo -e "${GREEN}✅ Federated Identity setup completed successfully!${NC}"
echo ""

# Create GitHub secrets configuration
echo -e "${YELLOW}🔑 GitHub Secrets Configuration:${NC}"
echo ""
echo "Add the following secrets to your GitHub repository:"
echo "Repository: https://github.com/$REPO_NAME/settings/secrets/actions"
echo ""

cat << EOF
AZURE_CLIENT_ID:
$CLIENT_ID

AZURE_SUBSCRIPTION_ID:
$SUBSCRIPTION_ID

AZURE_TENANT_ID:
$TENANT_ID
EOF

echo ""
echo -e "${BLUE}📋 Benefits of Federated Identity:${NC}"
echo "✅ No long-lived secrets to manage"
echo "✅ Automatic token rotation"
echo "✅ Scoped to specific repositories and branches"
echo "✅ Enhanced security with OIDC"
echo "✅ Audit trail in Azure AD"
echo ""

# Save to file for reference
cat << EOF > github-federated-identity.txt
GitHub Federated Identity Configuration for Repository: $REPO_NAME
Generated on: $(date)

=== GITHUB SECRETS (Repository Level) ===
AZURE_CLIENT_ID:
$CLIENT_ID

AZURE_SUBSCRIPTION_ID:
$SUBSCRIPTION_ID

AZURE_TENANT_ID:
$TENANT_ID

=== AZURE RESOURCES CREATED ===
Resource Group: $RESOURCE_GROUP_NAME
Managed Identity Name: $MANAGED_IDENTITY_NAME
Managed Identity Client ID: $CLIENT_ID
Managed Identity Principal ID: $PRINCIPAL_ID
Managed Identity Resource ID: $IDENTITY_ID

=== FEDERATED CREDENTIALS CREATED ===
1. github-main-branch
   - Subject: repo:$REPO_NAME:ref:refs/heads/main
   - Purpose: Main branch deployments

2. github-pull-requests
   - Subject: repo:$REPO_NAME:pull_request
   - Purpose: Pull request validations

3. github-env-dev
   - Subject: repo:$REPO_NAME:environment:dev
   - Purpose: Development environment deployments

4. github-env-staging
   - Subject: repo:$REPO_NAME:environment:staging
   - Purpose: Staging environment deployments

5. github-env-prod
   - Subject: repo:$REPO_NAME:environment:prod
   - Purpose: Production environment deployments

=== PERMISSIONS ===
Role: Contributor
Scope: /subscriptions/$SUBSCRIPTION_ID
Description: GitHub Actions access for $REPO_NAME

=== NEXT STEPS ===
1. Add the 3 secrets above to GitHub repository: https://github.com/$REPO_NAME/settings/secrets/actions
2. Update GitHub Actions workflows to use azure/login@v2 with federated identity
3. Set up GitHub environments (dev, staging, prod)
4. Run the "Setup Terraform Backend" workflow
5. Run the "Terraform Plan & Apply" workflow

=== SECURITY BENEFITS ===
- No client secrets to rotate (OIDC tokens are short-lived)
- Scoped access to specific repository and branches/environments
- Enhanced audit trail in Azure AD
- Follows Microsoft's recommended best practices
- Eliminates secret sprawl and management overhead

=== WORKFLOW AUTHENTICATION ===
Your workflows will use this authentication pattern:
  - uses: azure/login@v2
    with:
      client-id: \${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: \${{ secrets.AZURE_TENANT_ID }}
      subscription-id: \${{ secrets.AZURE_SUBSCRIPTION_ID }}
EOF

echo -e "${GREEN}✅ Configuration saved to: github-federated-identity.txt${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "- No AZURE_CLIENT_SECRET needed (federated identity uses OIDC tokens)"
echo "- Tokens are automatically rotated and short-lived"
echo "- Access is scoped to your specific repository and branches"
echo "- Monitor access in Azure AD sign-in logs"
echo ""
echo -e "${GREEN}🚀 Ready for secure deployment! Update your workflows and run them.${NC}"
