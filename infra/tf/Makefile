# Makefile for AKS Terraform Deployment
# Configuration: aks37921 in Central US (dev)

.PHONY: help init plan apply destroy validate fmt clean setup-backend check-tools

# Default environment
ENV ?= dev
TF_VAR_FILE ?= terraform.tfvars

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target
help: ## Display available targets and usage
	@echo "$(GREEN)AKS Terraform Deployment Makefile$(NC)"
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage examples:$(NC)"
	@echo "  make init              # Initialize Terraform"
	@echo "  make plan              # Plan deployment"
	@echo "  make apply             # Deploy infrastructure"
	@echo "  make destroy           # Destroy infrastructure"
	@echo "  make ENV=staging plan  # Plan for staging environment"

check-tools: ## Check if required tools are installed
	@echo "$(YELLOW)Checking required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)terraform is not installed$(NC)"; exit 1; }
	@command -v az >/dev/null 2>&1 || { echo "$(RED)Azure CLI is not installed$(NC)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl is not installed$(NC)"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "$(RED)helm is not installed$(NC)"; exit 1; }
	@echo "$(GREEN)All required tools are installed$(NC)"

setup-backend: check-tools ## Setup Azure Storage backend for Terraform state
	@echo "$(YELLOW)Setting up Azure Storage backend...$(NC)"
	@if [ -f "./setup-backend.sh" ]; then \
		echo "$(YELLOW)Running backend setup script...$(NC)"; \
		./setup-backend.sh; \
	else \
		echo "$(YELLOW)Creating storage account for Terraform state...$(NC)"; \
		az group create --name rg-terraform-state --location "Central US" || true; \
		az storage account create \
			--resource-group rg-terraform-state \
			--name staksdevcus001tfstate \
			--sku Standard_LRS \
			--encryption-services blob \
			--https-only true \
			--min-tls-version TLS1_2 \
			--allow-blob-public-access false || true; \
		az storage account blob-service-properties update \
			--account-name staksdevcus001tfstate \
			--enable-versioning true || true; \
		az storage container create \
			--name terraform-state \
			--account-name staksdevcus001tfstate \
			--public-access off || true; \
		echo "$(GREEN)Backend setup complete$(NC)"; \
	fi

init: check-tools ## Initialize Terraform and download providers
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)Terraform initialized$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Configuration is valid$(NC)"

fmt: ## Format Terraform code
	@echo "$(YELLOW)Formatting Terraform code...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Code formatted$(NC)"

plan: validate ## Run terraform plan with appropriate var files
	@echo "$(YELLOW)Planning Terraform deployment for $(ENV) environment...$(NC)"
	@if [ ! -f "$(TF_VAR_FILE)" ]; then \
		echo "$(RED)Variable file $(TF_VAR_FILE) not found. Please copy terraform.tfvars.example to $(TF_VAR_FILE)$(NC)"; \
		exit 1; \
	fi
	terraform plan -var-file="$(TF_VAR_FILE)" -out="$(ENV).tfplan"
	@echo "$(GREEN)Plan saved to $(ENV).tfplan$(NC)"

apply: ## Deploy infrastructure with confirmation
	@echo "$(YELLOW)Applying Terraform deployment for $(ENV) environment...$(NC)"
	@if [ ! -f "$(ENV).tfplan" ]; then \
		echo "$(RED)Plan file $(ENV).tfplan not found. Please run 'make plan' first$(NC)"; \
		exit 1; \
	fi
	terraform apply "$(ENV).tfplan"
	@echo "$(GREEN)Infrastructure deployed successfully$(NC)"
	@echo "$(YELLOW)Getting AKS credentials...$(NC)"
	@$(MAKE) get-credentials

apply-auto: plan ## Deploy infrastructure without manual confirmation (use with caution)
	@echo "$(YELLOW)Auto-applying Terraform deployment...$(NC)"
	terraform apply -auto-approve -var-file="$(TF_VAR_FILE)"
	@echo "$(GREEN)Infrastructure deployed successfully$(NC)"

