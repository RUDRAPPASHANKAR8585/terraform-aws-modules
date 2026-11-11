
# --------------------------------------------------
# Custom CloudFront Response Headers Policies
# --------------------------------------------------

resource "aws_cloudfront_response_headers_policy" "custom" {
  for_each = local.custom_response_headers_policy_selections

  name    = each.value.custom.name
  comment = try(each.value.custom.comment, null)

  # --------------------------------------------------
  # CORS Configuration
  # --------------------------------------------------

  dynamic "cors_config" {
    for_each = try(
      each.value.custom.cors_config,
      null
    ) == null ? [] : [each.value.custom.cors_config]

    content {
      access_control_allow_credentials = cors_config.value.access_control_allow_credentials
      access_control_max_age_sec       = cors_config.value.access_control_max_age_sec
      origin_override                  = cors_config.value.origin_override

      access_control_allow_origins {
        items = cors_config.value.access_control_allow_origins
      }

      access_control_allow_methods {
        items = cors_config.value.access_control_allow_methods
      }

      access_control_allow_headers {
        items = cors_config.value.access_control_allow_headers
      }

      access_control_expose_headers {
        items = cors_config.value.access_control_expose_headers
      }
    }
  }

  # --------------------------------------------------
  # Security Headers
  # --------------------------------------------------

  dynamic "security_headers_config" {
    for_each = try(
      each.value.custom.security_headers_config,
      null
    ) == null ? [] : [each.value.custom.security_headers_config]

    content {
      dynamic "content_type_options" {
        for_each = try(security_headers_config.value.content_type_options, null) == null ? [] : [security_headers_config.value.content_type_options]

        content {
          override = content_type_options.value.override
        }
      }

      dynamic "frame_options" {
        for_each = try(security_headers_config.value.frame_options, null) == null ? [] : [security_headers_config.value.frame_options]

        content {
          frame_option = frame_options.value.frame_option
          override     = frame_options.value.override
        }
      }

      dynamic "referrer_policy" {
        for_each = try(security_headers_config.value.referrer_policy, null) == null ? [] : [security_headers_config.value.referrer_policy]

        content {
          referrer_policy = referrer_policy.value.referrer_policy
          override        = referrer_policy.value.override
        }
      }

      dynamic "strict_transport_security" {
        for_each = try(security_headers_config.value.strict_transport_security, null) == null ? [] : [security_headers_config.value.strict_transport_security]

        content {
          access_control_max_age_sec = strict_transport_security.value.access_control_max_age_sec
          include_subdomains         = strict_transport_security.value.include_subdomains
          preload                    = strict_transport_security.value.preload
          override                   = strict_transport_security.value.override
        }
      }

      dynamic "xss_protection" {
        for_each = try(security_headers_config.value.xss_protection, null) == null ? [] : [security_headers_config.value.xss_protection]

        content {
          protection = xss_protection.value.protection
          mode_block = xss_protection.value.mode_block
          report_uri = xss_protection.value.report_uri
          override   = xss_protection.value.override
        }
      }
    }
  }

  # --------------------------------------------------
  # Custom Headers
  # --------------------------------------------------

  dynamic "custom_headers_config" {
    for_each = try(
      each.value.custom.custom_headers_config,
      null
    ) == null ? [] : [each.value.custom.custom_headers_config]

    content {
      dynamic "items" {
        for_each = custom_headers_config.value.items

        content {
          header   = items.value.header
          value    = items.value.value
          override = items.value.override
        }
      }
    }
  }

  # --------------------------------------------------
  # Remove Headers
  # --------------------------------------------------

  dynamic "remove_headers_config" {
    for_each = try(
      each.value.custom.remove_headers_config,
      null
    ) == null ? [] : [each.value.custom.remove_headers_config]

    content {
      dynamic "items" {
        for_each = remove_headers_config.value.items

        content {
          header = items.value.header
        }
      }
    }
  }

  # --------------------------------------------------
  # Server Timing Headers
  # --------------------------------------------------

  dynamic "server_timing_headers_config" {
    for_each = try(
      each.value.custom.server_timing_headers_config,
      null
    ) == null ? [] : [each.value.custom.server_timing_headers_config]

    content {
      enabled       = server_timing_headers_config.value.enabled
      sampling_rate = server_timing_headers_config.value.sampling_rate
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
