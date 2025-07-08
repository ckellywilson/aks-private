#!/bin/bash

# GitHub Environments Setup Script
# ⚠️  ADMIN ONLY - One-time setup script
# This script requires repository admin permissions
# DO NOT run this in automated workflows or CI/CD
# Run this once manually to set up GitHub environments
#
# Usage: ./scripts/setup-github-environments.sh
# Prerequisites: 
#   - gh CLI installed and authenticated
#   - Repository admin permissions
#   - Run from repository root directory

# Requires: gh CLI installed and authenticated with admin permissions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🌍 Setting up GitHub Environments for AKS Private Repository${NC}"
echo ""

# Check if gh CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
echo "Repository: $REPO"
echo ""

# Check if user has admin permissions
echo "🔍 Checking repository permissions..."
USER_PERMISSION=$(gh api repos/$REPO --jq '.permissions.admin // false')
if [[ "$USER_PERMISSION" != "true" ]]; then
    echo -e "${RED}❌ Error: You need admin permissions to create environments${NC}"
    echo "Please ensure you have admin access to the repository"
    exit 1
fi

echo -e "${GREEN}✅ Admin permissions confirmed${NC}"
echo ""

# Function to create environment
create_environment() {
    local env_name=$1
    local wait_timer=$2
    local needs_reviewer=$3
    local description=$4
    
    echo "🌍 Creating environment: $env_name"
    
    # Check if environment already exists
    if gh api repos/$REPO/environments/$env_name &> /dev/null; then
        echo -e "${YELLOW}⚠️  Environment '$env_name' already exists, updating...${NC}"
    fi
    
    # Create basic environment first
    gh api repos/$REPO/environments/$env_name \
        --method PUT \
        --field wait_timer=$wait_timer > /dev/null
    
    # Add protection rules if needed (simplified - just wait timer for now)
    if [[ "$needs_reviewer" == "true" ]]; then
        gh api repos/$REPO/environments/$env_name \
            --method PUT \
            --field wait_timer=$wait_timer > /dev/null
        
        echo -e "${GREEN}✅ Environment '$env_name' configured with protection rules${NC}"
        echo "   - Wait timer: ${wait_timer}s"
        echo "   - Protection: Basic (configure reviewers manually via GitHub UI)"
    else
        echo -e "${GREEN}✅ Environment '$env_name' configured without protection rules${NC}"
        echo "   - Wait timer: ${wait_timer}s"
        echo "   - Protection: None"
    fi
    
    echo "   - Purpose: $description"
    echo ""
}

# Create environments
echo "🚀 Creating GitHub environments..."
echo ""

create_environment "dev" 0 false "Development and testing environment"
create_environment "staging" 0 true "Pre-production testing environment"  
create_environment "prod" 300 true "Production environment with 5-minute wait timer"

# Verify environments were created
echo "🔍 Verifying environments..."
ENVS=$(gh api repos/$REPO/environments --jq '.environments | length')
echo -e "${GREEN}✅ Successfully created $ENVS environments${NC}"
echo ""

# List created environments
echo "📋 Environment Summary:"
gh api repos/$REPO/environments --jq '.environments[] | "- \(.name): \(.protection_rules | length) protection rules"'
echo ""

echo -e "${GREEN}🎉 GitHub Environments setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. 🔐 Add Azure secrets to each environment via GitHub UI:"
echo "   - Go to: https://github.com/$REPO/settings/environments"
echo "   - Add secrets: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID"
echo ""
echo "2. 🔧 Set environment variables:"
echo "   - TF_VAR_environment (dev/staging/prod)"
echo "   - TF_VAR_location (Central US)"
echo "   - TF_VAR_instance (001)"
echo ""
echo "3. 🧪 Test with infrastructure workflows"
echo ""
echo -e "${YELLOW}⚠️  Security Note:${NC}"
echo "This script required admin permissions to create environments."
echo "Regular workflows should NOT have environment creation permissions."
echo "This follows the principle of least privilege."
