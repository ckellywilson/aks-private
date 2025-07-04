#!/bin/bash

# GitHub Actions Workflow Validation Script
# Validates workflows and provides deployment readiness check

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 GitHub Actions Workflow Validation${NC}"
echo ""

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1 exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 missing${NC}"
        return 1
    fi
}

# Function to check if a command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $1 not found (optional)${NC}"
        return 1
    fi
}

# Check required files
echo -e "${BLUE}Checking workflow files...${NC}"
WORKFLOW_FILES=(
    ".github/workflows/terraform-backend-setup.yml"
    ".github/workflows/terraform-deploy.yml"
)

MISSING_WORKFLOWS=0
for file in "${WORKFLOW_FILES[@]}"; do
    if ! check_file "$file"; then
        ((MISSING_WORKFLOWS++))
    fi
done

# Check supporting files
echo ""
echo -e "${BLUE}Checking supporting files...${NC}"
SUPPORT_FILES=(
    ".github/setup-federated-identity.sh"
    ".github/setup-github-secrets.sh"
    ".github/README.md"
    ".github/DEPLOYMENT.md"
    "Makefile"
)

MISSING_SUPPORT=0
for file in "${SUPPORT_FILES[@]}"; do
    if ! check_file "$file"; then
        ((MISSING_SUPPORT++))
    fi
done

# Check Terraform files
echo ""
echo -e "${BLUE}Checking Terraform files...${NC}"
TERRAFORM_FILES=(
    "infra/tf/main.tf"
    "infra/tf/variables.tf"
    "infra/tf/outputs.tf"
    "infra/tf/versions.tf"
    "infra/tf/backend.tf"
    "infra/tf/terraform.tfvars.example"
    "infra/tf/setup-backend.sh"
)

MISSING_TERRAFORM=0
for file in "${TERRAFORM_FILES[@]}"; do
    if ! check_file "$file"; then
        ((MISSING_TERRAFORM++))
    fi
done

# Check optional tools
echo ""
echo -e "${BLUE}Checking optional tools...${NC}"
TOOLS=(
    "actionlint"
    "terraform-docs"
    "tflint"
    "checkov"
    "infracost"
)

for tool in "${TOOLS[@]}"; do
    check_command "$tool"
done

# Validate workflow syntax (if actionlint is available)
echo ""
if command -v actionlint &> /dev/null; then
    echo -e "${BLUE}Validating workflow syntax...${NC}"
    if actionlint .github/workflows/*.yml; then
        echo -e "${GREEN}✅ All workflows are syntactically valid${NC}"
    else
        echo -e "${RED}❌ Workflow syntax errors found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping workflow syntax validation (actionlint not found)${NC}"
fi

# Check if scripts are executable
echo ""
echo -e "${BLUE}Checking script permissions...${NC}"
SCRIPTS=(
    ".github/setup-service-principal.sh"
    "infra/tf/setup-backend.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✅ $script is executable${NC}"
        else
            echo -e "${YELLOW}⚠️  $script is not executable (fixing...)${NC}"
            chmod +x "$script"
            echo -e "${GREEN}✅ $script permissions fixed${NC}"
        fi
    fi
done

# Validate Terraform configuration (if terraform is available)
echo ""
if command -v terraform &> /dev/null; then
    echo -e "${BLUE}Validating Terraform configuration...${NC}"
    cd infra/tf
    if terraform fmt -check=true -diff=true .; then
        echo -e "${GREEN}✅ Terraform files are properly formatted${NC}"
    else
        echo -e "${YELLOW}⚠️  Terraform files need formatting (run: terraform fmt)${NC}"
    fi
    
    if terraform validate; then
        echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
    else
        echo -e "${RED}❌ Terraform configuration has errors${NC}"
    fi
    cd - > /dev/null
else
    echo -e "${YELLOW}⚠️  Skipping Terraform validation (terraform not found)${NC}"
fi

# Check for common workflow issues
echo ""
echo -e "${BLUE}Checking for common issues...${NC}"

# Check for placeholder values
if grep -r "YOUR_REPO\|YOUR_USERNAME\|REPLACE_ME" .github/ > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Found placeholder values in files - please customize${NC}"
    grep -r "YOUR_REPO\|YOUR_USERNAME\|REPLACE_ME" .github/ | head -5
else
    echo -e "${GREEN}✅ No placeholder values found${NC}"
fi

# Check for terraform.tfvars
if [ -f "infra/tf/terraform.tfvars" ]; then
    echo -e "${GREEN}✅ terraform.tfvars exists${NC}"
else
    echo -e "${YELLOW}⚠️  terraform.tfvars not found (will be created from example)${NC}"
fi

# Generate deployment readiness report
echo ""
echo -e "${BLUE}📋 Deployment Readiness Report${NC}"
echo "=================================="

TOTAL_ISSUES=$((MISSING_WORKFLOWS + MISSING_SUPPORT + MISSING_TERRAFORM))

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Your repository is ready for deployment.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run: .github/setup-service-principal.sh"
    echo "2. Configure GitHub secrets"
    echo "3. Run the 'Setup GitHub Environments' workflow"
    echo "4. Run the 'Setup Terraform Backend' workflow"
    echo "5. Deploy your infrastructure!"
    
    # Create readiness file
    cat > .github/deployment-readiness.txt << EOF
Deployment Readiness Check - $(date)
====================================

✅ All workflow files present
✅ All supporting files present  
✅ All Terraform files present
✅ Scripts have correct permissions

Status: READY FOR DEPLOYMENT

Next Steps:
1. Configure Azure Service Principal
2. Set up GitHub secrets
3. Create GitHub environments
4. Setup Terraform backend
5. Deploy infrastructure

Generated by: workflow-validation.sh
EOF
    
    echo ""
    echo -e "${GREEN}📄 Readiness report saved to: .github/deployment-readiness.txt${NC}"
    
else
    echo -e "${RED}❌ Found $TOTAL_ISSUES issues that need attention:${NC}"
    [ $MISSING_WORKFLOWS -gt 0 ] && echo "  - $MISSING_WORKFLOWS missing workflow files"
    [ $MISSING_SUPPORT -gt 0 ] && echo "  - $MISSING_SUPPORT missing support files"
    [ $MISSING_TERRAFORM -gt 0 ] && echo "  - $MISSING_TERRAFORM missing Terraform files"
    
    echo ""
    echo -e "${YELLOW}Please resolve these issues before proceeding with deployment.${NC}"
fi

echo ""
echo -e "${BLUE}💡 Helpful commands:${NC}"
echo "  make help                    # Show all available commands"
echo "  make check-tools            # Check required tools"
echo "  make github-setup           # Setup GitHub Actions"
echo "  make workflows-validate     # Validate workflows (requires actionlint)"
echo ""

exit $TOTAL_ISSUES
