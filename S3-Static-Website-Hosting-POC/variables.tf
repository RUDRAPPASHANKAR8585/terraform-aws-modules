variable "cloudfront_region" {
  description = "AWS region used by the root AWS provider configuration. CloudFront is a global service, but the provider requires a region."
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_region" {
  description = "AWS region where the existing S3 origin bucket is located."
  type        = string
  default     = "eu-west-2"
}

variable "pricing" {
  description = "CloudFront pricing configuration. Controls whether the distribution uses the Pay-As-You-Go model or an eligible flat-rate pricing plan."
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
# --------------------------------------------------
# CloudFront Access Logging
# --------------------------------------------------

variable "cloudfront_enable_logging" {
  description = "Enable or disable CloudFront access logging."
  type        = bool
  default     = false
}

variable "cloudfront_logging_destination_type" {
  description = "CloudFront logging destination: S3, CLOUDWATCH_LOGS, KINESIS_FIREHOSE or LEGACY_S3."
  type        = string
  default     = "S3"

  validation {
    condition = contains(
      ["S3", "CLOUDWATCH_LOGS", "KINESIS_FIREHOSE", "LEGACY_S3"],
      var.cloudfront_logging_destination_type
    )
    error_message = "Valid values are S3, CLOUDWATCH_LOGS, KINESIS_FIREHOSE or LEGACY_S3."
  }
}

variable "cloudfront_existing_s3_bucket_name" {
  description = "Existing S3 bucket for CloudFront access logs."
  type        = string
  default     = null
}

variable "cloudfront_logging_s3_bucket_region" {
  description = "Region of the existing CloudFront logging S3 bucket."
  type        = string
  default     = "us-east-1"
}

variable "cloudfront_existing_cloudwatch_log_group_name" {
  description = "Existing CloudWatch log group for CloudFront access logs."
  type        = string
  default     = null
}

variable "cloudfront_existing_firehose_stream_name" {
  description = "Existing Firehose delivery stream for CloudFront access logs."
  type        = string
  default     = null
}

variable "cloudfront_logging_source_name" {
  description = "CloudWatch Logs delivery source name for CloudFront."
  type        = string
  default     = "cloudfront-access-logs-source"
}

variable "cloudfront_logging_destination_name" {
  description = "CloudWatch Logs delivery destination name for CloudFront."
  type        = string
  default     = "cloudfront-access-logs-destination"
}

variable "cloudfront_logging_output_format" {
  description = "Output format for CloudFront standard logging v2."
  type        = string
  default     = "json"
}

variable "cloudfront_logging_s3_prefix" {
  description = "Prefix for legacy CloudFront S3 access logs."
  type        = string
  default     = ""
}

variable "cloudfront_logging_include_cookies" {
  description = "Whether legacy CloudFront logging includes cookies."
  type        = bool
  default     = false
}

variable "cloudfront_logging_s3_suffix_path" {
  description = "Optional suffix path for CloudFront standard logging v2 S3 delivery."
  type        = string
  default     = null
}

variable "cloudfront_logging_s3_hive_compatible_path" {
  description = "Enable Hive-compatible S3 paths for CloudFront standard logging v2."
  type        = bool
  default     = false
}





####################################
# Bucket Configuration
####################################

variable "bucket_name" {

  description = "Name of the S3 bucket. Must be globally unique."

  type = string


  validation {

    condition = can(regex(
      "^[a-z0-9][a-z0-9.-]+[a-z0-9]$",
      var.bucket_name
    ))

    error_message = "Bucket name must follow AWS naming conventions."

  }

}

variable "force_destroy" {
  description = "Allow Terraform to delete all objects in the bucket when destroying it."
  type        = bool
  default     = false
}

##############################################################################
# Default Server-Side Encryption
##############################################################################

variable "encryption_type" {

  description = "Specifies the default server-side encryption algorithm for the S3 bucket."

  type    = string
  default = "AES256"

}

##############################################################################
# AWS KMS Key Type
##############################################################################

variable "kms_key_type" {

  description = "Specifies whether to use the AWS managed KMS key or a customer-managed KMS key."

  type    = string
  default = "AWS_MANAGED"

}

##############################################################################
# Customer Managed KMS Key ARN
##############################################################################

variable "kms_key_alias" {

  description = "Alias of the customer-managed AWS KMS key."

  type     = string
  default  = null
  nullable = true

}

##############################################################################
# Amazon S3 Bucket Key
##############################################################################

variable "bucket_key_enabled" {

  description = "Enable Amazon S3 Bucket Keys when using SSE-KMS."

  type    = bool
  default = true

}

####################################
# Versioning
####################################

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket."
  type        = bool
  default     = true
}

