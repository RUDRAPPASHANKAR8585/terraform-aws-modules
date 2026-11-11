
module "cloudfront" {
  source = "./modules"

  # Pricing
  pricing = var.pricing

  # Origins and OAC
  origin_access_controls = var.origin_access_controls
  origins                = var.origins
  origin_settings        = var.origin_settings

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
  custom_error_responses = var.custom_error_responses

  # Functions and logging
  cloudfront_functions = var.cloudfront_functions
  cloudfront_logging   = local.cloudfront_logging

  # WAF
  waf_enabled     = var.waf_enabled
  waf_web_acl_arn = var.waf_web_acl_arn

  # Tags
  tags = var.tags
}

resource "aws_s3_bucket_policy" "cloudfront_oac" {
  provider = aws.s3

  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}