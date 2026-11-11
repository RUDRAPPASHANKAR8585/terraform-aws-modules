
locals {
  country_rules = {
    block_countries = {
      name          = "${var.name}-block-countries"
      priority      = var.country_rule_priorities["block_countries"]
      action        = "BLOCK"
      country_codes = var.blocked_country_codes
      enabled       = var.enable_country_blocklist
    }

    allow_countries = {
      name          = "${var.name}-allow-countries"
      priority      = var.country_rule_priorities["allow_countries"]
      action        = "ALLOW"
      country_codes = var.allowed_country_codes
      enabled       = var.enable_country_allowlist
    }
  }

  active_country_rules = {
    for key, rule in local.country_rules :
    key => rule
    if rule.enabled && length(rule.country_codes) > 0
  }
}
