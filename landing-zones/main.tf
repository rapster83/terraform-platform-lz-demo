# One application landing zone = one var file in this folder.
#
# What the platform hands over after the merge:
#   1. Network     Airstrip spoke: VNet, two standard subnets, NSGs, routes via the
#                  firewall, peering both ways, links to the hub's private DNS zones
#   2. Identity    a deploy identity only the team's repository can use (GitHub OIDC)
#   3. Permissions Contributor on the subscription, but role assignments only for an
#                  allow-list of roles, plus DNS records for its private endpoints
#   4. State       its own Terraform state container
#   5. GitHub      environment "prod" in the team's repository, all variables set
#
# The subscription's management group placement lives in platform/terraform.tfvars.



# ---------------------------------------------------------------------------
# 1. Network: every landing zone gets the same two subnets
# ---------------------------------------------------------------------------
module "spoke" {
  source = "github.com/rapster83/terraform-modules-lz-demo//terraform/modules/spoke?ref=v0.0.3"
  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  stage                = "regional_airfield"
  root_id              = local.root_id
  subscription_id      = var.subscription_id
  name                 = var.name
  location             = var.location
  tags                 = var.tags
  address_space        = var.address_space
  other_spoke_prefixes = var.other_spoke_prefixes
  hub                  = local.hub
  subnets              = local.subnets
}

# ---------------------------------------------------------------------------
# 2. Identity: only the team's repository can use it, and only from its environment
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "vending" {
  provider = azurerm.management
  name     = "rg-${local.root_id}-lz-${var.name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "deploy" {
  provider            = azurerm.management
  name                = "id-${local.root_id}-${var.name}-deploy"
  location            = var.location
  resource_group_name = azurerm_resource_group.vending.name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github" {
  provider                  = azurerm.management
  count                     = var.github_repository == null ? 0 : 1
  name                      = "github-${var.github_environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.deploy.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${coalesce(var.github_oidc_repository, var.github_repository)}:environment:${var.github_environment}"
}

# ---------------------------------------------------------------------------
# 3. Permissions
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "deploy_contributor" {
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.deploy.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# The team can give its app identities AcrPull, Storage Blob Data Contributor ...
# but never Owner, Contributor or User Access Administrator.
resource "azurerm_role_assignment" "deploy_constrained_rbac" {
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_name             = "Role Based Access Control Administrator"
  principal_id                     = azurerm_user_assigned_identity.deploy.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  description                      = "Landing zone ${var.name}: assign allow-listed roles only"
  condition_version                = "2.0"
  condition                        = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.assignable_role_ids}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.assignable_role_ids}}
     )
    )
  EOT
}

# Private endpoints register their A records in the hub's zones.
resource "azurerm_role_assignment" "deploy_dns" {
  provider                         = azurerm.connectivity
  for_each                         = toset(var.private_dns_zones)
  scope                            = lookup(local.hub.private_dns_zones, each.key, "missing")
  role_definition_name             = "Private DNS Zone Contributor"
  principal_id                     = azurerm_user_assigned_identity.deploy.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true

  lifecycle {
    precondition {
      condition     = contains(keys(local.hub.private_dns_zones), each.key)
      error_message = "${each.key} is not a hub DNS zone. Add it to connectivity/terraform.tfvars first."
    }
  }
}

# ---------------------------------------------------------------------------
# 4. State: one container per landing zone, nobody else's states in reach
# ---------------------------------------------------------------------------
resource "azurerm_storage_container" "state" {
  provider           = azurerm.management
  name               = "tfstate-${var.name}"
  storage_account_id = local.state_account_id
}

resource "azurerm_role_assignment" "deploy_state" {
  provider                         = azurerm.management
  scope                            = "${local.state_account_id}/blobServices/default/containers/${azurerm_storage_container.state.name}"
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.deploy.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# ---------------------------------------------------------------------------
# 5. GitHub: the team's repository gets a ready-to-use environment.
# No ticket, no copy and paste of IDs: the first push can deploy.
# ---------------------------------------------------------------------------
resource "github_repository_environment" "app" {
  count       = var.github_repository == null ? 0 : 1
  repository  = local.github_repo
  environment = var.github_environment
}

resource "github_actions_environment_variable" "app" {
  for_each      = var.github_repository == null ? {} : local.github_variables
  repository    = local.github_repo
  environment   = github_repository_environment.app[0].environment
  variable_name = each.key
  value         = each.value
}
