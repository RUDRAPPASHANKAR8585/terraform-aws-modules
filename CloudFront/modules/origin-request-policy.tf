
# --------------------------------------------------
# Custom CloudFront Origin Request Policies
# --------------------------------------------------

resource "aws_cloudfront_origin_request_policy" "custom" {
  for_each = local.custom_origin_request_policy_selections

  name    = each.value.custom.name
  comment = try(each.value.custom.comment, null)

  # ----------------------------------------------
  # Cookies
  # ----------------------------------------------

  cookies_config {
    cookie_behavior = each.value.custom.cookies_config.cookie_behavior

    dynamic "cookies" {
      for_each = (
        try(length(each.value.custom.cookies_config.items), 0) > 0
        ? [each.value.custom.cookies_config.items]
        : []
      )

      content {
        items = cookies.value
      }
    }
  }

  # ----------------------------------------------
  # Headers
  # ----------------------------------------------

  headers_config {
    header_behavior = each.value.custom.headers_config.header_behavior

    dynamic "headers" {
      for_each = (
        try(length(each.value.custom.headers_config.items), 0) > 0
        ? [each.value.custom.headers_config.items]
        : []
      )

      content {
        items = headers.value
      }
    }
  }

  # ----------------------------------------------
  # Query Strings
  # ----------------------------------------------

  query_strings_config {
    query_string_behavior = each.value.custom.query_strings_config.query_string_behavior

    dynamic "query_strings" {
      for_each = (
        try(length(each.value.custom.query_strings_config.items), 0) > 0
        ? [each.value.custom.query_strings_config.items]
        : []
      )

      content {
        items = query_strings.value
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