####################################
# Public Access Block
####################################

variable "block_public_acls" {
  description = "Block public ACLs."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets."
  type        = bool
  default     = true
}

####################################
# Ownership Controls
####################################

variable "object_ownership" {
  description = "S3 Object Ownership setting."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition = contains([
      "BucketOwnerEnforced",
      "BucketOwnerPreferred",
      "ObjectWriter"
    ], var.object_ownership)

    error_message = "Valid values are BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  }
}
####################################
# Tags
####################################

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "application" {
  description = "Application name."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags."

  type = map(string)

  default = {}
}

####################################
# Object Lock
####################################

variable "enable_object_lock" {
  description = "Enable object lock."

  type = bool

  default = false
}

variable "object_lock_mode" {
  description = "Default retention mode for S3 Object Lock."
  type        = string
  default     = "GOVERNANCE"

  validation {

    condition = contains(
      [
        "GOVERNANCE",
        "COMPLIANCE"
      ],
      upper(coalesce(var.object_lock_mode, "GOVERNANCE"))
    )

    error_message = "Valid values are GOVERNANCE or COMPLIANCE."

  }
}

variable "object_lock_days" {
  description = "Retention period in days."
  type        = number
  default     = null

  validation {

    condition = (
      var.object_lock_days == null ?
      true :
      var.object_lock_days > 0
    )
    error_message = "Retention days must be greater than zero."
  }
}

##############################################################################
# Static Website Hosting
##############################################################################

variable "static_website_type" {

  description = <<-EOT

Amazon S3 Static Website Hosting configuration.

Supported Values:
- null
- website
- redirect

Examples:

static_website_type = null

static_website_type = "website"

static_website_type = "redirect"


NOTES:
- null disables Static Website Hosting.
- website enables Amazon S3 Static Website Hosting.
- redirect enables Amazon S3 Redirect Website Hosting.
- Only one hosting type may be configured at a time.

EOT

  type    = string
  default = null


  validation {

    condition = (

      var.static_website_type == null ?

      true :

      contains(
        [
          "website",
          "redirect"
        ],

        lower(var.static_website_type)

      )

    )

    error_message = "Valid values are website or redirect."

  }

}

##############################################################################
# Website Hosting
##############################################################################

variable "website_index_document" {

  description = <<-EOT

Index document for Amazon S3 Static Website Hosting.

Examples:
- index.html
- home.html
- default.html

NOTES:
- Required only when:
    static_website_type = "website"
- Acts as the default page returned when users access
  the website endpoint.

EOT

  type    = string
  default = null

}

variable "website_error_document" {

  description = <<-EOT

Error document for Amazon S3 Static Website Hosting.

Examples:
- error.html
- 404.html
- access-denied.html

NOTES:
- Optional.
- Used only when:
    static_website_type = "website"
- Displays a custom error page when website requests fail.

EOT

  type    = string
  default = null

}

##############################################################################
# Redirect Website Hosting
##############################################################################

variable "redirect_host_name" {

  description = <<-EOT

Host name used when redirecting website requests.

Examples:
- www.example.com
- example.com
- bucket.s3-website.ap-south-1.amazonaws.com

NOTES:
- Required only when:
    static_website_type = "redirect"
- Amazon S3 redirects all incoming requests to the
  specified host name.

EOT

  type    = string
  default = null

}

variable "redirect_protocol" {

  description = <<-EOT

Protocol used when redirecting website requests.

Supported Values:
- http
- https
- null

Examples:

redirect_protocol = "https"

redirect_protocol = "http"

redirect_protocol = null

NOTES:
- Optional.
- Used only when:
    static_website_type = "redirect"
- When set to null, Amazon S3 preserves the original
  request protocol.

EOT

  type    = string
  default = null


  validation {

    condition = (

      var.redirect_protocol == null ?

      true :

      contains(
        [
          "http",
          "https"
        ],

        lower(var.redirect_protocol)

      )

    )

    error_message = "Valid values are http or https."

  }

}
####################################
# Transfer Acceleration
####################################

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration."
  type        = bool
  default     = false
}

####################################
# Requester Pays
####################################

