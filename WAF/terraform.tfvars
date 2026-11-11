name        = "novartis-poc-web-acl"
description = "WAF for Novartis static website"

scope = "CLOUDFRONT"

app_categories = [
  "Content & publishing systems"
]

app_focus = "WEB"


enable_ip_allowlist = true
enable_ip_blocklist = true

allowed_ipv4_cidrs = [
  "192.0.2.0/24"
]

allowed_ipv6_cidrs = []

blocked_ipv4_cidrs = []

blocked_ipv6_cidrs = []


enable_cloudwatch_metrics = true
enable_sampled_requests   = true


ip_rule_priorities = {
  block_ipv4 = 1
  block_ipv6 = 2
  allow_ipv4 = 3
  allow_ipv6 = 4
}


protection_mode             = "RECOMMENDED"
protection_rule_action_mode = "RECOMMENDED"

global_rate_limit            = 1000
get_rate_limit               = 500
write_rate_limit             = 100
managed_ip_ddos_rate_limit   = 1000
rate_limit_evaluation_window = 300

/*
    # IPv4 allowlist configuration
    allow_ipv4_ip_set_source        = "EXISTING"
    existing_allow_ipv4_ip_set_name = "novartis-poc-web-acl_IPV4_Allow"

    # IPv6 allowlist configuration
    allow_ipv6_ip_set_source        = "EXISTING"
    existing_allow_ipv6_ip_set_name = "novartis-poc-web-acl_IPV6_Allow"

    # IPv4 blocklist configuration
    block_ipv4_ip_set_source = "EXISTING"
    #existing_block_ipv4_ip_set_name = "novartis-poc-web-acl_IPV4_Block"
    existing_block_ipv4_ip_set_name = "novartis-poc-web-acl_IPV4_Block"

    # IPv6 blocklist configuration
    block_ipv6_ip_set_source        = "EXISTING"
    existing_block_ipv6_ip_set_name = "novartis-poc-web-acl_IPV6_Block"
    */

# IPv4 allowlist configuration
allow_ipv4_ip_set_source        = "CREATE_NEW"
existing_allow_ipv4_ip_set_name = null

# IPv6 allowlist configuration
allow_ipv6_ip_set_source        = "CREATE_NEW"
existing_allow_ipv6_ip_set_name = null

# IPv4 blocklist configuration
block_ipv4_ip_set_source        = "CREATE_NEW"
existing_block_ipv4_ip_set_name = null

# IPv6 blocklist configuration
block_ipv6_ip_set_source        = "CREATE_NEW"
existing_block_ipv6_ip_set_name = null

/*
    allow_ip_set_source        = "EXISTING"
    existing_allow_ip_set_name = "novartis-poc-web-acl_IPV4_Allow"

    block_ip_set_source        = "EXISTING"
    existing_block_ip_set_name = "novartis-poc-web-acl_IPV4_Block"
    */


default_action = "BLOCK"

enable_country_blocklist = true
blocked_country_codes = [
  "US"
]

enable_country_allowlist = true
allowed_country_codes = [
  "IN",
  "US"
]

country_rule_priorities = {
  block_countries = 5
  allow_countries = 6
}

/*
    existing_s3_bucket_name            = null
    existing_firehose_stream_name      = null
    enable_logging                    = true
    logging_destination_type          = "CLOUDWATCH_LOGS"
    existing_cloudwatch_log_group_name = "aws-waf-logs-novartis-poc"
*/

enable_logging           = true
logging_destination_type = "S3"
existing_s3_bucket_name  = "aws-waf-logs-novartis-poc"

existing_cloudwatch_log_group_name = null
existing_firehose_stream_name      = null