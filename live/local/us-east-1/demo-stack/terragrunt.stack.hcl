locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment = local.account_vars.locals.environment
  account_id  = local.account_vars.locals.account_id
  aws_region  = local.region_vars.locals.aws_region
}

unit "bucket" {
  source = "${get_repo_root()}/units/bucket"
  path   = "bucket"

  values = {
    bucket_name = "${local.environment}-terragrunt-ci-cd-${local.account_id}-${local.aws_region}"
  }
}

unit "sqs" {
  source = "${get_repo_root()}/units/sqs"
  path   = "sqs"

  values = {
    queue_name = "${local.environment}-terragrunt-ci-cd-${local.aws_region}"
  }
}
