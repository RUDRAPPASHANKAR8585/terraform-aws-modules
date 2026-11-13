variable "aws_region" {
  description = "AWS region for the Terraform AWS provider."
  type        = string
  default     = "us-east-1"
}


variable "pricing" {
  description = <<-EOT
    CloudFront pricing configuration.

    PAY_AS_YOU_GO uses standard usage-based CloudFront pricing.
    FLAT_RATE creates an AWS Pricing Plan Manager subscription.
  EOT

  type = object({
    model = optional(string, "PAY_AS_YOU_GO")

    flat_rate = optional(object({
      plan_tier = string

      # MANUAL or IMMEDIATE.
      # null allows AWS to apply its default approval behavior.
      approval_mode = optional(string)

      # DEFAULT selects the base usage level for the chosen tier.
      usage_level = optional(string, "DEFAULT")
    }))
  })

  default = {
    model = "PAY_AS_YOU_GO"
  }

  # Validate pricing model.
  validation {
    condition = contains(
      ["PAY_AS_YOU_GO", "FLAT_RATE"],
      var.pricing.model
    )

    error_message = "pricing.model must be PAY_AS_YOU_GO or FLAT_RATE."
  }

  # PAYG must not contain flat_rate.
  # FLAT_RATE must contain flat_rate.
  validation {
    condition = (
      var.pricing.model == "PAY_AS_YOU_GO"
      ? var.pricing.flat_rate == null
      : var.pricing.flat_rate != null
    )

    error_message = "For PAY_AS_YOU_GO, omit flat_rate. For FLAT_RATE, provide flat_rate with a plan_tier."
  }

  # Validate supported plan tiers.
  validation {
    condition = (
      var.pricing.flat_rate == null
      ? true
      : contains(
        ["FREE", "PRO", "BUSINESS", "PREMIUM"],
        var.pricing.flat_rate.plan_tier
      )
    )

    error_message = "pricing.flat_rate.plan_tier must be FREE, PRO, BUSINESS or PREMIUM."
  }

  # Validate approval mode when specified.
  validation {
    condition = (
      var.pricing.flat_rate == null
      ? true
      : (
        var.pricing.flat_rate.approval_mode == null
        ? true
        : contains(
          ["MANUAL", "IMMEDIATE"],
          var.pricing.flat_rate.approval_mode
        )
      )
    )

    error_message = "pricing.flat_rate.approval_mode must be MANUAL or IMMEDIATE when specified."
  }

  # Validate usage level against the selected plan tier.
  validation {
    condition = (
      var.pricing.flat_rate == null
      ? true
      : (
        var.pricing.flat_rate.plan_tier == "PREMIUM"
        ? contains(
          [
            "DEFAULT",
            "CF_PREMIUM_L2",
            "CF_PREMIUM_L3",
            "CF_PREMIUM_L4",
            "CF_PREMIUM_L5",
            "CF_PREMIUM_L6"
          ],
          var.pricing.flat_rate.usage_level
        )
        : var.pricing.flat_rate.usage_level == "DEFAULT"
      )
    )

    error_message = "PREMIUM supports DEFAULT and CF_PREMIUM_L2 through CF_PREMIUM_L6. FREE, PRO and BUSINESS support DEFAULT only."
  }
}


