#################################
# S3
#################################

s3_bucket_region = "ap-southeast-2"

bucket_name = "s3-static-website-novartis"

environment = "POC"

project = "NOVARTIS"

application = "S3"

additional_tags = {}

bucket_key_enabled = true

enable_versioning = true

object_ownership = "BucketOwnerEnforced"

block_public_acls       = true
ignore_public_acls      = true
block_public_policy     = true
restrict_public_buckets = true

static_website_type = null

website_index_document = null

website_error_document = null

redirect_host_name = null

redirect_protocol = null

enable_transfer_acceleration = false

enable_requester_pays = false

enable_object_lock = false


#################################
# WAF
#################################
waf_name        = "novartis-poc-web-acl"
waf_description = "WAF for Novartis static website"

scope = "CLOUDFRONT"

app_categories = [
  "Content & publishing systems"
]

app_focus = "WEB"

enable_ip_allowlist = true
enable_ip_blocklist = true

allowed_ipv4_cidrs = []

allowed_ipv6_cidrs = []

blocked_ipv4_cidrs = []

blocked_ipv6_cidrs = []

enable_cloudwatch_metrics = false
enable_sampled_requests   = false

default_action = "ALLOW"

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

enable_country_blocklist = false

enable_country_allowlist = false



# --------------------------------------------------
# CLOUDFRONT
# --------------------------------------------------

pricing = {
  model = "PAY_AS_YOU_GO"
}

distribution_enabled = true
distribution_comment = "CloudFront static website distribution"

price_class     = "PriceClass_All"
http_version    = "http2and3"
is_ipv6_enabled = true

use_default_certificate  = true
minimum_protocol_version = "TLSv1.2_2021"
default_root_object      = "index.html"

waf_enabled = true

tags = {
  Environment = "POC"
  ManagedBy   = "Terraform"
  Project     = "CloudFront-Module"
}


