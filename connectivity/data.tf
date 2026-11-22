data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config  = merge(var.state_backend, { key = "management-groups.tfstate", use_azuread_auth = true })
}