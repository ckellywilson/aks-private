# Makefile for AKS Private Cluster Terraform Deployment
# Provides local development commands and utilities

.DEFAULT_GOAL := help
.PHONY: help setup clean validate plan apply destroy fmt lint docs check-tools azure-login

# Configuration
TERRAFORM_DIR := infra/tf
ENV ?= dev
AUTO_APPROVE ?= false

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
NC := \033[0m

##@ General Commands

help: ## Display this help message
	@echo "$(BLUE)AKS Private Cluster Terraform Deployment$(NC)"
	@echo ""
	@echo "Usage: make [target] [ENV=environment] [AUTO_APPROVE=true/false]"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make setup ENV=dev                    # Setup development environment"
	@echo "  make plan ENV=staging                 # Plan staging deployment"
	@echo "  make apply ENV=prod AUTO_APPROVE=true # Apply production (dangerous!)"

##@ Prerequisites

check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)❌ Terraform not found$(NC)"; exit 1; }
	@command -v az >/dev/null 2>&1 || { echo "$(RED)❌ Azure CLI not found$(NC)"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "$(RED)❌ jq not found$(NC)"; exit 1; }
	@echo "$(GREEN)✅ All required tools are installed$(NC)"
	@echo "Terraform: $$(terraform version | head -n1)"
	@echo "Azure CLI: $$(az version --query '\"azure-cli\"' -o tsv)"

azure-login: ## Login to Azure CLI
	@echo "$(BLUE)Logging into Azure...$(NC)"
	@az login
	@echo "$(GREEN)✅ Azure login successful$(NC)"
	@az account show --query '{name:name, id:id}' -o table

##@ Environment Setup

setup: check-tools ## Setup local development environment
	@echo "$(BLUE)Setting up environment: $(ENV)$(NC)"
	@cd $(TERRAFORM_DIR) && \
	if [ ! -f terraform.tfvars ]; then \
		echo "$(YELLOW)Creating terraform.tfvars from example...$(NC)"; \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "$(YELLOW)⚠️  Please customize terraform.tfvars for your environment$(NC)"; \
	fi
	@echo "$(GREEN)✅ Environment setup complete$(NC)"

setup-backend: azure-login ## Setup Terraform backend (Azure Storage)
	@echo "$(BLUE)Setting up Terraform backend for $(ENV)...$(NC)"
	@cd $(TERRAFORM_DIR) && \
	chmod +x setup-backend.sh && \
	ENVIRONMENT=$(ENV) ./setup-backend.sh
	@echo "$(GREEN)✅ Backend setup complete$(NC)"

clean: ## Clean Terraform temporary files
	@echo "$(BLUE)Cleaning Terraform temporary files...$(NC)"
	@cd $(TERRAFORM_DIR) && \
	rm -rf .terraform/ && \
	rm -f .terraform.lock.hcl && \
	rm -f tfplan && \
	rm -f terraform.tfstate.backup && \
	rm -f backend-config.txt
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

##@ Terraform Operations

init: setup ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init
	@echo "$(GREEN)✅ Terraform initialized$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform fmt -recursive
	@echo "$(GREEN)✅ Terraform files formatted$(NC)"

validate: init ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform validate
	@echo "$(GREEN)✅ Terraform configuration is valid$(NC)"

plan: validate ## Create Terraform execution plan
	@echo "$(BLUE)Creating Terraform plan for $(ENV)...$(NC)"
	@cd $(TERRAFORM_DIR) && \
	terraform plan -out=tfplan -var="environment=$(ENV)"
	@echo "$(GREEN)✅ Terraform plan created: tfplan$(NC)"

apply: ## Apply Terraform plan
	@echo "$(BLUE)Applying Terraform plan for $(ENV)...$(NC)"
	@if [ "$(AUTO_APPROVE)" = "true" ]; then \
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve tfplan; \
	else \
		cd $(TERRAFORM_DIR) && terraform apply tfplan; \
	fi
	@echo "$(GREEN)✅ Terraform apply completed$(NC)"

destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)⚠️  This will destroy all infrastructure for $(ENV)!$(NC)"
	@if [ "$(AUTO_APPROVE)" != "true" ]; then \
		read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1; \
	fi
	@cd $(TERRAFORM_DIR) && \
	terraform destroy -var="environment=$(ENV)" \
	$(if $(filter true,$(AUTO_APPROVE)),-auto-approve,)
	@echo "$(GREEN)✅ Infrastructure destroyed$(NC)"

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENV):$(NC)"
	@cd $(TERRAFORM_DIR) && terraform output

state-list: ## List Terraform state resources
	@echo "$(BLUE)Terraform state resources:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform state list

##@ Development Utilities

lint: ## Run Terraform linting
	@echo "$(BLUE)Running Terraform lint checks...$(NC)"
	@command -v tflint >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  TFLint not found, skipping$(NC)"; exit 0; }
	@cd $(TERRAFORM_DIR) && tflint --init && tflint
	@echo "$(GREEN)✅ Terraform lint completed$(NC)"

docs: ## Generate Terraform documentation
	@echo "$(BLUE)Generating Terraform documentation...$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  terraform-docs not found, skipping$(NC)"; exit 0; }
	@cd $(TERRAFORM_DIR) && terraform-docs markdown table --output-file README.md .
	@echo "$(GREEN)✅ Documentation generated$(NC)"

security-scan: ## Run security scan on Terraform code
	@echo "$(BLUE)Running security scan...$(NC)"
	@command -v checkov >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  Checkov not found, skipping$(NC)"; exit 0; }
	@cd $(TERRAFORM_DIR) && checkov -d . --framework terraform
	@echo "$(GREEN)✅ Security scan completed$(NC)"

cost-estimate: ## Estimate infrastructure costs
	@echo "$(BLUE)Estimating infrastructure costs...$(NC)"
	@command -v infracost >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  Infracost not found, skipping$(NC)"; exit 0; }
	@cd $(TERRAFORM_DIR) && infracost breakdown --path .
	@echo "$(GREEN)✅ Cost estimation completed$(NC)"

##@ Kubernetes Operations

k8s-connect: ## Connect to AKS cluster
	@echo "$(BLUE)Connecting to AKS cluster...$(NC)"
	@cd $(TERRAFORM_DIR) && \
	CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null || echo "aks-cluster-$(ENV)-cus-001") && \
	RESOURCE_GROUP=$$(terraform output -raw resource_group_name 2>/dev/null || echo "rg-aks-$(ENV)-cus-001") && \
	az aks get-credentials --resource-group $$RESOURCE_GROUP --name $$CLUSTER_NAME --overwrite-existing
	@echo "$(GREEN)✅ Connected to AKS cluster$(NC)"

k8s-info: k8s-connect ## Show Kubernetes cluster information
	@echo "$(BLUE)Kubernetes cluster information:$(NC)"
	@kubectl cluster-info
	@echo ""
	@echo "$(BLUE)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo "$(BLUE)Namespaces:$(NC)"
	@kubectl get namespaces

k8s-dashboard: k8s-connect ## Open Kubernetes dashboard
	@echo "$(BLUE)Starting Kubernetes dashboard...$(NC)"
	@kubectl proxy &
	@echo "$(GREEN)Dashboard available at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/$(NC)"

##@ CI/CD Helpers

github-setup: ## Setup GitHub Actions prerequisites
	@echo "$(BLUE)Setting up GitHub Actions prerequisites...$(NC)"
	@if [ ! -f .github/setup-service-principal.sh ]; then \
		echo "$(RED)❌ Service principal setup script not found$(NC)"; \
		exit 1; \
	fi
	@chmod +x .github/setup-service-principal.sh
	@echo "$(YELLOW)Run the following command to setup Azure Service Principal:$(NC)"
	@echo ".github/setup-service-principal.sh"
	@echo ""
	@echo "$(YELLOW)Then configure the secrets in GitHub:$(NC)"
	@echo "https://github.com/YOUR_REPO/settings/secrets/actions"

