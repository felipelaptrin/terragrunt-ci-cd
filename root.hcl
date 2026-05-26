locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment = local.account_vars.locals.environment
  account_id  = local.common_vars.locals.account_ids[local.environment]
  aws_region  = local.region_vars.locals.aws_region
  name_prefix = "${local.environment}-${local.common_vars.locals.project_name}"

  # Tags: three-layer merge — root defaults < account-level tags.yml < unit-level tags.yml.
  # To override or extend tags, add a tags.yml beside the relevant account.hcl or unit.
  default_tags         = merge(local.common_vars.locals.default_tags, { Environment = local.environment })
  parent_override_tags = try(yamldecode(file(find_in_parent_folders("tags.yml"))), {})
  override_tags        = try(yamldecode(file("${get_terragrunt_dir()}/tags.yml")), {})
  tags                 = merge(local.default_tags, local.parent_override_tags, local.override_tags)
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
        tags = ${jsonencode(local.tags)}
      }
    }
  EOF
}
