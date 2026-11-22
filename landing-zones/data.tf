data "azurerm_client_config" "current" {}

data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config  = merge(var.state_backend, { key = "management-groups.tfstate", use_azuread_auth = true })
}

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config  = merge(var.state_backend, { key = "connectivity.tfstate", use_azuread_auth = true })
}

data "azurerm_role_definition" "assignable" {
  provider = azurerm.management
  for_each = toset(var.assignable_roles)
  name     = each.key
}