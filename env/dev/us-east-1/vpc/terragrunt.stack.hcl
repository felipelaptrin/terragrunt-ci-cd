locals {
  azs = ["us-east-1a", "us-east-1b"]
  cidr = "10.205.0.0/16"
}

unit "vpc" {
  source = "git::git@github.com:felipelaptrin/terragrunt-ci-cd.git//catalog/units/vpc"
  path = "vpc"
  values = {
    azs  = local.azs
    cidr = local.cidr
  }
}

unit "bastion-sg" {
  source = "git::git@github.com:felipelaptrin/terragrunt-ci-cd.git//catalog/units/security-group"
  path = "bastion-sg"
  values = {
    azs      = local.azs
    cidr     = local.cidr
    vpc_path = "../vpc"
  }
}
