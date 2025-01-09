resource "aws_lambda_function" "nops_nasg_lambda" {
  function_name = "nOps-ASG-${data.aws_region.current.id}"
  description   = "Lambda function to handle ASG event bus"
  handler       = "lambda_function.lambda_handler"
  memory_size   = var.memory_size
  timeout       = var.timeout
  runtime       = "python3.10"
  role          = aws_iam_role.nasg_function_role.arn
  architectures = ["arm64"]

  environment {
    variables = {
      STACK_NAME              = ""
      STACK_REGION            = data.aws_region.current.id
      NOPS_ASG_GATEWAY_HOST   = lookup(local.gateway_host, var.environment, local.gateway_host["prd"])
      NOPS_ASG_PROJECT_ID     = local.current_nops_project[0].id
      NOPS_ASG_ACCOUNT_NUMBER = data.aws_caller_identity.current.account_id
      NOPS_ASG_TOKEN          = var.token
      NOPS_ASG_AUTO_UPDATE    = true
      NOPS_ASG_VERSION        = local.nasg_lambda_version
    }
  }

  s3_bucket = local.nasg_s3_bucket
  s3_key    = local.nasg_s3_bucket_key
}

# self test configuration
data "archive_file" "nops_self_test_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/self_test/index.py"
  output_path = "self_test.zip"
}

resource "aws_lambda_function" "nops_self_test_lambda" {
  filename      = "self_test.zip"
  function_name = "nOps-ASG-self-test-${data.aws_region.current.id}"
  role          = aws_iam_role.nasg_function_role.arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_self_test_lambda.output_base64sha256

  runtime = "python3.10"
  timeout = 60
}

# regions checker
data "archive_file" "nops_regions_checker_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/regions_checker/index.py"
  output_path = "regions_checker.zip"
}

resource "aws_lambda_function" "nops_regions_checker_lambda" {
  filename      = "regions_checker.zip"
  function_name = "nOps-ASG-regions-checker-${data.aws_region.current.id}"
  role          = aws_iam_role.nasg_role_checker_role.arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_regions_checker_lambda.output_base64sha256

  runtime = "python3.10"
  timeout = 60

  environment {
    variables = {
      ExcludeRegions : var.exclude_regions
    }
  }
}

# Role checker
data "archive_file" "nops_role_checker_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/role_checker/index.py"
  output_path = "role_checker.zip"
}

resource "aws_lambda_function" "nops_role_checker_lambda" {
  filename      = "role_checker.zip"
  function_name = "nOps-ASG-role-checker-${data.aws_region.current.id}"
  role          = aws_iam_role.nasg_role_checker_role.arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_role_checker_lambda.output_base64sha256

  runtime = "python3.10"
  timeout = 60

  environment {
    variables = {
      account_number : data.aws_caller_identity.current.account_id
    }
  }
}

# Auto Update
data "archive_file" "nops_auto_updater_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/auto_updater/index.py"
  output_path = "auto_updater.zip"
}

resource "aws_lambda_function" "nops_auto_updater_lambda" {
  filename      = "auto_updater.zip"
  function_name = "nOps-ASG-auto-updater-${data.aws_region.current.id}"
  role          = aws_iam_role.nasg_auto_updater_role.arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_auto_updater_lambda.output_base64sha256

  runtime = "python3.10"
  timeout = 60

  environment {
    variables = {
      NASG_LAMBDA_BUCKET : local.nasg_s3_bucket,
      NASG_LAMBDA_BUCKET_KEY : local.nasg_s3_bucket_key,
      NASG_LAMBDA_ARN : aws_lambda_function.nops_nasg_lambda.arn
    }
  }
}
