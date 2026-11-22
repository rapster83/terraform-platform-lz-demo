locals {
  platform_root_scope = "/providers/Microsoft.Management/managementGroups/${var.root_id}"
  state_container     = "${azurerm_storage_account.state.id}/blobServices/default/containers/${azurerm_storage_container.state.name}"

  pipeline_roles = {

    # Plans see everything and change nothing in Azure. They do need to write to the
    # state container: for a brand-new landing zone the backend creates an empty state file.
    plan-reader = { identity = "plan", scope = local.platform_root_scope, role = "Reader" }
    plan-state  = { identity = "plan", scope = local.state_container, role = "Storage Blob Data Contributor" }

    # Applies build management groups, policies, networks and new landing zones.
    # Demo shortcut: Owner on the platform root. Production: split into narrower roles.
    apply-owner = { identity = "apply", scope = local.platform_root_scope, role = "Owner" }
    apply-state = { identity = "apply", scope = local.state_container, role = "Storage Blob Data Contributor" }
  }
}