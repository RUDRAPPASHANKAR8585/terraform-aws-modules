
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.distribution_enabled
  comment             = var.distribution_comment
  default_root_object = var.default_root_object
  aliases             = var.distribution_aliases
  price_class         = var.price_class
  http_version        = var.http_version
  is_ipv6_enabled     = var.is_ipv6_enabled
  web_acl_id          = var.waf_enabled ? var.waf_web_acl_arn : null

  # --------------------------------------------------
  # Standard Logging - Legacy
  # --------------------------------------------------

  dynamic "logging_config" {
    for_each = (
      var.cloudfront_logging.legacy == null
      ? []
      : [var.cloudfront_logging.legacy]
    )

    content {
      bucket          = logging_config.value.bucket_domain_name
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  # --------------------------------------------------
  # Custom Error Responses
  # --------------------------------------------------

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses

    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # --------------------------------------------------
  # Origins
  # --------------------------------------------------

  dynamic "origin" {
    for_each = var.origins

    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.key
      origin_path = origin.value.origin_path

      origin_access_control_id = (
        origin.value.origin_access_control_key == null
        ? null
        : aws_cloudfront_origin_access_control.this[
          origin.value.origin_access_control_key
        ].id
      )

      # S3 Origin
      dynamic "s3_origin_config" {
        for_each = origin.value.origin_type == "S3" ? [1] : []

        content {
          origin_access_identity = ""
        }
      }

      # Custom HTTP Origin
      dynamic "custom_origin_config" {
        for_each = origin.value.origin_type == "CUSTOM" ? [1] : []

        content {
          http_port                = origin.value.http_port
          https_port               = origin.value.https_port
          origin_protocol_policy   = origin.value.origin_protocol_policy
          origin_ssl_protocols     = origin.value.origin_ssl_protocols
          origin_keepalive_timeout = origin.value.origin_keepalive_timeout

          origin_read_timeout = local.normalized_origin_settings[
            origin.key
          ].response_timeout
        }
      }

      connection_attempts = local.normalized_origin_settings[
        origin.key
      ].connection_attempts

      connection_timeout = local.normalized_origin_settings[
        origin.key
      ].connection_timeout

      response_completion_timeout = local.normalized_origin_settings[
        origin.key
      ].response_completion_timeout

      # Custom Headers
      dynamic "custom_header" {
        for_each = local.normalized_origin_settings[
          origin.key
        ].custom_headers

        content {
          name  = custom_header.key
          value = custom_header.value
        }
      }

      # Origin Shield
      dynamic "origin_shield" {
        for_each = (
          local.normalized_origin_settings[origin.key].origin_shield_enabled
          ? [1]
          : []
        )

        content {
          enabled = true

          origin_shield_region = local.normalized_origin_settings[
            origin.key
          ].origin_shield_region
        }
      }
    }
  }

  # --------------------------------------------------
  # Default Cache Behavior
  # --------------------------------------------------

  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_key
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    compress               = var.default_cache_behavior.compress

    cache_policy_id = local.resolved_cache_policy_ids["default"]

    origin_request_policy_id = (
      local.resolved_origin_request_policy_ids["default"]
    )

    response_headers_policy_id = (
      local.resolved_response_headers_policy_ids["default"]
    )

    # Default Behavior Function Associations
    dynamic "function_association" {
      for_each = try(
        var.default_cache_behavior.function_associations,
        []
      )

      content {
        event_type = function_association.value.event_type

        function_arn = aws_cloudfront_function.this[
          function_association.value.function_key
        ].arn
      }
    }
  }

  # --------------------------------------------------
  # Ordered Cache Behaviors
  # --------------------------------------------------

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors

    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_key
      viewer_protocol_policy = try(ordered_cache_behavior.value.viewer_protocol_policy, "redirect-to-https")
      allowed_methods        = try(ordered_cache_behavior.value.allowed_methods, ["GET", "HEAD"])
      cached_methods         = try(ordered_cache_behavior.value.cached_methods, ["GET", "HEAD"])
      compress               = try(ordered_cache_behavior.value.compress, true)

      cache_policy_id = local.resolved_cache_policy_ids[
        "ordered-${ordered_cache_behavior.key}"
      ]

      origin_request_policy_id = local.resolved_origin_request_policy_ids[
        "ordered-${ordered_cache_behavior.key}"
      ]

      response_headers_policy_id = local.resolved_response_headers_policy_ids[
        "ordered-${ordered_cache_behavior.key}"
      ]

      # Ordered Behavior Function Associations
      dynamic "function_association" {
        for_each = try(
          ordered_cache_behavior.value.function_associations,
          []
        )

        content {
          event_type = function_association.value.event_type

          function_arn = aws_cloudfront_function.this[
            function_association.value.function_key
          ].arn
        }
      }
    }
  }

  # --------------------------------------------------
  # Restrictions
  # --------------------------------------------------

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # --------------------------------------------------
  # Viewer Certificate
  # --------------------------------------------------

  viewer_certificate {
    cloudfront_default_certificate = local.viewer_certificate_config.cloudfront_default_certificate

    acm_certificate_arn      = local.viewer_certificate_config.acm_certificate_arn
    ssl_support_method       = local.viewer_certificate_config.ssl_support_method
    minimum_protocol_version = local.viewer_certificate_config.minimum_protocol_version
  }

  # --------------------------------------------------
  # Tags
  # --------------------------------------------------

  tags = var.tags
}
