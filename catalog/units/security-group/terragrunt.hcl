include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::terraform-aws-modules/security-group/aws?ref=5.3.1"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock-outputs"
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}