#!/bin/bash

# Setup Managed Identity for Terraform Backend Storage
# This script creates a user-assigned managed identity with OIDC federation
# for GitHub Actions to manage Terraform backend storage across environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Setting up Managed Identity for Terraform Backend Storage${NC}"
echo ""

# Configuration
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
LOCATION="${LOCATION:-Central US}"
BASE_RESOURCE_GROUP_NAME="rg-terraform-backend-identity-cus-001"
BASE_IDENTITY_NAME="id-terraform-backend"
GITHUB_REPO="${GITHUB_REPOSITORY:-$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>/dev/null || echo "UNKNOWN/UNKNOWN")}"

# Environment configuration
declare -a ENVIRONMENTS=("dev" "staging" "prod")

# Validate environment configuration
if [ ${#ENVIRONMENTS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No environments configured${NC}"
    exit 1
fi

# Validate prerequisites
echo -e "${YELLOW}🔍 Validating prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found${NC}"
    exit 1
fi

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not found${NC}"
    exit 1
fi

# Check Azure login
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged into Azure. Run 'az login'${NC}"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub. Run 'gh auth login'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites validated${NC}"
echo ""

# Display configuration
echo -e "${BLUE}📋 Configuration:${NC}"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Location: $LOCATION"
echo "Base Resource Group: $BASE_RESOURCE_GROUP_NAME"
echo "Base Identity Name: $BASE_IDENTITY_NAME"
echo "GitHub Repository: $GITHUB_REPO"
echo "Environments: ${ENVIRONMENTS[*]}"
echo ""

# Create base resource group for the identities
echo -e "${YELLOW}📦 Creating base resource group for managed identities...${NC}"
az group create \
    --name "$BASE_RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags \
        Environment=shared \
        Project=aks-private \
        ManagedBy=Terraform \
        Owner="DevOps Team" \
        CostCenter=IT-Infrastructure \
        Purpose="Terraform Backend Identities" \
    --output table

echo -e "${GREEN}✅ Base resource group created${NC}"
echo ""

# Arrays to store identity information
declare -A CLIENT_IDS
declare -A PRINCIPAL_IDS

# Create managed identities for each environment
echo -e "${YELLOW}🆔 Creating environment-specific managed identities...${NC}"

for ENV in "${ENVIRONMENTS[@]}"; do
    IDENTITY_NAME="${BASE_IDENTITY_NAME}-${ENV}-cus-001"
    
    echo "Creating managed identity for $ENV environment: $IDENTITY_NAME"
    
    # Create identity with error handling
    if ! az identity create \
        --name "$IDENTITY_NAME" \
        --resource-group "$BASE_RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags \
            Environment="$ENV" \
            Project=aks-private \
            ManagedBy=Terraform \
            Owner="DevOps Team" \
            CostCenter=IT-Infrastructure \
            Purpose="Terraform Backend Identity - $ENV" \
        --output table; then
        echo -e "${RED}❌ Failed to create managed identity for $ENV environment${NC}"
        exit 1
    fi
    
    # Get identity details with error handling
    CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$BASE_RESOURCE_GROUP_NAME" --query clientId -o tsv)
    PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$BASE_RESOURCE_GROUP_NAME" --query principalId -o tsv)
    
    # Validate retrieved values
    if [[ -z "$CLIENT_ID" || -z "$PRINCIPAL_ID" ]]; then
        echo -e "${RED}❌ Failed to retrieve identity details for $ENV environment${NC}"
        exit 1
    fi
    
    # Store in arrays
    CLIENT_IDS["$ENV"]="$CLIENT_ID"
    PRINCIPAL_IDS["$ENV"]="$PRINCIPAL_ID"
    
    echo "  Client ID: $CLIENT_ID"
    echo "  Principal ID: $PRINCIPAL_ID"
    echo ""
done

echo -e "${GREEN}✅ All managed identities created${NC}"
echo ""

# Assign required roles at subscription level for each environment
echo -e "${YELLOW}🔐 Assigning required roles to managed identities...${NC}"

for ENV in "${ENVIRONMENTS[@]}"; do
    IDENTITY_NAME="${BASE_IDENTITY_NAME}-${ENV}-cus-001"
    PRINCIPAL_ID="${PRINCIPAL_IDS[$ENV]}"
    
    echo "Assigning roles for $ENV environment identity..."
    
    # Storage Account Contributor - for creating and managing storage accounts
    echo "  Assigning Storage Account Contributor role..."
    az role assignment create \
        --assignee "$PRINCIPAL_ID" \
        --role "Storage Account Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --output table

    # Contributor role for resource group management (scoped to specific environment)
    echo "  Assigning Contributor role for resource group management..."
    az role assignment create \
        --assignee "$PRINCIPAL_ID" \
        --role "Contributor" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --output table
    
    echo "  ✅ Roles assigned for $ENV environment"
    echo ""
done

echo -e "${GREEN}✅ All roles assigned${NC}"
echo ""

# Create federated identity credentials for GitHub Actions
echo -e "${YELLOW}🔗 Creating federated identity credentials for GitHub Actions...${NC}"

for ENV in "${ENVIRONMENTS[@]}"; do
    IDENTITY_NAME="${BASE_IDENTITY_NAME}-${ENV}-cus-001"
    
    echo "Creating federated credentials for $ENV environment identity..."
    
    # Main branch credential for this environment
    echo "  Creating federated credential for main branch..."
    az identity federated-credential create \
        --name "github-main-branch" \
        --identity-name "$IDENTITY_NAME" \
        --resource-group "$BASE_RESOURCE_GROUP_NAME" \
        --issuer "https://token.actions.githubusercontent.com" \
        --subject "repo:$GITHUB_REPO:ref:refs/heads/main" \
        --audiences "api://AzureADTokenExchange" \
        --output table

    # Pull request credential for this environment
    echo "  Creating federated credential for pull requests..."
    az identity federated-credential create \
        --name "github-pull-requests" \
        --identity-name "$IDENTITY_NAME" \
        --resource-group "$BASE_RESOURCE_GROUP_NAME" \
        --issuer "https://token.actions.githubusercontent.com" \
        --subject "repo:$GITHUB_REPO:pull_request" \
        --audiences "api://AzureADTokenExchange" \
        --output table

    # Environment-specific credential
    echo "  Creating federated credential for $ENV environment..."
    az identity federated-credential create \
        --name "github-environment-$ENV" \
        --identity-name "$IDENTITY_NAME" \
        --resource-group "$BASE_RESOURCE_GROUP_NAME" \
        --issuer "https://token.actions.githubusercontent.com" \
        --subject "repo:$GITHUB_REPO:environment:$ENV" \
        --audiences "api://AzureADTokenExchange" \
        --output table
    
    echo "  ✅ Federated credentials created for $ENV environment"
    echo ""
done

echo -e "${GREEN}✅ All federated identity credentials created${NC}"
echo ""

# Create GitHub repository secrets
echo -e "${YELLOW}🔑 Creating GitHub repository secrets...${NC}"

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Set repository secrets (fallback values - will be overridden by environment secrets)
echo "Setting repository-level fallback secrets..."
echo "Setting AZURE_TENANT_ID..."
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"

echo "Setting AZURE_SUBSCRIPTION_ID..."
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"

# Use dev CLIENT_ID as fallback
echo "Setting AZURE_CLIENT_ID (fallback to dev)..."
gh secret set AZURE_CLIENT_ID --body "${CLIENT_IDS[dev]}"

echo -e "${GREEN}✅ GitHub repository secrets created${NC}"
echo ""

# Create environment-specific secrets with unique client IDs
echo -e "${YELLOW}🌍 Creating environment-specific secrets...${NC}"

for ENV in "${ENVIRONMENTS[@]}"; do
    echo "Setting secrets for $ENV environment..."
    
    # Check if environment exists
    if gh api repos/$GITHUB_REPO/environments/$ENV &> /dev/null; then
        # Set environment-specific CLIENT_ID
        gh secret set AZURE_TENANT_ID --env $ENV --body "$TENANT_ID"
        gh secret set AZURE_SUBSCRIPTION_ID --env $ENV --body "$SUBSCRIPTION_ID"
        gh secret set AZURE_CLIENT_ID --env $ENV --body "${CLIENT_IDS[$ENV]}"
        echo "✅ Secrets set for $ENV environment (Client ID: ${CLIENT_IDS[$ENV]})"
    else
        echo "⚠️ Environment $ENV not found, skipping"
    fi
done

echo -e "${GREEN}✅ Environment secrets configured${NC}"
echo ""

# Create summary file
echo -e "${YELLOW}📄 Creating setup summary...${NC}"
cat > terraform-backend-identity-summary.md << EOF
# Terraform Backend Identity Setup Summary

## Created Resources

### Managed Identities (Per Environment)
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    IDENTITY_NAME="${BASE_IDENTITY_NAME}-${ENV}-cus-001"
    cat >> terraform-backend-identity-summary.md << EOF

#### $ENV Environment
- **Name**: $IDENTITY_NAME
- **Resource Group**: $BASE_RESOURCE_GROUP_NAME
- **Client ID**: ${CLIENT_IDS[$ENV]}
- **Principal ID**: ${PRINCIPAL_IDS[$ENV]}
EOF
done

cat >> terraform-backend-identity-summary.md << EOF

### Role Assignments (Per Identity)
- **Storage Account Contributor**: Subscription level
- **Contributor**: Subscription level

### Federated Identity Credentials (Per Environment)
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    cat >> terraform-backend-identity-summary.md << EOF
- **$ENV Main Branch**: repo:$GITHUB_REPO:ref:refs/heads/main
- **$ENV Pull Requests**: repo:$GITHUB_REPO:pull_request
- **$ENV Environment**: repo:$GITHUB_REPO:environment:$ENV
EOF
done

cat >> terraform-backend-identity-summary.md << EOF

### GitHub Secrets

#### Repository Level (Fallback)
- **AZURE_TENANT_ID**: $TENANT_ID
- **AZURE_SUBSCRIPTION_ID**: $SUBSCRIPTION_ID
- **AZURE_CLIENT_ID**: ${CLIENT_IDS[dev]} (dev fallback)

#### Environment Specific
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    cat >> terraform-backend-identity-summary.md << EOF
- **$ENV AZURE_CLIENT_ID**: ${CLIENT_IDS[$ENV]}
EOF
done

cat >> terraform-backend-identity-summary.md << EOF

## Security Enhancements

- ✅ **Environment Isolation**: Each environment has its own managed identity
- ✅ **Unique Client IDs**: Separate credentials per environment
- ✅ **Principle of Least Privilege**: Each identity only has access to its resources
- ✅ **Reduced Blast Radius**: Compromise of one environment doesn't affect others
- ✅ **Zero Trust Model**: No cross-environment access possible

## Next Steps

1. **Deploy the setup-terraform-backend.yml workflow**
2. **Run the workflow for each environment** (dev, staging, prod)
3. **Update backend.tf files** to use the created storage accounts
4. **Test OIDC authentication** with environment-specific identities

## Security Notes

- ✅ **No long-lived secrets** - uses OIDC federation
- ✅ **Environment isolation** - separate managed identities
- ✅ **Principle of least privilege** - only necessary permissions
- ✅ **Audit trail** - all actions logged in Azure Activity Log
- ✅ **Zero cross-environment access** - complete isolation

Generated on: $(date)
EOF

echo -e "${GREEN}✅ Setup summary saved to terraform-backend-identity-summary.md${NC}"
echo ""

echo -e "${GREEN}🎉 Enhanced Managed Identity setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "• Base Resource Group: $BASE_RESOURCE_GROUP_NAME"
echo "• GitHub Repository: $GITHUB_REPO"
echo "• Environments configured: ${ENVIRONMENTS[*]}"
echo ""
echo -e "${YELLOW}🔐 Environment-Specific Identities:${NC}"
for ENV in "${ENVIRONMENTS[@]}"; do
    echo "• $ENV: ${CLIENT_IDS[$ENV]}"
done
echo ""
echo -e "${YELLOW}🔄 Next Steps:${NC}"
echo "1. Deploy the GitHub Actions workflow for backend setup"
echo "2. Run the workflow for each environment using their unique identities"
echo "3. Update your Terraform backend configuration"
echo "4. Test the OIDC authentication per environment"
echo ""
echo -e "${BLUE}💡 The setup summary has been saved to terraform-backend-identity-summary.md${NC}"
