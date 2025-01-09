locals {
  nasg_lambda_version = "latest"
  gateway_host = {
    dev : "asg-dev.nops.io"
    uat : "asg-uat.nops.io"
    ua2 : "asg-uat2.nops.io"
    prd : "asg.nops.io"
  }
  current_nops_project = [
    for project in data.nops_projects.current.projects : project
    if project.account_number == data.aws_caller_identity.current.account_id
  ]
  nasg_s3_bucket     = "nops-${var.environment}-asg-lambda-${data.aws_region.current.id}"
  nasg_s3_bucket_key = "${local.nasg_lambda_version}/src/nasg-${local.nasg_lambda_version}.zip"
}
