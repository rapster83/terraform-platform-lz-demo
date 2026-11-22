# The application's subscription: spoke network and the team's permissions.
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

# The hub: peering back to the spoke, DNS zone links, DNS permissions.
provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id                 = local.hub.subscription_id
  resource_provider_registrations = "none"
}

# The management subscription: deploy identity and the team's state container.
provider "azurerm" {
  alias = "management"
  features {}
  subscription_id                 = local.management_subscription_id
  resource_provider_registrations = "none"
}

# Creates the GitHub environment in the application repository.
# Token: LZ_GITHUB_TOKEN, passed in as GITHUB_TOKEN by the pipeline.
provider "github" {
  owner = local.github_owner
}