variable "origin_settings" {
  description = "Per-origin CloudFront connection settings. Keys must match the keys defined in the origins variable."

  type = map(object({
    mode = optional(string, "RECOMMENDED")

    mutual_tls_enabled         = optional(bool, false)
    mutual_tls_certificate_arn = optional(string)

    custom_headers = optional(map(string), {})

    origin_shield = optional(object({
      enabled = optional(bool, false)
      region  = optional(string)
    }), {})

    connection_attempts         = optional(number, 3)
    connection_timeout          = optional(number, 10)
    response_timeout            = optional(number, 30)
    response_completion_timeout = optional(number)
  }))

  default = {}

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      contains(["RECOMMENDED", "CUSTOM"], settings.mode)
    ])
    error_message = "Origin settings mode must be RECOMMENDED or CUSTOM."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      settings.connection_attempts >= 1 &&
      settings.connection_attempts <= 3
    ])
    error_message = "Connection attempts must be between 1 and 3."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      settings.connection_timeout >= 1 &&
      settings.connection_timeout <= 10
    ])
    error_message = "Connection timeout must be between 1 and 10 seconds."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      settings.response_timeout >= 1 &&
      settings.response_timeout <= 120
    ])
    error_message = "Response timeout must be between 1 and 120 seconds."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      settings.response_completion_timeout == null ||
      settings.response_completion_timeout >= settings.response_timeout
    ])
    error_message = "Response completion timeout must be greater than or equal to response timeout."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      !settings.mutual_tls_enabled ||
      try(trimspace(settings.mutual_tls_certificate_arn) != "", false)
    ])
    error_message = "A client certificate ARN is required when mutual TLS is enabled."
  }

  validation {
    condition = alltrue([
      for settings in values(var.origin_settings) :
      !settings.origin_shield.enabled ||
      try(trimspace(settings.origin_shield.region) != "", false)
    ])
    error_message = "An AWS region is required when Origin Shield is enabled."
  }
}


# --------------------------------------------------
# Cache Behavior Policy Selection Objects
# --------------------------------------------------

