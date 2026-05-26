locals {
  project_name   = "terragrunt-cicd"
  default_region = "us-east-1"

  account_info = yamldecode(file("accounts.yml"))
  account_ids = {
    for environment, info in local.account_info :
    environment => info.id
  }

  default_tags = yamldecode(file("tags.yml"))
}
