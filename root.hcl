locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment = local.account_vars.locals.environment
  account_id  = local.account_vars.locals.account_id
  aws_region  = local.region_vars.locals.aws_region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "terragrunt-states-${local.environment}"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = local.aws_region
    encrypt = true

    use_lockfile = true

    # Floci overrides for local environment
    endpoint                    = local.environment == "local" ? "http://localhost:4566" : null
    access_key                  = local.environment == "local" ? "test" : null
    secret_key                  = local.environment == "local" ? "test" : null
    skip_credentials_validation = local.environment == "local" ? true : false
    skip_metadata_api_check     = local.environment == "local" ? true : false
    skip_requesting_account_id  = local.environment == "local" ? true : false
    use_path_style              = local.environment == "local" ? true : false
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      %{if local.environment == "local"}
      access_key                  = "test"
      secret_key                  = "test"
      skip_credentials_validation = true
      skip_metadata_api_check     = true
      skip_requesting_account_id  = true
      s3_use_path_style           = true
      %{endif}

      default_tags {
        tags = {
          Project     = "Terragrunt CI/CD"
          Environment = "${local.environment}"
          ManagedBy   = "Terragrunt"
        }
      }
    }
  EOF
}
