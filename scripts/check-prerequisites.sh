#!/bin/bash

# Prerequisites Validation Script
# This script checks that all prerequisites are met before running setup scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating Terraform Backend Setup Readiness${NC}"
echo ""

VALIDATION_ERRORS=0

# Check if running from correct directory
if [[ ! -f "scripts/setup-terraform-backend-identity.sh" ]]; then
    echo -e "${RED}❌ Must run from repository root directory${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check required tools
echo -e "${YELLOW}🔧 Checking required tools...${NC}"

tools=("az" "gh" "jq" "curl")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool: Available"
    else
        echo -e "${RED}❌ $tool: Not found${NC}"
        ((VALIDATION_ERRORS++))
    fi
done

# Check Azure CLI authentication
echo ""
echo -e "${YELLOW}🔐 Checking Azure CLI authentication...${NC}"
if az account show &> /dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    echo "✅ Azure CLI: Authenticated (Subscription: $SUBSCRIPTION)"
else
    echo -e "${RED}❌ Azure CLI: Not authenticated - run 'az login'${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check GitHub CLI authentication
echo ""
echo -e "${YELLOW}🐙 Checking GitHub CLI authentication...${NC}"
if gh auth status &> /dev/null; then
    GITHUB_USER=$(gh api user --jq .login 2>/dev/null || echo "Unknown")
    echo "✅ GitHub CLI: Authenticated (User: $GITHUB_USER)"
else
    echo -e "${RED}❌ GitHub CLI: Not authenticated - run 'gh auth login'${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check GitHub repository access
echo ""
echo -e "${YELLOW}📁 Checking GitHub repository access...${NC}"
if gh repo view &> /dev/null; then
    REPO_NAME=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
    echo "✅ Repository: $REPO_NAME"
    
    # Check if user has admin permissions
    if gh api repos/$REPO_NAME/collaborators/$(gh api user --jq .login) --jq .permissions.admin 2>/dev/null | grep -q true; then
        echo "✅ Permissions: Admin access confirmed"
    else
        echo -e "${RED}❌ Permissions: Admin access required for setting up environments and secrets${NC}"
        ((VALIDATION_ERRORS++))
    fi
else
    echo -e "${RED}❌ Repository: Cannot access current repository${NC}"
    ((VALIDATION_ERRORS++))
fi

# Check file permissions
echo ""
echo -e "${YELLOW}📄 Checking file permissions...${NC}"
if [[ -x "scripts/setup-terraform-backend-identity.sh" ]]; then
    echo "✅ Script executable: setup-terraform-backend-identity.sh"
else
    echo -e "${YELLOW}⚠️ Script not executable - fixing...${NC}"
    chmod +x scripts/setup-terraform-backend-identity.sh
    echo "✅ Fixed: setup-terraform-backend-identity.sh is now executable"
fi

# Check workflow files
echo ""
echo -e "${YELLOW}⚙️ Checking workflow files...${NC}"
workflows=(
    ".github/workflows/setup-terraform-backend.yml"
    ".github/workflows/test-oidc.yml"
)

for workflow in "${workflows[@]}"; do
    if [[ -f "$workflow" ]]; then
        echo "✅ Workflow: $workflow exists"
    else
        echo -e "${RED}❌ Workflow: $workflow missing${NC}"
        ((VALIDATION_ERRORS++))
    fi
done

# Check Azure subscription permissions
echo ""
echo -e "${YELLOW}🔑 Checking Azure subscription permissions...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Test if user can create resource groups (requires Contributor role)
TEST_RG_NAME="test-permissions-$(date +%s)"
if az group create --name "$TEST_RG_NAME" --location "Central US" --dry-run &> /dev/null; then
    echo "✅ Azure Permissions: Can create resource groups"
else
    echo -e "${RED}❌ Azure Permissions: Insufficient permissions to create resource groups${NC}"
    echo "   Required: Contributor role at subscription level"
    ((VALIDATION_ERRORS++))
fi

# Summary
echo ""
echo "================================================================"
if [[ $VALIDATION_ERRORS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All validation checks passed!${NC}"
    echo ""
    echo -e "${YELLOW}🚀 Ready to execute:${NC}"
    echo "1. ./scripts/setup-github-environments.sh (if not done already)"
    echo "2. ./scripts/setup-terraform-backend-identity.sh"
    echo "3. Use GitHub Actions workflows for backend setup"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "• Run the setup scripts in the recommended order"
    echo "• Check the generated summary files for configuration details"
    echo "• Test OIDC authentication using the test workflow"
else
    echo -e "${RED}❌ Validation failed with $VALIDATION_ERRORS error(s)${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Fix the above issues before proceeding${NC}"
    exit 1
fi
echo "================================================================"
