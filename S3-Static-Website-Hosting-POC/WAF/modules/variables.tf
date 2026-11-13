variable "aws_region" {
  description = "AWS region used by the root AWS provider configuration. CloudFront is a global service, but the provider requires a region."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the AWS WAF Web ACL."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name)) && length(var.name) <= 128
    error_message = "WAF name must contain only letters, numbers, and hyphens, with a maximum length of 128 characters."
  }
}

variable "description" {
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


variable "enable_logging" {
  description = "Whether to enable AWS WAF logging."
  type        = bool
  default     = false
}

variable "logging_destination_type" {
  description = "Existing logging destination type: CLOUDWATCH_LOGS, S3, or FIREHOSE."
  type        = string
  default     = "CLOUDWATCH_LOGS"

  validation {
    condition = contains(
      ["CLOUDWATCH_LOGS", "S3", "FIREHOSE"],
      var.logging_destination_type
    )
    error_message = "logging_destination_type must be CLOUDWATCH_LOGS, S3, or FIREHOSE."
  }
}

variable "existing_cloudwatch_log_group_name" {
  description = "Name of the existing CloudWatch Logs log group for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.enable_logging ||
      var.logging_destination_type != "CLOUDWATCH_LOGS" ||
      (var.existing_cloudwatch_log_group_name != null &&
      trimspace(var.existing_cloudwatch_log_group_name) != "")
    )
    error_message = "Provide existing_cloudwatch_log_group_name when logging is enabled with CLOUDWATCH_LOGS."
  }

  validation {
    condition = (
      var.logging_destination_type == "CLOUDWATCH_LOGS" ||
      var.existing_cloudwatch_log_group_name == null
    )
    error_message = "Set existing_cloudwatch_log_group_name only when CLOUDWATCH_LOGS is selected."
  }
}

variable "existing_s3_bucket_name" {
  description = "Name of the existing S3 bucket for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.enable_logging ||
      var.logging_destination_type != "S3" ||
      (var.existing_s3_bucket_name != null &&
      trimspace(var.existing_s3_bucket_name) != "")
    )
    error_message = "Provide existing_s3_bucket_name when logging is enabled with S3."
  }

  validation {
    condition = (
      var.logging_destination_type == "S3" ||
      var.existing_s3_bucket_name == null
    )
    error_message = "Set existing_s3_bucket_name only when S3 is selected."
  }
}

variable "existing_firehose_stream_name" {
  description = "Name of the existing Amazon Data Firehose delivery stream for WAF logging."
  type        = string
  default     = null

  validation {
    condition = (
      !var.enable_logging ||
      var.logging_destination_type != "FIREHOSE" ||
      (var.existing_firehose_stream_name != null &&
      trimspace(var.existing_firehose_stream_name) != "")
    )
    error_message = "Provide existing_firehose_stream_name when logging is enabled with FIREHOSE."
  }

  validation {
    condition = (
      var.logging_destination_type == "FIREHOSE" ||
      var.existing_firehose_stream_name == null
    )
    error_message = "Set existing_firehose_stream_name only when FIREHOSE is selected."
  }
}
