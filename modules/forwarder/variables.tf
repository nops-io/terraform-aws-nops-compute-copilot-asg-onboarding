variable "nasg_eventbus_name" {
  type        = string
  default     = "nops-asg-ec2-instance-state-change"
  description = "nOps ASG Event Bus Name"
}

variable "nasg_central_region" {
  type        = string
  default     = "us-east-1"
  description = "Region where ASG Lambda Function has been deployed"
  validation {
    condition     = can(regex("(us-east-1|us-west-2)", var.nasg_central_region))
    error_message = "The nasg lambda function supports only us-east-1 or us-west-2 as deployment regions."
  }
}
