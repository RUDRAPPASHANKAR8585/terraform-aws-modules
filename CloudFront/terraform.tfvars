# --------------------------------------------------
# AWS Region
# --------------------------------------------------

aws_region = "us-east-1"


# --------------------------------------------------
# CloudFront Pricing
# --------------------------------------------------

pricing = {
  model = "PAY_AS_YOU_GO"
}

# For Flat Rate, users can select this instead:
#
/*
 pricing = {
   model = "FLAT_RATE"

   flat_rate = {
     plan_tier     = "FREE"
     approval_mode = "MANUAL"
     usage_level   = "DEFAULT"
   }
}
*/

# --------------------------------------------------
# Existing S3 Origin
# --------------------------------------------------

origin_access_controls = {
  s3_oac = {
    name             = "cloudfront-poc-s3-oac"
    description      = "OAC for private S3 origin"
    origin_type      = "s3"
    signing_behavior = "always"
  }
}

origins = {
  s3_origin = {
    domain_name               = "s3-static-website-novartis-241452988633-ap-southeast-2.s3.ap-southeast-2.amazonaws.com"
    origin_type               = "S3"
    origin_access_control_key = "s3_oac"
  }
}


# --------------------------------------------------
# Distribution Settings
# --------------------------------------------------

distribution_enabled = true
distribution_comment = "CloudFront static website distribution"

price_class     = "PriceClass_100"
http_version    = "http2and3"
is_ipv6_enabled = true

default_root_object = "index.html"


# --------------------------------------------------
# Viewer Certificate
# --------------------------------------------------

use_default_certificate  = true
minimum_protocol_version = "TLSv1.2_2021"


# --------------------------------------------------
# Custom Error Responses
# --------------------------------------------------

custom_error_responses = [
  {
    error_code            = 403
    response_page_path    = "/Error.HTML"
    response_code         = 403
    error_caching_min_ttl = 10
  },
  {
    error_code            = 404
    response_page_path    = "/Error.HTML"
    response_code         = 404
    error_caching_min_ttl = 10
  }
]


# --------------------------------------------------
# WAF Association
# --------------------------------------------------

waf_enabled     = true
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:241452988633:global/webacl/novartis-poc-web-acl/31d273fd-ca36-4d67-9c36-89d48495b3a7"

# Populate waf_web_acl_arn when WAF is enabled.


# --------------------------------------------------
# Tags
# --------------------------------------------------

tags = {
  Environment = "POC"
  ManagedBy   = "Terraform"
  Project     = "CloudFront-Module"
}

s3_bucket_arn    = "arn:aws:s3:::s3-static-website-novartis-241452988633-ap-southeast-2"
s3_bucket_name   = "s3-static-website-novartis-241452988633-ap-southeast-2"
s3_bucket_region = "ap-southeast-2"

# --------------------------------------------------
# CloudFront Access Logging
# --------------------------------------------------

enable_logging           = true
logging_destination_type = "S3"

existing_s3_bucket_name  = "aws-cloudfront-logs-novartis-poc"
logging_s3_bucket_region = "ap-southeast-2"

logging_output_format  = "json"
logging_s3_suffix_path = "cloudfront/"
logging_s3_prefix      = "cloudfront/"