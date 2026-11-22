# The hub: Azure Firewall, shared private DNS zones, central diagnostics.
# Root ID, subscription and logging workspace come from the platform state, so
# platform/terraform.tfvars stays the single place for them.

data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config  = merge(var.state_backend, { key = "management-groups.tfstate", use_azuread_auth = true })
}

locals {
  platform = data.terraform_remote_state.platform.outputs
}

module "connectivity" {
  source = "github.com/rapster83/terraform-modules-lz-demo//terraform/modules/connectivity?ref=v0.0.3"

  stage                      = "regional_airfield"
  root_id                    = local.platform.root_id
  subscription_id            = local.platform.subscriptions["management"][0] # WARNING: Changed from 'connectivity' to 'management', because only one subscription is available in the tenant.
  location                   = var.location
  tags                       = var.tags
  address_space              = var.address_space
  firewall_subnet            = var.firewall_subnet
  private_dns_zones          = var.private_dns_zones
  log_analytics_workspace_id = local.platform.log_analytics_workspace_id
  network_rules              = var.network_rules
  application_rules          = var.application_rules
}
