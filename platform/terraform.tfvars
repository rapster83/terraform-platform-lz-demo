root_id           = "ddc"
root_display_name = "DDC"
allowed_locations = ["swedencentral", "germanywestcentral"]
logging_location  = "swedencentral"

# One management group per application, below Corp or Online.
workloads = {
  corp = {}
  online = {
    meter-readings = "Meter Readings"
  }
}

# Subscriptions are created by hand. Placing one here moves it into its management group.
subscriptions = {
  management = ["70f0d042-bb3d-490b-8498-964903cd415a"]

  # WARNING: Only one subscription is available in the tenant, so connectivity uses the management subscription.
  #connectivity          = ["70f0d042-bb3d-490b-8498-964903cd415a"]
  #online-meter-readings = ["70f0d042-bb3d-490b-8498-964903cd415a"]
}

# Approved, expiring exceptions from Corp "No public endpoints".
exemptions = {}
