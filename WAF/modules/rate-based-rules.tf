
locals {
  rate_based_rules = {
    global = {
      name     = "${var.name}-global-rate-limit"
      priority = 10
      limit    = var.global_rate_limit
      methods  = []
      enabled  = true
    }

    get = {
      name     = "${var.name}-get-rate-limit"
      priority = 11
      limit    = var.get_rate_limit
      methods  = ["GET"]
      enabled  = var.protection_mode == "RECOMMENDED"
    }

    write = {
      name     = "${var.name}-write-rate-limit"
      priority = 12
      limit    = var.write_rate_limit
      methods  = ["POST", "PUT", "DELETE"]
      enabled  = var.protection_mode == "RECOMMENDED"
    }
  }

  active_rate_based_rules = {
    for key, rule in local.rate_based_rules :
    key => rule
    if rule.enabled
  }
}