variable "enable_requester_pays" {
  description = "Enable Requester Pays for the bucket."
  type        = bool
  default     = false
}





variable "waf_region" {
  description = "AWS region used by the root AWS provider. waf requires a region."
  type        = string
  default     = "us-east-1"
}

variable "waf_name" {
  description = "Name of the AWS WAF Web ACL."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.waf_name)) && length(var.waf_name) <= 128
    error_message = "WAF name must contain only letters, numbers, and hyphens, with a maximum length of 128 characters."
  }
}

variable "waf_description" {
  description = "Description of the WAF Web ACL."
  type        = string
  default     = null
}

variable "scope" {
  description = "Scope of the WAF Web ACL. CLOUDFRONT requires the provider in us-east-1."
  type        = string
  default     = "CLOUDFRONT"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "app_categories" {
  description = "Select one or more application categories from the AWS WAF protection-pack wizard."

  type = set(string)

  validation {
    condition = (
      length(var.app_categories) > 0 &&
      alltrue([
        for category in var.app_categories :
        contains([
          "Content & publishing systems",
          "E-commerce & transaction platforms",
          "Enterprise & business applications",
          "API & integration services",
          "Media & file processing",
          "Other"
        ], category)
      ])
    )

    error_message = "Select at least one valid application category from the supported AWS WAF application categories."
  }
}

variable "app_focus" {
  description = "Select the application traffic focus: BOTH, API, or WEB."

  type = string

  validation {
    condition = contains(
      ["BOTH", "API", "WEB"],
      var.app_focus
    )

    error_message = "Valid app_focus values are BOTH, API, or WEB."
  }
}

variable "default_action" {
  description = "Default action when no WAF rule matches."
  type        = string
  default     = "BLOCK"

  validation {
    condition     = contains(["ALLOW", "BLOCK"], var.default_action)
    error_message = "Default action must be ALLOW or BLOCK."
  }
}

variable "enable_ip_allowlist" {
  description = "Enable IP allowlist protection."
  type        = bool
  default     = false
}

variable "enable_ip_blocklist" {
  description = "Enable IP blocklist protection."
  type        = bool
  default     = false
}


variable "allowed_ipv4_cidrs" {
  description = "IPv4 CIDR ranges permitted by the allowlist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ipv4_cidrs :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every allowed_ipv4_cidrs entry must be a valid IPv4 CIDR range with a prefix between /0 and /32."
  }

  validation {
    condition     = length(distinct(var.allowed_ipv4_cidrs)) == length(var.allowed_ipv4_cidrs)
    error_message = "Duplicate CIDR entries are not allowed in allowed_ipv4_cidrs."
  }
}

variable "allowed_ipv6_cidrs" {
  description = "IPv6 CIDR ranges permitted by the allowlist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_ipv6_cidrs :
      strcontains(cidr, ":") && can(cidrhost(cidr, 0))
    ])

    error_message = "Every allowed_ipv6_cidrs entry must be a valid IPv6 CIDR range with a prefix between /0 and /128."
  }

  validation {
    condition     = length(distinct(var.allowed_ipv6_cidrs)) == length(var.allowed_ipv6_cidrs)
    error_message = "Duplicate CIDR entries are not allowed in allowed_ipv6_cidrs."
  }
}

variable "blocked_ipv4_cidrs" {
  description = "IPv4 CIDR ranges denied by the blocklist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.blocked_ipv4_cidrs :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every blocked_ipv4_cidrs entry must be a valid IPv4 CIDR range with a prefix between /0 and /32."
  }

  validation {
    condition     = length(distinct(var.blocked_ipv4_cidrs)) == length(var.blocked_ipv4_cidrs)
    error_message = "Duplicate CIDR entries are not allowed in blocked_ipv4_cidrs."
  }
}

variable "blocked_ipv6_cidrs" {
  description = "IPv6 CIDR ranges denied by the blocklist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.blocked_ipv6_cidrs :
      strcontains(cidr, ":") && can(cidrhost(cidr, 0))
    ])

    error_message = "Every blocked_ipv6_cidrs entry must be a valid IPv6 CIDR range with a prefix between /0 and /128."
  }

  validation {
    condition     = length(distinct(var.blocked_ipv6_cidrs)) == length(var.blocked_ipv6_cidrs)
    error_message = "Duplicate CIDR entries are not allowed in blocked_ipv6_cidrs."
  }
}