variable "default_cache_behavior" {
  description = "Default CloudFront cache behavior and its independent policy selections."

  type = object({
    target_origin_key      = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods        = optional(list(string), ["GET", "HEAD"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    compress               = optional(bool, true)

    function_associations = optional(list(object({
      event_type   = string
      function_key = string
    })), [])

    cache_policy = optional(object({
      type         = optional(string, "NONE")
      managed_name = optional(string)
      policy_id    = optional(string)
      custom       = optional(any)
    }), { type = "NONE" })

    origin_request_policy = optional(object({
      type         = optional(string, "NONE")
      managed_name = optional(string)
      policy_id    = optional(string)
      custom       = optional(any)
    }), { type = "NONE" })

    response_headers_policy = optional(object({
      type         = optional(string, "NONE")
      managed_name = optional(string)
      policy_id    = optional(string)
      custom       = optional(any)
    }), { type = "NONE" })
  })


  validation {
    condition = alltrue([
      for policy_type in [
        var.default_cache_behavior.cache_policy.type,
        var.default_cache_behavior.origin_request_policy.type,
        var.default_cache_behavior.response_headers_policy.type
      ] : contains(["NONE", "MANAGED", "EXISTING", "CUSTOM"], policy_type)
    ])

    error_message = "Policy type must be NONE, MANAGED, EXISTING or CUSTOM."
  }

  validation {
    condition = alltrue([
      for policy in [
        var.default_cache_behavior.cache_policy,
        var.default_cache_behavior.origin_request_policy,
        var.default_cache_behavior.response_headers_policy
      ] :
      policy.type == "MANAGED" ? try(trimspace(policy.managed_name), "") != "" :
      policy.type == "EXISTING" ? try(trimspace(policy.policy_id), "") != "" :
      policy.type == "CUSTOM" ? try(trimspace(policy.custom.name), "") != "" :
      true
    ])

    error_message = "For MANAGED policies, managed_name is required. For EXISTING policies, policy_id is required. For CUSTOM policies, custom.name is required."
  }

  validation {
    condition = alltrue([
      for association in var.default_cache_behavior.function_associations :
      contains(
        ["viewer-request", "viewer-response"],
        association.event_type
      )
    ])

    error_message = "CloudFront Function event_type must be viewer-request or viewer-response."
  }

  validation {
    condition = alltrue([
      for association in var.default_cache_behavior.function_associations :
      contains(keys(var.cloudfront_functions), association.function_key)
    ])

    error_message = "Every default behavior function_key must reference a key defined in cloudfront_functions."
  }

  validation {
    condition = alltrue([
      for association in var.default_cache_behavior.function_associations :
      try(var.cloudfront_functions[association.function_key].publish, false)
    ])

    error_message = "Functions associated with the default behavior must have publish = true."
  }
  validation {
    condition = contains(
      keys(var.origins),
      var.default_cache_behavior.target_origin_key
    )

    error_message = "default_cache_behavior.target_origin_key must reference a key defined in the origins variable."
  }
}


variable "ordered_cache_behaviors" {
  description = "Ordered CloudFront cache behaviors with independent policy selections."

  type    = any
  default = {}

  # --------------------------------------------------
  # Validate Ordered Behaviors
  # --------------------------------------------------

  validation {
    condition = (
      can(keys(var.ordered_cache_behaviors)) &&
      alltrue([
        for behavior in values(var.ordered_cache_behaviors) :
        try(trimspace(behavior.path_pattern), "") != "" &&
        try(trimspace(behavior.target_origin_key), "") != ""
      ])
    )

    error_message = "Every ordered behavior must define a non-empty path_pattern and target_origin_key."
  }

  # --------------------------------------------------
  # Validate Policy Types
  # --------------------------------------------------

  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      alltrue([
        for policy_type in [
          try(behavior.cache_policy.type, "NONE"),
          try(behavior.origin_request_policy.type, "NONE"),
          try(behavior.response_headers_policy.type, "NONE")
        ] :
        contains(
          ["NONE", "MANAGED", "EXISTING", "CUSTOM"],
          policy_type
        )
      ])
    ])

    error_message = "Each ordered behavior policy type must be NONE, MANAGED, EXISTING or CUSTOM."
  }

  # --------------------------------------------------
  # Validate Policy Configuration
  # --------------------------------------------------

  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      alltrue([
        for policy in [
          try(behavior.cache_policy, { type = "NONE" }),
          try(behavior.origin_request_policy, { type = "NONE" }),
          try(behavior.response_headers_policy, { type = "NONE" })
        ] :
        try(policy.type, "NONE") == "MANAGED"
        ? try(trimspace(policy.managed_name), "") != ""

        : try(policy.type, "NONE") == "EXISTING"
        ? try(trimspace(policy.policy_id), "") != ""

        : try(policy.type, "NONE") == "CUSTOM"
        ? try(trimspace(policy.custom.name), "") != ""

        : true
      ])
    ])

    error_message = "Each ordered behavior must provide managed_name for MANAGED policies, policy_id for EXISTING policies, and custom.name for CUSTOM policies."
  }

  # --------------------------------------------------
  # Custom Cache Policy Name Uniqueness
  # --------------------------------------------------

  validation {
    condition = (
      length(compact(concat(
        try(
          var.default_cache_behavior.cache_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.cache_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.cache_policy.type == "CUSTOM"
            ? behavior.cache_policy.custom.name
            : "",
            ""
          )
        ]
      ))) ==
      length(distinct(compact(concat(
        try(
          var.default_cache_behavior.cache_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.cache_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.cache_policy.type == "CUSTOM"
            ? behavior.cache_policy.custom.name
            : "",
            ""
          )
        ]
      ))))
    )

    error_message = "Custom cache policy names must be unique across the default and ordered cache behaviors."
  }

  # --------------------------------------------------
  # Custom Origin Request Policy Name Uniqueness
  # --------------------------------------------------

  validation {
    condition = (
      length(compact(concat(
        try(
          var.default_cache_behavior.origin_request_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.origin_request_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.origin_request_policy.type == "CUSTOM"
            ? behavior.origin_request_policy.custom.name
            : "",
            ""
          )
        ]
      ))) ==
      length(distinct(compact(concat(
        try(
          var.default_cache_behavior.origin_request_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.origin_request_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.origin_request_policy.type == "CUSTOM"
            ? behavior.origin_request_policy.custom.name
            : "",
            ""
          )
        ]
      ))))
    )

    error_message = "Custom origin request policy names must be unique across the default and ordered cache behaviors."
  }

  # --------------------------------------------------
  # Validate Function Event Types
  # --------------------------------------------------

  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      alltrue([
        for association in try(behavior.function_associations, []) :
        contains(
          ["viewer-request", "viewer-response"],
          association.event_type
        )
      ])
    ])

    error_message = "Ordered behavior function event_type must be viewer-request or viewer-response."
  }

  # --------------------------------------------------
  # Validate Function References
  # --------------------------------------------------

  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      alltrue([
        for association in try(behavior.function_associations, []) :
        contains(
          keys(var.cloudfront_functions),
          association.function_key
        )
      ])
    ])

    error_message = "Every ordered behavior function_key must reference a key defined in cloudfront_functions."
  }

  # --------------------------------------------------
  # Validate Published Functions
  # --------------------------------------------------

  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      alltrue([
        for association in try(behavior.function_associations, []) :
        try(
          var.cloudfront_functions[association.function_key].publish,
          false
        )
      ])
    ])

    error_message = "Functions associated with ordered behaviors must have publish = true."
  }

  # --------------------------------------------------
  # Custom Response Headers Policy Name Uniqueness
  # --------------------------------------------------

  validation {
    condition = (
      length(compact(concat(
        try(
          var.default_cache_behavior.response_headers_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.response_headers_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.response_headers_policy.type == "CUSTOM"
            ? behavior.response_headers_policy.custom.name
            : "",
            ""
          )
        ]
      ))) ==
      length(distinct(compact(concat(
        try(
          var.default_cache_behavior.response_headers_policy.type == "CUSTOM"
          ? [var.default_cache_behavior.response_headers_policy.custom.name]
          : [],
          []
        ),
        [
          for behavior in values(var.ordered_cache_behaviors) :
          try(
            behavior.response_headers_policy.type == "CUSTOM"
            ? behavior.response_headers_policy.custom.name
            : "",
            ""
          )
        ]
      ))))
    )

    error_message = "Custom response headers policy names must be unique across the default and ordered cache behaviors."
  }
  validation {
    condition = alltrue([
      for behavior in values(var.ordered_cache_behaviors) :
      contains(
        keys(var.origins),
        try(behavior.target_origin_key, "")
      )
    ])

    error_message = "Every ordered behavior target_origin_key must reference a key defined in the origins variable."
  }
}