destroy: ## Clean up all resources
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@read -p "Are you sure you want to continue? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	terraform destroy -var-file="$(TF_VAR_FILE)"
	@echo "$(GREEN)Infrastructure destroyed$(NC)"

get-credentials: ## Get AKS cluster credentials
	@echo "$(YELLOW)Getting AKS credentials...$(NC)"
	@RG_NAME=$$(terraform output -raw resource_group_name 2>/dev/null || echo "rg-aks-dev-cus-001"); \
	CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null || echo "aks37921"); \
	az aks get-credentials --resource-group $$RG_NAME --name $$CLUSTER_NAME --overwrite-existing
	@echo "$(GREEN)Credentials configured for kubectl$(NC)"

verify-cluster: get-credentials ## Verify cluster is accessible and healthy
	@echo "$(YELLOW)Verifying cluster health...$(NC)"
	kubectl cluster-info
	kubectl get nodes
	kubectl get pods --all-namespaces
	@echo "$(GREEN)Cluster verification complete$(NC)"

install-addons: get-credentials ## Install additional add-ons manually
	@echo "$(YELLOW)Installing additional cluster add-ons...$(NC)"
	@echo "Add-ons are installed automatically via Terraform (nginx-ingress, cert-manager)"
	@echo "Checking add-on status..."
	kubectl get pods -n ingress-nginx || echo "nginx-ingress not found"
	kubectl get pods -n cert-manager || echo "cert-manager not found"

show-endpoints: ## Show important cluster endpoints and IPs
	@echo "$(YELLOW)Cluster Information:$(NC)"
	@terraform output -json 2>/dev/null | jq -r '.cluster_fqdn.value // "N/A"' | xargs -I {} echo "Cluster FQDN: {}"
	@terraform output -json 2>/dev/null | jq -r '.bastion_public_ip.value // "N/A"' | xargs -I {} echo "Bastion Public IP: {}"
	@terraform output -json 2>/dev/null | jq -r '.container_registry_login_server.value // "N/A"' | xargs -I {} echo "Container Registry: {}"

clean: ## Clean up temporary files and state backups
	@echo "$(YELLOW)Cleaning up temporary files...$(NC)"
	rm -f *.tfplan
	rm -f terraform.tfstate.backup
	rm -f .terraform.lock.hcl.backup
	find . -name "*.tmp" -delete
	@echo "$(GREEN)Cleanup complete$(NC)"

refresh: ## Refresh Terraform state
	@echo "$(YELLOW)Refreshing Terraform state...$(NC)"
	terraform refresh -var-file="$(TF_VAR_FILE)"
	@echo "$(GREEN)State refreshed$(NC)"

output: ## Show Terraform outputs
	@echo "$(YELLOW)Terraform Outputs:$(NC)"
	@terraform output

state-list: ## List resources in Terraform state
	@echo "$(YELLOW)Resources in Terraform state:$(NC)"
	@terraform state list

# Environment-specific targets
dev-plan: ## Plan for dev environment
	@$(MAKE) plan ENV=dev TF_VAR_FILE=terraform.tfvars

dev-apply: ## Apply for dev environment
	@$(MAKE) apply ENV=dev

staging-plan: ## Plan for staging environment
	@$(MAKE) plan ENV=staging TF_VAR_FILE=staging.tfvars

staging-apply: ## Apply for staging environment
	@$(MAKE) apply ENV=staging

prod-plan: ## Plan for production environment
	@$(MAKE) plan ENV=prod TF_VAR_FILE=production.tfvars

prod-apply: ## Apply for production environment
	@$(MAKE) apply ENV=prod

# Security targets
security-scan: ## Run security scan on Terraform code
	@echo "$(YELLOW)Running security scan (if tfsec is installed)...$(NC)"
	@command -v tfsec >/dev/null 2>&1 && tfsec . || echo "$(YELLOW)tfsec not installed, skipping security scan$(NC)"

# Documentation targets
docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 && terraform-docs markdown table . > TERRAFORM.md || echo "$(YELLOW)terraform-docs not installed$(NC)"
	@echo "$(GREEN)Documentation generated$(NC)"

# Default target
default: help
