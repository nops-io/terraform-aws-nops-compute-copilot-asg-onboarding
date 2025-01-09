data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  lifecycle {
    postcondition {
      condition     = contains(["us-east-1", "us-west-2"], self.id)
      error_message = "This module only supports us-east-1 or us-west-2 as deployment regions."
    }
  }
}

data "nops_projects" "current" {}
