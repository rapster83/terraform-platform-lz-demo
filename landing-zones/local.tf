locals {
  platform                   = data.terraform_remote_state.platform.outputs
  hub                        = data.terraform_remote_state.connectivity.outputs.hub
  root_id                    = local.platform.root_id
  management_subscription_id = local.platform.subscriptions["management"][0]

  github_owner = var.github_repository == null ? null : split("/", var.github_repository)[0]
  github_repo  = var.github_repository == null ? null : split("/", var.github_repository)[1]

  state_account_id = "/subscriptions/${var.state_backend.subscription_id}/resourceGroups/${var.state_backend.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.state_backend.storage_account_name}"


  # ---------------------------------------------------------------------------
  # Network Subnets which are used for apps and private endpoints
  # ---------------------------------------------------------------------------
  apps_prefix = cidrsubnet(var.address_space[0], 2, 0) # /24 -> x.x.x.0/26
  pe_prefix   = cidrsubnet(var.address_space[0], 3, 2) # /24 -> x.x.x.64/27

  subnets = {
    # App Service / Functions VNet integration
    apps = {
      address_prefixes = [local.apps_prefix]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
      rules = {
        to-private-endpoints = {
          priority                   = 200
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = local.apps_prefix
          destination_address_prefix = local.pe_prefix
        }
      }
    }
    # Private endpoints for storage, Key Vault, SQL ...
    private-endpoints = {
      address_prefixes  = [local.pe_prefix]
      private_endpoints = true
      rules = {
        from-apps = {
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = local.apps_prefix
          destination_address_prefix = local.pe_prefix
        }
      }
    }
  }

  # Assignable role IDs for constrained RBAC
  assignable_role_ids = join(", ", [for r in data.azurerm_role_definition.assignable : basename(r.role_definition_id)])

  # ---------------------------------------------------------------------------
  # The CONTRACT the application's Terraform receives (GitHub variable LANDING_ZONE)
  # ---------------------------------------------------------------------------
  landing_zone = {
    name                 = var.name
    subscription_id      = var.subscription_id
    location             = var.location
    tags                 = var.tags
    vnet_id              = module.spoke.network.vnet_id
    subnet_ids           = module.spoke.network.subnet_ids
    private_dns_zone_ids = { for zone in var.private_dns_zones : zone => lookup(local.hub.private_dns_zones, zone, null) }
  }

  github_variables = {
    AZURE_CLIENT_ID         = azurerm_user_assigned_identity.deploy.client_id
    AZURE_TENANT_ID         = data.azurerm_client_config.current.tenant_id
    AZURE_SUBSCRIPTION_ID   = var.subscription_id
    TFSTATE_SUBSCRIPTION_ID = var.state_backend.subscription_id
    TFSTATE_RESOURCE_GROUP  = var.state_backend.resource_group_name
    TFSTATE_STORAGE_ACCOUNT = var.state_backend.storage_account_name
    TFSTATE_CONTAINER       = azurerm_storage_container.state.name
    LANDING_ZONE            = jsonencode(local.landing_zone)
  }
}
