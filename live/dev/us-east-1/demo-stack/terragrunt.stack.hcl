locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment = local.account_vars.locals.environment
  account_id  = local.common_vars.locals.account_ids[local.environment]
  aws_region  = local.region_vars.locals.aws_region
  name_prefix = "${local.environment}-${local.common_vars.locals.project_name}"
}

unit "bucket" {
  source = "${get_repo_root()}/units/bucket"
  path   = "bucket"

  values = {
    bucket_name = "${local.name_prefix}-${local.account_id}-${local.aws_region}"
  }
}

unit "sqs" {
  source = "${get_repo_root()}/units/sqs"
  path   = "sqs"

  values = {
    queue_name = "${local.name_prefix}-${local.aws_region}"
  }
}
