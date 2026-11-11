# Look up an existing IPv4 allowlist IP set
data "aws_wafv2_ip_set" "existing_allow_ipv4" {
  count = (
    var.enable_ip_allowlist &&
    var.allow_ipv4_ip_set_source == "EXISTING"
  ) ? 1 : 0

  name  = var.existing_allow_ipv4_ip_set_name
  scope = var.scope

  lifecycle {
    postcondition {
      condition     = self.ip_address_version == "IPV4"
      error_message = "The existing IPv4 allowlist IP set must have IP address version IPV4."
    }
  }
}

# Look up an existing IPv6 allowlist IP set
data "aws_wafv2_ip_set" "existing_allow_ipv6" {
  count = (
    var.enable_ip_allowlist &&
    var.allow_ipv6_ip_set_source == "EXISTING"
  ) ? 1 : 0

  name  = var.existing_allow_ipv6_ip_set_name
  scope = var.scope

  lifecycle {
    postcondition {
      condition     = self.ip_address_version == "IPV6"
      error_message = "The existing IPv6 allowlist IP set must have IP address version IPV6."
    }
  }
}

# Look up an existing IPv4 blocklist IP set
data "aws_wafv2_ip_set" "existing_block_ipv4" {
  count = (
    var.enable_ip_blocklist &&
    var.block_ipv4_ip_set_source == "EXISTING"
  ) ? 1 : 0

  name  = var.existing_block_ipv4_ip_set_name
  scope = var.scope

  lifecycle {
    postcondition {
      condition     = self.ip_address_version == "IPV4"
      error_message = "The existing IPv4 blocklist IP set must have IP address version IPV4."
    }
  }
}

# Look up an existing IPv6 blocklist IP set
data "aws_wafv2_ip_set" "existing_block_ipv6" {
  count = (
    var.enable_ip_blocklist &&
    var.block_ipv6_ip_set_source == "EXISTING"
  ) ? 1 : 0

  name  = var.existing_block_ipv6_ip_set_name
  scope = var.scope

  lifecycle {
    postcondition {
      condition     = self.ip_address_version == "IPV6"
      error_message = "The existing IPv6 blocklist IP set must have IP address version IPV6."
    }
  }
}