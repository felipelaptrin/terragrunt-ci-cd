include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/sqs/aws?version=5.2.1"
}

inputs = {
  name                    = values.queue_name
  sqs_managed_sse_enabled = true
}