workflows-validate: ## Validate GitHub Actions workflows
	@echo "$(BLUE)Validating GitHub Actions workflows...$(NC)"
	@command -v actionlint >/dev/null 2>&1 || { echo "$(YELLOW)⚠️  actionlint not found, skipping$(NC)"; exit 0; }
	@actionlint .github/workflows/*.yml
	@echo "$(GREEN)✅ Workflows validation completed$(NC)"

##@ Quick Commands

dev: setup init plan ## Quick development workflow (setup + init + plan)
	@echo "$(GREEN)✅ Development workflow completed$(NC)"

deploy-dev: dev apply ## Deploy to development environment
	@echo "$(GREEN)✅ Development deployment completed$(NC)"

full-setup: check-tools azure-login setup-backend init validate plan ## Complete setup workflow
	@echo "$(GREEN)✅ Full setup completed - ready for deployment$(NC)"

##@ Information

env-info: ## Show current environment information
	@echo "$(BLUE)Current Environment Information:$(NC)"
	@echo "Environment: $(ENV)"
	@echo "Terraform Directory: $(TERRAFORM_DIR)"
	@echo "Auto Approve: $(AUTO_APPROVE)"
	@echo ""
	@if [ -f $(TERRAFORM_DIR)/terraform.tfvars ]; then \
		echo "$(BLUE)Terraform Variables:$(NC)"; \
		grep -E '^[^#].*=' $(TERRAFORM_DIR)/terraform.tfvars | head -10; \
	else \
		echo "$(YELLOW)⚠️  terraform.tfvars not found$(NC)"; \
	fi

status: ## Show Terraform and Azure status
	@echo "$(BLUE)Status Information:$(NC)"
	@echo ""
	@echo "$(BLUE)Azure Account:$(NC)"
	@az account show --query '{name:name, id:id}' -o table 2>/dev/null || echo "Not logged in"
	@echo ""
	@echo "$(BLUE)Terraform Status:$(NC)"
	@if [ -d $(TERRAFORM_DIR)/.terraform ]; then \
		echo "✅ Terraform initialized"; \
		cd $(TERRAFORM_DIR) && terraform workspace show; \
	else \
		echo "❌ Terraform not initialized"; \
	fi
	@echo ""
	@if [ -f $(TERRAFORM_DIR)/tfplan ]; then \
		echo "$(BLUE)Plan Status:$(NC) ✅ Plan file exists"; \
	else \
		echo "$(BLUE)Plan Status:$(NC) ❌ No plan file found"; \
	fi

##@ Troubleshooting

debug: ## Debug Terraform configuration
	@echo "$(BLUE)Terraform Debug Information:$(NC)"
	@cd $(TERRAFORM_DIR) && \
	echo "Terraform Version:" && terraform version && \
	echo "" && \
	echo "Working Directory:" && pwd && \
	echo "" && \
	echo "Files:" && ls -la && \
	echo "" && \
	echo "Terraform Configuration:" && terraform validate -json | jq '.' 2>/dev/null || echo "Invalid configuration"

logs: ## Show recent Terraform logs
	@echo "$(BLUE)Recent Terraform Activity:$(NC)"
	@if [ -f $(TERRAFORM_DIR)/.terraform/terraform.tfstate ]; then \
		echo "Last state modification:"; \
		stat -c %y $(TERRAFORM_DIR)/.terraform/terraform.tfstate; \
	fi
	@if [ -f $(TERRAFORM_DIR)/tfplan ]; then \
		echo "Plan file created:"; \
		stat -c %y $(TERRAFORM_DIR)/tfplan; \
	fi

reset: clean init ## Reset Terraform (clean + init)
	@echo "$(GREEN)✅ Terraform reset completed$(NC)"
