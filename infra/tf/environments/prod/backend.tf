terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend-prod"
    storage_account_name = "stterraformbackendprod"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}