variable "origin_access_controls" {
  description = "Optional CloudFront Origin Access Controls."

  type = map(object({
    name             = string
    description      = optional(string)
    origin_type      = optional(string, "s3")
    signing_behavior = optional(string, "always")
  }))

  default = {}

  validation {
    condition = alltrue([
      for oac in values(var.origin_access_controls) :
      contains(["s3", "mediastore", "mediapackagev2", "lambda"], oac.origin_type)
    ])
    error_message = "OAC origin_type must be s3, mediastore, mediapackagev2 or lambda."
  }

  validation {
    condition = alltrue([
      for oac in values(var.origin_access_controls) :
      contains(["always", "never", "no-override"], oac.signing_behavior)
    ])
    error_message = "OAC signing_behavior must be always, never or no-override."
  }
}

variable "origins" {
  description = "CloudFront origins. Origin resources are externally managed."

  type = map(object({
    domain_name               = string
    origin_type               = string
    origin_path               = optional(string)
    origin_access_control_key = optional(string)

    http_port                = optional(number, 80)
    https_port               = optional(number, 443)
    origin_protocol_policy   = optional(string, "https-only")
    origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
    origin_keepalive_timeout = optional(number, 5)
  }))

  default = {}

  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      contains(["S3", "CUSTOM"], origin.origin_type)
    ])
    error_message = "Origin type must be S3 or CUSTOM. VPC origins will be added as a separate capability."
  }

  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      origin.origin_type != "CUSTOM" ||
      contains(["http-only", "https-only", "match-viewer"], origin.origin_protocol_policy)
    ])
    error_message = "Custom origin protocol policy must be http-only, https-only or match-viewer."
  }
  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      origin.origin_access_control_key == null ||
      contains(
        keys(var.origin_access_controls),
        origin.origin_access_control_key
      )
    ])

    error_message = "Every origin_access_control_key must reference a key defined in origin_access_controls."
  }

  validation {
    condition = alltrue([
      for origin in values(var.origins) :
      origin.origin_type != "S3" ||
      origin.origin_access_control_key == null ||
      var.origin_access_controls[origin.origin_access_control_key].origin_type == "s3"
    ])

    error_message = "S3 origins must reference an OAC configured with origin_type = s3."
  }
}

