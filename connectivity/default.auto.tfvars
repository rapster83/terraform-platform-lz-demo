state_backend = {
  subscription_id      = "70f0d042-bb3d-490b-8498-964903cd415a"
  resource_group_name  = "rg-ddc-tfstate"
  storage_account_name = "stlzddcdevgwctfstate001"
  container_name       = "tfstate"
}

location        = "swedencentral"
tags            = { owner = "platform-team", cost-center = "cc-platform", env = "prod" }
address_space   = ["10.100.0.0/22"]
firewall_subnet = "10.100.0.0/26"

# Landing zones get records in these zones for their private endpoints.
private_dns_zones = [
  "privatelink.blob.core.windows.net",
  "privatelink.vaultcore.azure.net",
  "privatelink.database.windows.net",
  "privatelink.azurewebsites.net",
]

# No allow rules = no workload egress through the firewall.
application_rules = {}
network_rules     = {}
