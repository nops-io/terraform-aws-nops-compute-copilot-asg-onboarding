check "health_check" {
  data "aws_lambda_invocation" "self_test" {
    function_name = aws_lambda_function.nops_self_test_lambda.function_name
    input = "{}"
  }

  assert {
    condition = jsondecode(data.aws_lambda_invocation.self_test.result).status_code == 200
    error_message = "Lambda ${aws_lambda_function.nops_self_test_lambda.function_name} returned an unhealthy status code ${jsondecode(data.aws_lambda_invocation.self_test.result).status_code}"
  }
}

check "region_check" {
  data "aws_lambda_invocation" "regions_checker" {
    function_name = aws_lambda_function.nops_regions_checker_lambda.function_name
    input = "{}"
  }

  assert {
    condition = jsondecode(data.aws_lambda_invocation.regions_checker.result).status_code == 200
    error_message = "Lambda ${aws_lambda_function.nops_regions_checker_lambda.function_name} returned an unhealthy status code ${jsondecode(data.aws_lambda_invocation.regions_checker.result).status_code}"
  }
}

check "role_check" {
  data "aws_lambda_invocation" "role_checker" {
    function_name = aws_lambda_function.nops_role_checker_lambda.function_name
    input = "{}"
  }

  assert {
    condition = jsondecode(data.aws_lambda_invocation.role_checker.result).status_code == 200
    error_message = "Lambda ${aws_lambda_function.nops_role_checker_lambda.function_name} returned an unhealthy status code ${jsondecode(data.aws_lambda_invocation.role_checker.result).status_code}"
  }
}