variable "enable_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics for the Web ACL and its rules."
  type        = bool
  default     = true
}

variable "enable_sampled_requests" {
  description = "Enable sampled request collection."
  type        = bool
  default     = true
}


variable "ip_rule_priorities" {
  description = "Priority assigned to each IP-based WAF rule."
  type        = map(number)

  default = {
    block_ipv4 = 1
    block_ipv6 = 2
    allow_ipv4 = 3
    allow_ipv6 = 4
  }

  validation {
    condition = (
      toset(keys(var.ip_rule_priorities)) == toset([
        "allow_ipv4",
        "allow_ipv6",
        "block_ipv4",
        "block_ipv6"
      ]) &&
      alltrue([
        for priority in values(var.ip_rule_priorities) :
        priority >= 0 && floor(priority) == priority
      ])
    )

    error_message = "IP rule priorities must contain exactly the four supported IP rule keys and each priority must be a non-negative whole number."
  }
}



variable "protection_mode" {
  description = "Select the initial AWS WAF protection package."
  type        = string

  validation {
    condition = contains(
      ["RECOMMENDED", "ESSENTIAL"],
      var.protection_mode
    )

    error_message = "Valid protection modes are RECOMMENDED or ESSENTIAL. CUSTOM is deferred to a future phase."
  }
}

variable "protection_rule_action_mode" {
  description = "Use the protection package's recommended rule actions or put applicable rules into COUNT mode."
  type        = string
  default     = "RECOMMENDED"

  validation {
    condition = contains(
      ["RECOMMENDED", "COUNT"],
      var.protection_rule_action_mode
    )

    error_message = "Valid protection rule action modes are RECOMMENDED or COUNT."
  }
}


variable "global_rate_limit" {
  description = "Maximum requests per IP for the global rate-based rule."
  type        = number
  default     = 1000

  validation {
    condition     = var.global_rate_limit >= 10 && var.global_rate_limit <= 2000000000 && floor(var.global_rate_limit) == var.global_rate_limit
    error_message = "Global rate limit must be a whole number between 10 and 2,000,000,000."
  }
}

variable "get_rate_limit" {
  description = "Maximum GET requests per IP within the evaluation window."
  type        = number
  default     = 500

  validation {
    condition     = var.get_rate_limit >= 10 && var.get_rate_limit <= 2000000000 && floor(var.get_rate_limit) == var.get_rate_limit
    error_message = "GET rate limit must be a whole number between 10 and 2,000,000,000."
  }
}

variable "write_rate_limit" {
  description = "Maximum POST, PUT and DELETE requests per IP within the evaluation window."
  type        = number
  default     = 100

  validation {
    condition     = var.write_rate_limit >= 10 && var.write_rate_limit <= 2000000000 && floor(var.write_rate_limit) == var.write_rate_limit
    error_message = "Write request rate limit must be a whole number between 10 and 2,000,000,000."
  }
}

variable "managed_ip_ddos_rate_limit" {
  description = "Rate threshold configured for the managed IP DDoS protection."
  type        = number
  default     = 1000

  validation {
    condition     = var.managed_ip_ddos_rate_limit >= 10 && var.managed_ip_ddos_rate_limit <= 2000000000 && floor(var.managed_ip_ddos_rate_limit) == var.managed_ip_ddos_rate_limit
    error_message = "Managed IP DDoS rate limit must be a whole number between 10 and 2,000,000,000."
  }
}

variable "rate_limit_evaluation_window" {
  description = "Rate-based rule evaluation window in seconds."
  type        = number
  default     = 300

  validation {
    condition     = contains([60, 120, 300, 600], var.rate_limit_evaluation_window)
    error_message = "Evaluation window must be 60, 120, 300, or 600 seconds."
  }
}


# IPv4 allowlist source selection
variable "allow_ipv4_ip_set_source" {
  description = "Choose whether to create a new IPv4 allowlist IP set or use an existing one."
  type        = string
  default     = "CREATE_NEW"

  validation {
    condition     = contains(["CREATE_NEW", "EXISTING"], var.allow_ipv4_ip_set_source)
    error_message = "allow_ipv4_ip_set_source must be CREATE_NEW or EXISTING."
  }
}

