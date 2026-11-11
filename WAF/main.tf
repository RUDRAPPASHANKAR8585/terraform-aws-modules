
module "waf" {
  source = "./modules"

  # General configuration
  name        = var.name
  description = var.description
  scope       = var.scope

  # Application configuration
  app_categories = var.app_categories
  app_focus      = var.app_focus

  # Default action
  default_action = var.default_action

  # IP allowlist and blocklist
  enable_ip_allowlist = var.enable_ip_allowlist
  enable_ip_blocklist = var.enable_ip_blocklist

  allowed_ipv4_cidrs = var.allowed_ipv4_cidrs
  allowed_ipv6_cidrs = var.allowed_ipv6_cidrs
  blocked_ipv4_cidrs = var.blocked_ipv4_cidrs
  blocked_ipv6_cidrs = var.blocked_ipv6_cidrs

  ip_rule_priorities = var.ip_rule_priorities

  # IP set source selection
  allow_ipv4_ip_set_source        = var.allow_ipv4_ip_set_source
  existing_allow_ipv4_ip_set_name = var.existing_allow_ipv4_ip_set_name

  allow_ipv6_ip_set_source        = var.allow_ipv6_ip_set_source
  existing_allow_ipv6_ip_set_name = var.existing_allow_ipv6_ip_set_name

  block_ipv4_ip_set_source        = var.block_ipv4_ip_set_source
  existing_block_ipv4_ip_set_name = var.existing_block_ipv4_ip_set_name

  block_ipv6_ip_set_source        = var.block_ipv6_ip_set_source
  existing_block_ipv6_ip_set_name = var.existing_block_ipv6_ip_set_name

  # Country-based protection
  enable_country_allowlist = var.enable_country_allowlist
  allowed_country_codes    = var.allowed_country_codes

  enable_country_blocklist = var.enable_country_blocklist
  blocked_country_codes    = var.blocked_country_codes

  country_rule_priorities = var.country_rule_priorities

  # Protection configuration
  protection_mode             = var.protection_mode
  protection_rule_action_mode = var.protection_rule_action_mode

  # Rate-based protection
  global_rate_limit          = var.global_rate_limit
  get_rate_limit             = var.get_rate_limit
  write_rate_limit           = var.write_rate_limit
  managed_ip_ddos_rate_limit = var.managed_ip_ddos_rate_limit

  rate_limit_evaluation_window = var.rate_limit_evaluation_window

  # Monitoring
  enable_cloudwatch_metrics = var.enable_cloudwatch_metrics
  enable_sampled_requests   = var.enable_sampled_requests

  # Logging
  enable_logging                     = var.enable_logging
  logging_destination_type           = var.logging_destination_type
  existing_cloudwatch_log_group_name = var.existing_cloudwatch_log_group_name
  existing_s3_bucket_name            = var.existing_s3_bucket_name
  existing_firehose_stream_name      = var.existing_firehose_stream_name
}