variable "distribution_enabled" {
  type    = bool
  default = true
}

variable "distribution_comment" {
  type    = string
  default = "Managed by Terraform"
}

variable "distribution_aliases" {
  type    = list(string)
  default = []

  validation {
    condition = (
      length(var.distribution_aliases) == 0 ||
      var.use_default_certificate == false
    )

    error_message = "Custom domain aliases require an ACM certificate. Set use_default_certificate to false."
  }
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "price_class" {
  type    = string
  default = "PriceClass_All"
}

variable "http_version" {
  type    = string
  default = "http2and3"
}

variable "is_ipv6_enabled" {
  type    = bool
  default = true
}


variable "geo_restriction_type" {
  type    = string
  default = "none"
}

variable "geo_restriction_locations" {
  type    = list(string)
  default = []
}

variable "use_default_certificate" {
  type    = bool
  default = true
}


variable "acm_certificate_arn" {
  description = "Existing ACM certificate ARN in us-east-1 for CloudFront."
  type        = string
  default     = null

  validation {
    condition = (
      var.use_default_certificate ||
      try(
        can(regex(
          "^arn:[^:]+:acm:us-east-1:[0-9]{12}:certificate/.+$",
          var.acm_certificate_arn
        )),
        false
      )
    )

    error_message = "When using a custom certificate, provide a valid ACM certificate ARN from us-east-1."
  }
}


variable "minimum_protocol_version" {
  type    = string
  default = "TLSv1.2_2021"
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "custom_error_responses" {
  description = "Custom error response configurations for CloudFront."

  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 10)
  }))

  default = []
}


# --------------------------------------------------
# CloudFront Functions
# --------------------------------------------------

variable "cloudfront_functions" {
  description = "CloudFront Functions to create."

  type = map(object({
    name    = string
    runtime = optional(string, "cloudfront-js-2.0")
    comment = optional(string, "")
    publish = optional(bool, true)
    code    = string
  }))

  default = {}

  validation {
    condition = alltrue([
      for function in values(var.cloudfront_functions) :
      trimspace(function.code) != ""
    ])
    error_message = "CloudFront Function code cannot be empty."
  }

  validation {
    condition = alltrue([
      for function in values(var.cloudfront_functions) :
      contains(
        ["cloudfront-js-1.0", "cloudfront-js-2.0"],
        function.runtime
      )
    ])
    error_message = "CloudFront Function runtime must be cloudfront-js-1.0 or cloudfront-js-2.0."
  }
  validation {
    condition = alltrue([
      for function in values(var.cloudfront_functions) :
      can(regex("^[A-Za-z0-9_-]{1,64}$", function.name))
    ])

    error_message = "CloudFront Function names must contain 1-64 characters and use only letters, numbers, underscores or hyphens."
  }

  validation {
    condition = (
      length(distinct([
        for function in values(var.cloudfront_functions) :
        function.name
      ])) == length(var.cloudfront_functions)
    )

    error_message = "CloudFront Function names must be unique."
  }
}

# --------------------------------------------------
# CloudFront Access Logging
# --------------------------------------------------

