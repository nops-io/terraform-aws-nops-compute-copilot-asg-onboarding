resource "aws_cloudwatch_event_rule" "ec2_instance_instance_state_change" {
  name           = "nops-asg-ec2-instance-state-change"
  event_bus_name = "default"
  event_pattern = jsonencode({
    source        = ["aws.ec2", "cc_asg_isc_event_retry"]
    "detail-type" = ["EC2 Instance State-change Notification", "EC2 Instance State-change Retry"]
    detail = {
      state : ["pending", "running"]
    }
  })
  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "ec2_instance_state_change_target" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_instance_state_change.name
  target_id = var.nasg_eventbus_name
  role_arn  = aws_iam_role.nasg_eventbus_role.arn
  arn       = "arn:aws:events:${var.nasg_central_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.nasg_eventbus_name}"
}

resource "aws_cloudwatch_event_rule" "asg_ec2_spot_termination_warning" {
  name           = "nops-asg-ec2-spot-termination-warning"
  event_bus_name = "default"
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
  rule      = aws_cloudwatch_event_rule.asg_ec2_spot_termination_warning.name
  target_id = var.nasg_eventbus_name
  role_arn  = aws_iam_role.nasg_eventbus_role.arn
  arn       = "arn:aws:events:${var.nasg_central_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.nasg_eventbus_name}"
}

resource "aws_cloudwatch_event_rule" "ec2_instance_launch_unsuccessful" {
  name           = "nops-asg-ec2-instance-launch-unsuccessful"
  event_bus_name = "default"
  event_pattern = jsonencode({
    source        = ["aws.autoscaling"]
    "detail-type" = ["EC2 Instance Launch Unsuccessful"]
  })
  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "ec2_instance_launch_unsuccessful_target" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_launch_unsuccessful.name
  target_id = var.nasg_eventbus_name
  role_arn  = aws_iam_role.nasg_eventbus_role.arn
  arn       = "arn:aws:events:${var.nasg_central_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.nasg_eventbus_name}"
}
