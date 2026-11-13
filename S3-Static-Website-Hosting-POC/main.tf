
module "s3" {

  source = "./S3/modules"

  providers = {
    aws = aws.s3
  }

  bucket_name = var.bucket_name

  environment = var.environment

  project = var.project

  application = var.application

  additional_tags = var.additional_tags

  force_destroy = var.force_destroy

  encryption_type = var.encryption_type

  kms_key_type = var.kms_key_type

  kms_key_alias = var.kms_key_alias

  bucket_key_enabled = var.bucket_key_enabled

  enable_versioning = var.enable_versioning

  object_ownership = var.object_ownership

  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets

  static_website_type = var.static_website_type

  website_index_document = var.website_index_document

  website_error_document = var.website_error_document

  redirect_host_name = var.redirect_host_name

  redirect_protocol = var.redirect_protocol

  enable_transfer_acceleration = var.enable_transfer_acceleration

  enable_requester_pays = var.enable_requester_pays

  enable_object_lock = var.enable_object_lock

  object_lock_mode = var.object_lock_mode

  object_lock_days = var.object_lock_days

}

module "waf" {
  source = "./WAF/modules"

  providers = {
    aws = aws.waf
  }

  # General configuration
  name        = var.waf_name
  description = var.waf_description
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
  # WAF Logging
  enable_logging                     = var.waf_enable_logging
  logging_destination_type           = var.waf_logging_destination_type
  existing_cloudwatch_log_group_name = var.waf_existing_cloudwatch_log_group_name
  existing_s3_bucket_name            = var.waf_existing_s3_bucket_name
  existing_firehose_stream_name      = var.waf_existing_firehose_stream_name
}



module "cloudfront" {
  source = "./CloudFront/modules"

  providers = {
    aws = aws.cloudfront
  }

  # Pricing
  pricing = var.pricing

  # S3 origin
  origins = {
    s3_origin = {
      domain_name               = module.s3.bucket_regional_domain_name
      origin_type               = "S3"
      origin_access_control_key = "s3_oac"
    }
  }

  # Origin Access Control
  origin_access_controls = {
    s3_oac = {
      name             = "static-website-oac"
      origin_type      = "s3"
      signing_behavior = "always"
    }
  }

  origin_settings = var.origin_settings

  # Cache behaviors
  default_cache_behavior  = var.default_cache_behavior
  ordered_cache_behaviors = var.ordered_cache_behaviors

  # Distribution
  distribution_enabled = var.distribution_enabled
  distribution_comment = var.distribution_comment
  distribution_aliases = var.distribution_aliases
  default_root_object  = var.default_root_object
  price_class          = var.price_class
  http_version         = var.http_version
  is_ipv6_enabled      = var.is_ipv6_enabled

  # Geo restrictions
  geo_restriction_type      = var.geo_restriction_type
  geo_restriction_locations = var.geo_restriction_locations

  # Viewer certificate
  use_default_certificate  = var.use_default_certificate
  acm_certificate_arn      = var.acm_certificate_arn
  minimum_protocol_version = var.minimum_protocol_version

  # Error responses
  custom_error_responses = coalesce(
    var.custom_error_responses,
    []
  )

  # Functions and logging
  cloudfront_functions = var.cloudfront_functions
  cloudfront_logging   = local.cloudfront_logging

  # WAF
  waf_enabled     = var.waf_enabled
  waf_web_acl_arn = module.waf.web_acl_arn

  # Tags
  tags = var.tags
}


resource "aws_s3_bucket_policy" "cloudfront_oac" {
  provider = aws.s3

  bucket = module.s3.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      # Wiz - Deny unencrypted object uploads
      {
        Sid       = "WizDenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"

        Resource = "${module.s3.bucket_arn}/*"

        Condition = {
          StringNotEqualsIfExists = {
            "s3:x-amz-server-side-encryption" = [
              "aws:kms",
              "AES256"
            ]
          }

          Null = {
            "s3:x-amz-server-side-encryption" = "false"
          }
        }
      },

      # Deny requests without HTTPS
      {
        Sid       = "MustBeEncryptedInTransit"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          module.s3.bucket_arn,
          "${module.s3.bucket_arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },

      # Allow CloudFront OAC to access S3 objects
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = "s3:GetObject"

        Resource = "${module.s3.bucket_arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [
    module.s3,
    module.waf,
    module.cloudfront
  ]
}

