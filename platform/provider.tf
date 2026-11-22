provider "azurerm" {
  features {}
  # Management groups and policies are tenant-wide. The logging workspace and the
  # Defender settings land in the management subscription.
  subscription_id                 = var.subscriptions["management"][0]
  resource_provider_registrations = "none"
}
