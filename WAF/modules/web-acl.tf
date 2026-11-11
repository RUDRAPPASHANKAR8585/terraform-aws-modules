
resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = var.description
  scope       = var.scope

  # Default action
  default_action {
    dynamic "allow" {
      for_each = var.default_action == "ALLOW" ? [1] : []

      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "BLOCK" ? [1] : []

      content {}
    }
  }

  # IP allowlist and blocklist rules
  dynamic "rule" {
    for_each = local.ip_set_rules
    iterator = ip_rule

    content {
      name     = ip_rule.value.name
      priority = ip_rule.value.priority

      action {
        dynamic "allow" {
          for_each = ip_rule.value.action == "ALLOW" ? [1] : []

          content {}
        }

        dynamic "block" {
          for_each = ip_rule.value.action == "BLOCK" ? [1] : []

          content {}
        }
      }

      statement {
        ip_set_reference_statement {
          arn = ip_rule.value.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = ip_rule.value.name
      }
    }
  }

  # Country allowlist and blocklist rules
  dynamic "rule" {
    for_each = local.active_country_rules
    iterator = country_rule

    content {
      name     = country_rule.value.name
      priority = country_rule.value.priority

      action {
        dynamic "allow" {
          for_each = country_rule.value.action == "ALLOW" ? [1] : []

          content {}
        }

        dynamic "block" {
          for_each = country_rule.value.action == "BLOCK" ? [1] : []

          content {}
        }
      }

      statement {
        geo_match_statement {
          country_codes = country_rule.value.country_codes
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = country_rule.value.name
      }
    }
  }

  # Rate-based protection rules
  dynamic "rule" {
    for_each = local.active_rate_based_rules
    iterator = rate_rule

    content {
      name     = rate_rule.value.name
      priority = rate_rule.value.priority

      action {
        count {}
      }

      statement {
        rate_based_statement {
          limit                 = rate_rule.value.limit
          aggregate_key_type    = "IP"
          evaluation_window_sec = var.rate_limit_evaluation_window

          dynamic "scope_down_statement" {
            for_each = length(rate_rule.value.methods) > 0 ? [1] : []

            content {
              # Single HTTP method: use byte_match_statement directly.
              dynamic "byte_match_statement" {
                for_each = length(rate_rule.value.methods) == 1 ? rate_rule.value.methods : []
                iterator = method

                content {
                  field_to_match {
                    method {}
                  }

                  positional_constraint = "EXACTLY"
                  search_string         = method.value

                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }

              # Multiple HTTP methods: use OR statement.
              dynamic "or_statement" {
                for_each = length(rate_rule.value.methods) > 1 ? [1] : []

                content {
                  dynamic "statement" {
                    for_each = rate_rule.value.methods
                    iterator = method

                    content {
                      byte_match_statement {
                        field_to_match {
                          method {}
                        }

                        positional_constraint = "EXACTLY"
                        search_string         = method.value

                        text_transformation {
                          priority = 0
                          type     = "NONE"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = rate_rule.value.name
      }
    }
  }

  # Web ACL monitoring
  visibility_config {
    cloudwatch_metrics_enabled = local.visibility_config.cloudwatch_metrics_enabled
    sampled_requests_enabled   = local.visibility_config.sampled_requests_enabled
    metric_name                = local.visibility_config.metric_name
  }

  # Resource tags
  tags = {
    Name      = var.name
    ManagedBy = "Terraform"
  }

  # Validate that all active WAF rule priorities are unique
  lifecycle {
    precondition {
      condition = (
        length(local.active_rule_priorities) ==
        length(distinct(local.active_rule_priorities))
      )

      error_message = "Active WAF rule priorities must be unique across IP-based, country-based, and rate-based rules. Please assign a different priority to each rule."
    }
  }
}
