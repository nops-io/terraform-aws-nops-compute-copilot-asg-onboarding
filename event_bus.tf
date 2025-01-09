resource "aws_cloudwatch_event_bus" "nops_asg_ec2_instance_state_change" {
  name = "nops-asg-ec2-instance-state-change"
}

resource "aws_cloudwatch_event_rule" "asg_ec2_spot_termination_warning" {
  name           = "nops-asg-ec2-spot-termination-warning"
  event_bus_name = aws_cloudwatch_event_bus.nops_asg_ec2_instance_state_change.name
  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Spot Instance Interruption Warning"]
    detail = {
      "instance-action" = ["terminate"]
    }
  })
  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "asg_ec2_spot_termination_target" {
  rule           = aws_cloudwatch_event_rule.asg_ec2_spot_termination_warning.name
  target_id      = aws_lambda_function.nops_nasg_lambda.function_name
  arn            = aws_lambda_function.nops_nasg_lambda.arn
  event_bus_name = aws_cloudwatch_event_bus.nops_asg_ec2_instance_state_change.name
}

# Lambda permission for EC2 Spot Termination Warning
resource "aws_lambda_permission" "ec2_spot_termination_warning_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nops_nasg_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_ec2_spot_termination_warning.arn
}

# EventBridge Rule for EC2 Instance Launch Unsuccessful
resource "aws_cloudwatch_event_rule" "ec2_instance_launch_unsuccessful" {
  name           = "nops-asg-ec2-instance-launch-unsuccessful"
  event_bus_name = aws_cloudwatch_event_bus.nops_asg_ec2_instance_state_change.name
  event_pattern = jsonencode({
    source        = ["aws.autoscaling"]
    "detail-type" = ["EC2 Instance Launch Unsuccessful"]
  })
  state = "ENABLED"
}

# Target for EC2 Instance Launch Unsuccessful
resource "aws_cloudwatch_event_target" "ec2_instance_launch_unsuccessful_target" {
  rule           = aws_cloudwatch_event_rule.ec2_instance_launch_unsuccessful.name
  target_id      = aws_lambda_function.nops_nasg_lambda.function_name
  arn            = aws_lambda_function.nops_nasg_lambda.arn
  event_bus_name = aws_cloudwatch_event_bus.nops_asg_ec2_instance_state_change.name
}

# Lambda permission for EC2 Instance Launch Unsuccessful
resource "aws_lambda_permission" "ec2_instance_launch_unsuccessful_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nops_nasg_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_instance_launch_unsuccessful.arn
}

# EventBridge Rule for Scheduled Check
resource "aws_cloudwatch_event_rule" "scheduled_check" {
  name                = "nops-asg-scheduled-check"
  event_bus_name      = "default"
  schedule_expression = "rate(30 minutes)"
  state               = "ENABLED"
}

# Target for Scheduled Check
resource "aws_cloudwatch_event_target" "scheduled_check_target" {
  rule           = aws_cloudwatch_event_rule.scheduled_check.name
  target_id      = aws_lambda_function.nops_nasg_lambda.function_name
  arn            = aws_lambda_function.nops_nasg_lambda.arn
  event_bus_name = "default"
}

# Lambda permission for Scheduled Check
resource "aws_lambda_permission" "scheduled_check_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nops_nasg_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_check.arn
}

# EventBridge Rule for Auto Update
resource "aws_cloudwatch_event_rule" "auto_update" {
  name                = "nops-asg-auto-update"
  event_bus_name      = "default"
  schedule_expression = "rate(30 minutes)"
  state               = "ENABLED"
}

# Target for Auto Update
resource "aws_cloudwatch_event_target" "auto_update_target" {
  rule           = aws_cloudwatch_event_rule.auto_update.name
  target_id      = aws_lambda_function.nops_auto_updater_lambda.function_name
  arn            = aws_lambda_function.nops_auto_updater_lambda.arn
  event_bus_name = "default"
}

# Lambda permission for Auto Update
resource "aws_lambda_permission" "auto_update_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nops_auto_updater_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auto_update.arn
}
