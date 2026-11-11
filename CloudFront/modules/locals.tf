
locals {

  # --------------------------------------------------
  # Normalize Origin Settings
  # --------------------------------------------------

  normalized_origin_settings = {
    for origin_key, origin in var.origins :
    origin_key => {
      mode = try(
        var.origin_settings[origin_key].mode,
        "RECOMMENDED"
      )

      mutual_tls_enabled = try(
        var.origin_settings[origin_key].mutual_tls_enabled,
        false
      )

      mutual_tls_certificate_arn = try(
        var.origin_settings[origin_key].mutual_tls_certificate_arn,
        null
      )

      custom_headers = try(
        var.origin_settings[origin_key].custom_headers,
        {}
      )

      origin_shield_enabled = try(
        var.origin_settings[origin_key].origin_shield.enabled,
        false
      )

      origin_shield_region = try(
        var.origin_settings[origin_key].origin_shield.region,
        null
      )

      connection_attempts = try(
        var.origin_settings[origin_key].connection_attempts,
        3
      )

      connection_timeout = try(
        var.origin_settings[origin_key].connection_timeout,
        10
      )

      response_timeout = try(
        var.origin_settings[origin_key].response_timeout,
        30
      )

      response_completion_timeout = try(
        var.origin_settings[origin_key].response_completion_timeout,
        null
      )
    }
  }

  # --------------------------------------------------
  # Normalize Default and Ordered Behavior Policies
  # --------------------------------------------------

  behavior_policy_selections = merge(
    {
      default = {
        cache_policy = try(
          var.default_cache_behavior.cache_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )

        origin_request_policy = try(
          var.default_cache_behavior.origin_request_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )

        response_headers_policy = try(
          var.default_cache_behavior.response_headers_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )
      }
    },
    {
      for behavior_key, behavior in var.ordered_cache_behaviors :
      "ordered-${behavior_key}" => {
        cache_policy = try(
          behavior.cache_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )

        origin_request_policy = try(
          behavior.origin_request_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )

        response_headers_policy = try(
          behavior.response_headers_policy,
          { type = "NONE", managed_name = null, policy_id = null, custom = null }
        )
      }
    }
  )

  # --------------------------------------------------
  # Managed Cache Policy Selections
  # --------------------------------------------------

  managed_cache_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.cache_policy
    if policies.cache_policy.type == "MANAGED"
  }

  # --------------------------------------------------
  # Managed Origin Request Policy Selections
  # --------------------------------------------------

  managed_origin_request_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.origin_request_policy
    if policies.origin_request_policy.type == "MANAGED"
  }

  # --------------------------------------------------
  # Managed Response Headers Policy Selections
  # --------------------------------------------------

  managed_response_headers_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.response_headers_policy
    if policies.response_headers_policy.type == "MANAGED"
  }

  # --------------------------------------------------
  # Custom Cache Policy Selections
  # --------------------------------------------------

  custom_cache_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.cache_policy
    if policies.cache_policy.type == "CUSTOM"
  }

  # --------------------------------------------------
  # Custom Origin Request Policy Selections
  # --------------------------------------------------

  custom_origin_request_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.origin_request_policy
    if policies.origin_request_policy.type == "CUSTOM"
  }

  # --------------------------------------------------
  # Custom Response Headers Policy Selections
  # --------------------------------------------------

  custom_response_headers_policy_selections = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => policies.response_headers_policy
    if policies.response_headers_policy.type == "CUSTOM"
  }

  # --------------------------------------------------
  # Resolve Cache Policy IDs
  # --------------------------------------------------

  resolved_cache_policy_ids = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => (
      policies.cache_policy.type == "NONE"
      ? "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

      : policies.cache_policy.type == "EXISTING"
      ? policies.cache_policy.policy_id

      : policies.cache_policy.type == "MANAGED"
      ? data.aws_cloudfront_cache_policy.managed[behavior_key].id

      : policies.cache_policy.type == "CUSTOM"
      ? aws_cloudfront_cache_policy.custom[behavior_key].id

      : null
    )
  }

  # --------------------------------------------------
  # Resolve Origin Request Policy IDs
  # --------------------------------------------------

  resolved_origin_request_policy_ids = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => (
      policies.origin_request_policy.type == "NONE"
      ? null

      : policies.origin_request_policy.type == "EXISTING"
      ? policies.origin_request_policy.policy_id

      : policies.origin_request_policy.type == "MANAGED"
      ? data.aws_cloudfront_origin_request_policy.managed[behavior_key].id

      : policies.origin_request_policy.type == "CUSTOM"
      ? aws_cloudfront_origin_request_policy.custom[behavior_key].id

      : null
    )
  }

  # --------------------------------------------------
  # Resolve Response Headers Policy IDs
  # --------------------------------------------------

  resolved_response_headers_policy_ids = {
    for behavior_key, policies in local.behavior_policy_selections :
    behavior_key => (
      policies.response_headers_policy.type == "NONE"
      ? null

      : policies.response_headers_policy.type == "EXISTING"
      ? policies.response_headers_policy.policy_id

      : policies.response_headers_policy.type == "MANAGED"
      ? data.aws_cloudfront_response_headers_policy.managed[behavior_key].id

      : policies.response_headers_policy.type == "CUSTOM"
      ? aws_cloudfront_response_headers_policy.custom[behavior_key].id

      : null
    )
  }
}
