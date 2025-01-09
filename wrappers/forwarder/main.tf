module "wrapper" {
  source = "../../modules/forwarder"

  for_each = var.items

  nasg_central_region = try(each.value.nasg_central_region, var.defaults.nasg_central_region, "us-east-1")
  nasg_eventbus_name  = try(each.value.nasg_eventbus_name, var.defaults.nasg_eventbus_name, "nops-asg-ec2-instance-state-change")
}
