variable "aws_region" {
  description = "AWS region used by the root AWS provider configuration. CloudFront is a global service, but the provider requires a region."
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_region" {
  description = "AWS region where the existing S3 origin bucket is located."
  type        = string
  default     = "ap-south-1"
}

variable "s3_bucket_arn" {
  description = "ARN of the existing S3 bucket used to configure CloudFront OAC access."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the existing private S3 bucket used as the CloudFront origin."
  type        = string
}

variable "pricing" {
  description = "CloudFront pricing configuration. Controls whether the distribution uses the Pay-As-You-Go model or an eligible flat-rate pricing plan."
  type        = any
  default     = null
}

variable "origin_access_controls" {
  description = "Map of CloudFront Origin Access Control (OAC) configurations used to securely connect CloudFront to private S3 REST origins."
  type        = any
  default     = null
}

variable "origins" {
  description = "Map of origin configurations for the CloudFront distribution, including S3 REST origins and custom HTTP or HTTPS origins."
  type        = any
  default     = null
}


variable "origin_settings" {
  description = "Optional per-origin connection settings. Defaults are used when no custom settings are provided."
  type        = any
  default     = {}
}

variable "ordered_cache_behaviors" {
  description = "Optional additional path-based cache behaviors. Defaults to no additional behaviors."
  type        = any
  default     = {}
}

variable "distribution_enabled" {
  description = "Whether the CloudFront distribution is enabled and able to serve content to viewers."
  type        = bool
  default     = null
}

variable "distribution_comment" {
  description = "Optional descriptive comment to identify the purpose or application associated with the CloudFront distribution."
  type        = string
  default     = null
}

variable "distribution_aliases" {
  description = "Optional list of alternate domain names (CNAMEs) associated with the CloudFront distribution."
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "Object that CloudFront returns when a viewer requests the distribution's root URL, such as index.html."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class that determines the geographic edge locations used to serve content, such as PriceClass_100, PriceClass_200, or PriceClass_All."
  type        = string
  default     = null
}

variable "http_version" {
  description = "Maximum HTTP version supported by the CloudFront distribution, such as http2, http2and3, or http3."
  type        = string
  default     = null
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the CloudFront distribution."
  type        = bool
  default     = null
}

variable "use_default_certificate" {
  description = "Whether to use the default CloudFront certificate for HTTPS. Set to false when using a custom ACM certificate."
  type        = bool
  default     = null
}

variable "acm_certificate_arn" {
  description = "ARN of an existing ACM certificate used for the CloudFront distribution's alternate domain names. The certificate must be provisioned in us-east-1."
  type        = string
  default     = null

  validation {
    condition = (
      var.use_default_certificate == true
      ? var.acm_certificate_arn == null
      : (
        var.acm_certificate_arn != null &&
        can(regex(
          "^arn:[^:]+:acm:us-east-1:[0-9]{12}:certificate/.+$",
          var.acm_certificate_arn
        ))
      )
    )

    error_message = "Use the default CloudFront certificate without an ACM ARN, or provide a valid ACM certificate ARN from us-east-1."
  }
}

variable "minimum_protocol_version" {
  description = "Minimum TLS security protocol supported by viewers connecting to the CloudFront distribution, such as TLSv1.2_2021."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to supported CloudFront resources for identification, ownership, and cost allocation."
  type        = map(string)
  default     = null
}

variable "custom_error_responses" {
  description = "Optional custom error response configurations, including HTTP error codes, replacement response pages, response codes, and error caching durations."
  type        = any
  default     = null
}

variable "cloudfront_functions" {
  description = "Optional CloudFront Functions to create and associate with cache behaviors. Defaults to no functions."
  type        = any
  default     = {}
}

variable "waf_enabled" {
  description = "Whether to associate an existing AWS WAFv2 Web ACL with the CloudFront distribution."
  type        = bool
  default     = null
}

variable "waf_web_acl_arn" {
  description = "ARN of an existing AWS WAFv2 Web ACL with CLOUDFRONT scope to associate with the distribution. The module does not create the Web ACL."
  type        = string
  default     = null
}

variable "default_cache_behavior" {
  description = "Default CloudFront cache behavior. Uses HTTPS redirection, GET and HEAD methods, compression, and AWS-managed caching by default."
  type        = any

  default = {
    target_origin_key      = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    function_associations = []

    cache_policy = {
      type         = "MANAGED"
      managed_name = "CachingOptimized"
      policy_id    = null
      custom       = null
    }

    origin_request_policy = {
      type         = "NONE"
      managed_name = null
      policy_id    = null
      custom       = null
    }

    response_headers_policy = {
      type         = "NONE"
      managed_name = null
      policy_id    = null
      custom       = null
    }
  }
}

variable "geo_restriction_type" {
  description = "Geographic restriction mode for the CloudFront distribution. Use none to allow access from all geographic locations."
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "Country codes for geographic restrictions when whitelist or blacklist is selected."
  type        = list(string)
  default     = []
}


# --------------------------------------------------
# CloudFront Access Logging
# --------------------------------------------------

variable "enable_logging" {
  description = "Whether CloudFront access logging is enabled."
  type        = bool
  default     = false
}

variable "logging_destination_type" {
  description = "Logging destination: S3, CLOUDWATCH_LOGS, KINESIS_FIREHOSE or LEGACY_S3."
  type        = string
  default     = "S3"

  validation {
    condition = contains(
      ["S3", "CLOUDWATCH_LOGS", "KINESIS_FIREHOSE", "LEGACY_S3"],
      var.logging_destination_type
    )
    error_message = "logging_destination_type must be S3, CLOUDWATCH_LOGS, KINESIS_FIREHOSE or LEGACY_S3."
  }
}

variable "existing_s3_bucket_name" {
  description = "Existing S3 bucket for standard or legacy CloudFront access logging."
  type        = string
  default     = null
}

variable "logging_s3_bucket_region" {
  description = "Region of the existing S3 logging bucket."
  type        = string
  default     = "us-east-1"
}

variable "existing_cloudwatch_log_group_name" {
  description = "Existing CloudWatch Logs log group name."
  type        = string
  default     = null
}

variable "existing_firehose_stream_name" {
  description = "Existing Kinesis Data Firehose delivery stream name."
  type        = string
  default     = null
}

variable "logging_source_name" {
  description = "CloudWatch Logs delivery source name for CloudFront."
  type        = string
  default     = "cloudfront-access-logs-source"
}

variable "logging_destination_name" {
  description = "CloudWatch Logs delivery destination name for CloudFront."
  type        = string
  default     = "cloudfront-access-logs-destination"
}

variable "logging_output_format" {
  description = "Output format for standard logging v2."
  type        = string
  default     = "json"
}

variable "logging_s3_prefix" {
  description = "Prefix for legacy CloudFront S3 access logs."
  type        = string
  default     = ""
}

variable "logging_include_cookies" {
  description = "Whether legacy CloudFront logging includes cookies."
  type        = bool
  default     = false
}

variable "logging_s3_suffix_path" {
  description = "Optional suffix path for standard logging v2 S3 delivery."
  type        = string
  default     = null
}

variable "logging_s3_hive_compatible_path" {
  description = "Whether standard logging v2 S3 delivery uses Hive-compatible paths."
  type        = bool
  default     = false
}