variable "existing_allow_ipv4_ip_set_name" {
  description = "Name of an existing IPv4 AWS WAF allowlist IP set."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.allow_ipv4_ip_set_source != "EXISTING" ||
      (var.existing_allow_ipv4_ip_set_name != null && trimspace(var.existing_allow_ipv4_ip_set_name) != "")
    )
    error_message = "Provide an existing IPv4 allowlist IP set name when allow_ipv4_ip_set_source is EXISTING."
  }
  validation {
    condition = (
      var.allow_ipv4_ip_set_source != "EXISTING" ||
      var.block_ipv4_ip_set_source != "EXISTING" ||
      var.existing_allow_ipv4_ip_set_name != var.existing_block_ipv4_ip_set_name
    )

    error_message = "The same existing IPv4 IP set cannot be used for both allowlist and blocklist."
  }
}

# IPv6 allowlist source selection
variable "allow_ipv6_ip_set_source" {
  description = "Choose whether to create a new IPv6 allowlist IP set or use an existing one."
  type        = string
  default     = "CREATE_NEW"

  validation {
    condition     = contains(["CREATE_NEW", "EXISTING"], var.allow_ipv6_ip_set_source)
    error_message = "allow_ipv6_ip_set_source must be CREATE_NEW or EXISTING."
  }
}

variable "existing_allow_ipv6_ip_set_name" {
  description = "Name of an existing IPv6 AWS WAF allowlist IP set."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.allow_ipv6_ip_set_source != "EXISTING" ||
      (var.existing_allow_ipv6_ip_set_name != null && trimspace(var.existing_allow_ipv6_ip_set_name) != "")
    )
    error_message = "Provide an existing IPv6 allowlist IP set name when allow_ipv6_ip_set_source is EXISTING."
  }
  validation {
    condition = (
      var.allow_ipv6_ip_set_source != "EXISTING" ||
      var.block_ipv6_ip_set_source != "EXISTING" ||
      var.existing_allow_ipv6_ip_set_name != var.existing_block_ipv6_ip_set_name
    )

    error_message = "The same existing IPv6 IP set cannot be used for both allowlist and blocklist."
  }
}

# IPv4 blocklist source selection
variable "block_ipv4_ip_set_source" {
  description = "Choose whether to create a new IPv4 blocklist IP set or use an existing one."
  type        = string
  default     = "CREATE_NEW"

  validation {
    condition     = contains(["CREATE_NEW", "EXISTING"], var.block_ipv4_ip_set_source)
    error_message = "block_ipv4_ip_set_source must be CREATE_NEW or EXISTING."
  }
}

variable "existing_block_ipv4_ip_set_name" {
  description = "Name of an existing IPv4 AWS WAF blocklist IP set."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.block_ipv4_ip_set_source != "EXISTING" ||
      (var.existing_block_ipv4_ip_set_name != null && trimspace(var.existing_block_ipv4_ip_set_name) != "")
    )
    error_message = "Provide an existing IPv4 blocklist IP set name when block_ipv4_ip_set_source is EXISTING."
  }
}

# IPv6 blocklist source selection
variable "block_ipv6_ip_set_source" {
  description = "Choose whether to create a new IPv6 blocklist IP set or use an existing one."
  type        = string
  default     = "CREATE_NEW"

  validation {
    condition     = contains(["CREATE_NEW", "EXISTING"], var.block_ipv6_ip_set_source)
    error_message = "block_ipv6_ip_set_source must be CREATE_NEW or EXISTING."
  }
}

variable "existing_block_ipv6_ip_set_name" {
  description = "Name of an existing IPv6 AWS WAF blocklist IP set."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.block_ipv6_ip_set_source != "EXISTING" ||
      (var.existing_block_ipv6_ip_set_name != null && trimspace(var.existing_block_ipv6_ip_set_name) != "")
    )
    error_message = "Provide an existing IPv6 blocklist IP set name when block_ipv6_ip_set_source is EXISTING."
  }
}


variable "enable_country_allowlist" {
  description = "Whether to allow requests only from the configured country allowlist."
  type        = bool
  default     = false
}

variable "allowed_country_codes" {
  description = "ISO 3166-1 alpha-2 country codes allowed by the country allowlist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for country in var.allowed_country_codes :
      can(regex("^[A-Z]{2}$", country))
    ])
    error_message = "Every allowed_country_codes entry must be an uppercase two-letter country code, such as IN, US, or GB."
  }

  validation {
    condition     = length(distinct(var.allowed_country_codes)) == length(var.allowed_country_codes)
    error_message = "Duplicate country codes are not allowed in allowed_country_codes."
  }

  validation {
    condition     = !var.enable_country_allowlist || length(var.allowed_country_codes) > 0
    error_message = "At least one country code must be provided when enable_country_allowlist is true."
  }
}

