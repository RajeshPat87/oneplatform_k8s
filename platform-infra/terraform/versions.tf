terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.5" }
    azuread    = { source = "hashicorp/azuread", version = "~> 3.0" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.32" }
    helm       = { source = "hashicorp/helm", version = "~> 2.15" }
  }

  # Backend values come from scripts/ensure-tf-backend.sh defaults.
  # Pass via CI: -backend-config or `terraform init -backend-config=backend.hcl`.
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstaterajesh15282"
    container_name       = "tfstate"
    key                  = "oneplatform.tfstate"
  }
}
