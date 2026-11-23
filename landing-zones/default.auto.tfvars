state_backend = {
  subscription_id      = "70f0d042-bb3d-490b-8498-964903cd415a"
  resource_group_name  = "rg-ddc-tfstate"
  storage_account_name = "stlzddcdevgwctfstate001"
  container_name       = "tfstate"
}

subscription_id        = "70f0d042-bb3d-490b-8498-964903cd415a"
name                   = "meter-readings" # Name of the application landing zone (Normally over the .sh file)
address_space          = ["10.100.16.0/24"]
github_repository      = "rapster83/terraform-application-lz-demo" # Application Repository!
github_oidc_repository = "rapster83@45358082/terraform-application-lz-demo@1467797538"

tags = {
  owner         = "meter-team"
  "cost-center" = "cc-4711"
  env           = "prod"
}