# Terraform Backend Configuration
# This file will be updated after running the setup-terraform-backend.yml workflow

# Backend configuration for remote state storage
# Uncomment and update after running the backend setup workflow

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "st37921tfstate"
#     container_name       = "terraform-state"
#     key                  = "dev.tfstate"
#   }
# }

# Example configurations for different environments:

# Development
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state-dev-cus-001"
#     storage_account_name = "staksdevcus001tfstate"
#     container_name       = "terraform-state"
#     key                  = "dev.tfstate"
#   }
# }

# Staging
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state-staging-cus-001"
#     storage_account_name = "staksstaginkcus001tfstate"
#     container_name       = "terraform-state"
#     key                  = "staging.tfstate"
#   }
# }

# Production
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state-prod-cus-001"
#     storage_account_name = "staksprodcus001tfstate"
#     container_name       = "terraform-state"
#     key                  = "prod.tfstate"
#   }
# }

# Notes:
# - Each environment has its own storage account for complete isolation
# - Storage account names are globally unique and follow naming conventions
# - State files are named after their respective environments
# - All storage accounts have encryption, versioning, and security features enabled
