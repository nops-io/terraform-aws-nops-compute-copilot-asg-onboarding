module "wrapper" {
  source = "../"

  for_each = var.items

  auto_update     = try(each.value.auto_update, var.defaults.auto_update, "false")
  environment     = try(each.value.environment, var.defaults.environment, "prd")
  exclude_regions = try(each.value.exclude_regions, var.defaults.exclude_regions, "")
  memory_size     = try(each.value.memory_size, var.defaults.memory_size, 2048)
  timeout         = try(each.value.timeout, var.defaults.timeout, 900)
  token           = try(each.value.token, var.defaults.token)
}
