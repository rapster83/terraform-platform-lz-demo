terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {} # configured by scripts/platform.sh
}

provider "azurerm" {
  features {}
  # The connectivity subscription comes from platform/terraform.tfvars.
  subscription_id                 = local.platform.subscriptions["management"][0] # WARNING: Changed from 'connectivity' to 'management', because only one subscription is available in the tenant.
  resource_provider_registrations = "none"
}
