include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v6.6.0"
}

inputs = {
  name = "vpc-terraform"

  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = true

  enable_nat_gateway = false
}