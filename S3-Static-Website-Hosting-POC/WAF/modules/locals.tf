
locals {
  # IP set configurations
  ip_sets = {
    allow_ipv4 = {
      name               = "${var.name}-IPv4-Allow"
      ip_address_version = "IPV4"
      addresses          = var.allowed_ipv4_cidrs
      enabled            = var.enable_ip_allowlist
    }

    allow_ipv6 = {
      name               = "${var.name}-IPv6-Allow"
      ip_address_version = "IPV6"
      addresses          = var.allowed_ipv6_cidrs
      enabled            = var.enable_ip_allowlist
    }

    block_ipv4 = {
      name               = "${var.name}-IPv4-Block"
      ip_address_version = "IPV4"
      addresses          = var.blocked_ipv4_cidrs
      enabled            = var.enable_ip_blocklist
    }

    block_ipv6 = {
      name               = "${var.name}-IPv6-Block"
      ip_address_version = "IPV6"
      addresses          = var.blocked_ipv6_cidrs
      enabled            = var.enable_ip_blocklist
    }
  }

  # Create only enabled IP sets when their source is CREATE_NEW
  active_ip_sets = {
    for key, config in local.ip_sets :
    key => config
    if(
      config.enabled &&
      length(config.addresses) > 0 &&
      (
        (key == "allow_ipv4" && var.allow_ipv4_ip_set_source == "CREATE_NEW") ||
        (key == "allow_ipv6" && var.allow_ipv6_ip_set_source == "CREATE_NEW") ||
        (key == "block_ipv4" && var.block_ipv4_ip_set_source == "CREATE_NEW") ||
        (key == "block_ipv6" && var.block_ipv6_ip_set_source == "CREATE_NEW")
      )
    )
  }

  # Visibility configuration
  visibility_config = {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    sampled_requests_enabled   = var.enable_sampled_requests
    metric_name                = var.name
  }

  # Application configuration
  application_configuration = {
    categories = sort(tolist(var.app_categories))
    focus      = var.app_focus
  }


  # Collect priorities from all currently active WAF rules
  active_rule_priorities = concat(
    [
      for rule in values(local.ip_set_rules) :
      rule.priority
    ],
    [
      for rule in values(local.active_rate_based_rules) :
      rule.priority
    ],
    [
      for rule in values(local.active_country_rules) :
      rule.priority
    ]
  )
}
