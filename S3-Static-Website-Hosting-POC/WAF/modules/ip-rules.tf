
locals {
  # Rules for IP sets created by this module
  created_ip_set_rules = {
    for key, ip_set in aws_wafv2_ip_set.this :
    key => {
      name     = "${var.name}-${replace(key, "_", "-")}"
      priority = var.ip_rule_priorities[key]
      action   = startswith(key, "allow") ? "ALLOW" : "BLOCK"
      arn      = ip_set.arn
    }
  }

  # Rules for existing IP sets
  existing_ip_set_rules = merge(

    # Existing IPv4 allowlist
    var.enable_ip_allowlist && var.allow_ipv4_ip_set_source == "EXISTING" ? {
      allow_ipv4 = {
        name     = "${var.name}-allow-ipv4-existing"
        priority = var.ip_rule_priorities["allow_ipv4"]
        action   = "ALLOW"
        arn      = data.aws_wafv2_ip_set.existing_allow_ipv4[0].arn
      }
    } : {},

    # Existing IPv6 allowlist
    var.enable_ip_allowlist && var.allow_ipv6_ip_set_source == "EXISTING" ? {
      allow_ipv6 = {
        name     = "${var.name}-allow-ipv6-existing"
        priority = var.ip_rule_priorities["allow_ipv6"]
        action   = "ALLOW"
        arn      = data.aws_wafv2_ip_set.existing_allow_ipv6[0].arn
      }
    } : {},

    # Existing IPv4 blocklist
    var.enable_ip_blocklist && var.block_ipv4_ip_set_source == "EXISTING" ? {
      block_ipv4 = {
        name     = "${var.name}-block-ipv4-existing"
        priority = var.ip_rule_priorities["block_ipv4"]
        action   = "BLOCK"
        arn      = data.aws_wafv2_ip_set.existing_block_ipv4[0].arn
      }
    } : {},

    # Existing IPv6 blocklist
    var.enable_ip_blocklist && var.block_ipv6_ip_set_source == "EXISTING" ? {
      block_ipv6 = {
        name     = "${var.name}-block-ipv6-existing"
        priority = var.ip_rule_priorities["block_ipv6"]
        action   = "BLOCK"
        arn      = data.aws_wafv2_ip_set.existing_block_ipv6[0].arn
      }
    } : {}
  )

  # Combine newly created and existing IP set rules
  ip_set_rules = merge(
    local.created_ip_set_rules,
    local.existing_ip_set_rules
  )
}