variable "enable_country_blocklist" {
  description = "Whether to block requests originating from the configured countries."
  type        = bool
  default     = false
}

variable "blocked_country_codes" {
  description = "ISO 3166-1 alpha-2 country codes blocked by the country blocklist."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for country in var.blocked_country_codes :
      can(regex("^[A-Z]{2}$", country))
    ])
    error_message = "Every blocked_country_codes entry must be an uppercase two-letter country code, such as IN, US, or GB."
  }

  validation {
    condition     = length(distinct(var.blocked_country_codes)) == length(var.blocked_country_codes)
    error_message = "Duplicate country codes are not allowed in blocked_country_codes."
  }

  validation {
    condition     = !var.enable_country_blocklist || length(var.blocked_country_codes) > 0
    error_message = "At least one country code must be provided when enable_country_blocklist is true."
  }
}

variable "country_rule_priorities" {
  description = "Priority assigned to country-based WAF rules."

  type = map(number)

  default = {
    block_countries = 5
    allow_countries = 6
  }

  validation {
    condition = (
      toset(keys(var.country_rule_priorities)) == toset([
        "allow_countries",
        "block_countries"
      ]) &&
      alltrue([
        for priority in values(var.country_rule_priorities) :
        priority >= 0 && floor(priority) == priority
      ])
    )
    error_message = "Country rule priorities must contain exactly allow_countries and block_countries, each with a non-negative whole number."
  }
}


variable "waf_enable_logging" {
  description = "Enable or disable AWS WAF logging."
  type        = bool
  default     = false
}

variable "waf_logging_destination_type" {
  description = "Existing logging destination type: CLOUDWATCH_LOGS, S3, or FIREHOSE."
  type        = string
  default     = "CLOUDWATCH_LOGS"

  validation {
    condition = contains(
      ["CLOUDWATCH_LOGS", "S3", "FIREHOSE"],
      var.waf_logging_destination_type
    )
    error_message = "waf_logging_destination_type must be CLOUDWATCH_LOGS, S3, or FIREHOSE."
  }
}

variable "waf_existing_cloudwatch_log_group_name" {
  description = "Name of the existing CloudWatch Logs log group for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.waf_enable_logging ||
      var.waf_logging_destination_type != "CLOUDWATCH_LOGS" ||
      (var.waf_existing_cloudwatch_log_group_name != null &&
      trimspace(var.waf_existing_cloudwatch_log_group_name) != "")
    )
    error_message = "Provide waf_existing_cloudwatch_log_group_name when logging is enabled with CLOUDWATCH_LOGS."
  }

  validation {
    condition = (
      var.waf_logging_destination_type == "CLOUDWATCH_LOGS" ||
      var.waf_existing_cloudwatch_log_group_name == null
    )
    error_message = "Set waf_existing_cloudwatch_log_group_name only when CLOUDWATCH_LOGS is selected."
  }
}

variable "waf_existing_s3_bucket_name" {
  description = "Name of the existing S3 bucket for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.waf_enable_logging ||
      var.waf_logging_destination_type != "S3" ||
      (var.waf_existing_s3_bucket_name != null &&
      trimspace(var.waf_existing_s3_bucket_name) != "")
    )
    error_message = "Provide waf_existing_s3_bucket_name when logging is enabled with S3."
  }

  validation {
    condition = (
      var.waf_logging_destination_type == "S3" ||
      var.waf_existing_s3_bucket_name == null
    )
    error_message = "Set waf_existing_s3_bucket_name only when S3 is selected."
  }
}

variable "waf_existing_firehose_stream_name" {
  description = "Name of the existing Amazon Data Firehose delivery stream for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.waf_enable_logging ||
      var.waf_logging_destination_type != "FIREHOSE" ||
      (var.waf_existing_firehose_stream_name != null &&
      trimspace(var.waf_existing_firehose_stream_name) != "")
    )
    error_message = "Provide waf_existing_firehose_stream_name when logging is enabled with FIREHOSE."
  }

  validation {
    condition = (
      var.waf_logging_destination_type == "FIREHOSE" ||
      var.waf_existing_firehose_stream_name == null
    )
    error_message = "Set waf_existing_firehose_stream_name only when FIREHOSE is selected."
  }
}

