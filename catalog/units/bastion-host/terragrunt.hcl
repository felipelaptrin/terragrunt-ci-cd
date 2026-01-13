include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/ec2-instance.git?ref=v5.7.1"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id = "vpc-mock-outputs"
    private_subnets = ["subnet-mock-outputs"]
  }
}

dependency "sg" {
  config_path  = values.sg_path
  mock_outputs = {
    security_group_id = "sg-mock-outputs"
  }
}

inputs = {
  name   = "${local.account_name}-bastion"
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [dependency.sg.security_group_id]
  instance_type = values.instance_type
  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}