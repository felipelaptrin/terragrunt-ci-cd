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
    vpc_path = "../vpc"
    name = "bastion-terraform-sg"
  }
}

unit "bastion" {
  source = "git::git@github.com:felipelaptrin/terragrunt-ci-cd.git//catalog/units/bastion-host"
  path = "bastion"
  values = {
    instance_type = "t4g.small"
    vpc_path = "../vpc"
    sg_path = "../bastion-sg"
  }
}