variable "cloudfront_logging" {
  description = "Optional CloudFront standard access logging configuration. Supports legacy and standard logging v2."

  type = object({

    # Standard logging - Legacy (S3 only)
    legacy = optional(object({
      bucket_domain_name = string
      prefix             = optional(string, "")
      include_cookies    = optional(bool, false)
    }))

    # Standard logging - V2 (S3, CloudWatch Logs or Firehose)
    v2 = optional(object({
      source_name              = string
      destination_name         = string
      destination_resource_arn = string
      output_format            = optional(string, "json")
      field_delimiter          = optional(string, "\t")

      record_fields = optional(list(string), [
        "date",
        "time",
        "x-edge-location",
        "sc-bytes",
        "c-ip",
        "cs-method",
        "cs(Host)",
        "cs-uri-stem",
        "sc-status",
        "cs(Referer)",
        "cs(User-Agent)",
        "cs-uri-query",
        "cs(Cookie)",
        "x-edge-result-type",
        "x-edge-request-id"
      ])

      s3_delivery_configuration = optional(object({
        suffix_path                 = optional(string)
        enable_hive_compatible_path = optional(bool, false)
      }))
    }))
  })

  default = {}

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ? true :
      contains(
        ["json", "plain", "w3c", "raw", "parquet"],
        var.cloudfront_logging.v2.output_format
      )
    )

    error_message = "CloudFront logging v2 output_format must be json, plain, w3c, raw or parquet."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ? true :
      length(var.cloudfront_logging.v2.record_fields) > 0
    )

    error_message = "CloudFront logging v2 must contain at least one record field."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ||
      can(regex(
        "^arn:[^:]+:s3:::[^/]+(/.*)?$",
        var.cloudfront_logging.v2.destination_resource_arn
      )) ||
      can(regex(
        "^arn:[^:]+:logs:[^:]+:[0-9]{12}:log-group:",
        var.cloudfront_logging.v2.destination_resource_arn
      )) ||
      can(regex(
        "^arn:[^:]+:firehose:[^:]+:[0-9]{12}:deliverystream/",
        var.cloudfront_logging.v2.destination_resource_arn
      ))
    )

    error_message = "CloudFront logging v2 destination_resource_arn must reference an S3 bucket, CloudWatch Logs log group, or Kinesis Data Firehose delivery stream ARN."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ||
      var.cloudfront_logging.v2.s3_delivery_configuration == null ||
      can(regex(
        "^arn:[^:]+:s3:::[^/]+(/.*)?$",
        var.cloudfront_logging.v2.destination_resource_arn
      ))
    )

    error_message = "s3_delivery_configuration can only be used when destination_resource_arn references an S3 bucket."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ||
      (
        trimspace(var.cloudfront_logging.v2.source_name) != "" &&
        trimspace(var.cloudfront_logging.v2.destination_name) != ""
      )
    )

    error_message = "CloudFront logging v2 source_name and destination_name must not be empty."
  }

  validation {
    condition = (
      var.cloudfront_logging.legacy == null ||
      trimspace(var.cloudfront_logging.legacy.bucket_domain_name) != ""
    )

    error_message = "Legacy CloudFront logging requires a valid S3 bucket domain name."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ||
      var.cloudfront_logging.v2.s3_delivery_configuration == null ||
      var.cloudfront_logging.v2.s3_delivery_configuration.suffix_path == null ||
      trimspace(var.cloudfront_logging.v2.s3_delivery_configuration.suffix_path) != ""
    )

    error_message = "S3 suffix_path must not be empty when provided."
  }

  validation {
    condition = (
      var.cloudfront_logging.v2 == null ||
      var.cloudfront_logging.v2.output_format != "parquet" ||
      can(regex(
        "^arn:[^:]+:s3:::[^/]+(/.*)?$",
        var.cloudfront_logging.v2.destination_resource_arn
      ))
    )

    error_message = "The parquet output format is supported only for S3 destinations."
  }
}

# --------------------------------------------------
# CloudFront WAF Association
# --------------------------------------------------

variable "waf_enabled" {
  description = "Whether to associate an existing AWS WAF Web ACL with CloudFront."
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of an existing AWS WAF Web ACL with CLOUDFRONT scope in us-east-1."
  type        = string
  default     = null

  validation {
    condition = (
      var.waf_enabled == false ||
      try(
        can(regex(
          "^arn:[^:]+:wafv2:us-east-1:[0-9]{12}:global/webacl/.+/.+$",
          var.waf_web_acl_arn
        )),
        false
      )
    )

    error_message = "When waf_enabled is true, provide an existing CloudFront-scope WAF Web ACL ARN from us-east-1."
  }
}
