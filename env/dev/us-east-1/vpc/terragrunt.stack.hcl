locals {
  azs = ["us-east-1a", "us-east-1b"]
  cidr = "10.205.0.0/16"
}

unit "service" {
  source = "git::git@github.com:felipelaptrin/terragrunt-ci-cd.git//catalog/units/vpc"
  path = "vpc"
  values = {
    azs = local.azs
    cidr = local.cidr
  }
}
