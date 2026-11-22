provider "azurerm" {
  features {
    storage {
      data_plane_available = false # shared keys are off; manage the account through ARM only
    }
  }
  subscription_id                 = var.management_subscription_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}