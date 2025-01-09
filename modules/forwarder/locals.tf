locals {
  nasg_eventbus_arn = "arn:aws:events:${var.nasg_central_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.nasg_eventbus_name}"
}
