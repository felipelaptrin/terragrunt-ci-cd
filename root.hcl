locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  accounts     = yamldecode(file(find_in_parent_folders("accounts.yml")))

  environment = local.account_vars.locals.environment
  account_id  = local.accounts[local.environment].id
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
    access_key                  = local.environment == "local" ? "test" : null
    secret_key                  = local.environment == "local" ? "test" : null
    skip_credentials_validation = local.environment == "local" ? true : false
    skip_metadata_api_check     = local.environment == "local" ? true : false
    skip_requesting_account_id  = local.environment == "local" ? true : false
    use_path_style              = local.environment == "local" ? true : false
    ## For some reason this is required in order to make Floci work with Terragrunt
    skip_bucket_root_access            = local.environment == "local" ? true : false
    skip_bucket_enforced_tls           = local.environment == "local" ? true : false
    skip_bucket_versioning             = local.environment == "local" ? true : false
    skip_bucket_ssencryption           = local.environment == "local" ? true : false
    skip_bucket_public_access_blocking = local.environment == "local" ? true : false
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      allowed_account_ids = ["${local.account_id}"]

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
