
# --------------------------------------------------
# Custom CloudFront Cache Policies
# --------------------------------------------------

resource "aws_cloudfront_cache_policy" "custom" {
  for_each = local.custom_cache_policy_selections

  name    = each.value.custom.name
  comment = try(each.value.custom.comment, null)

  min_ttl     = each.value.custom.min_ttl
  default_ttl = each.value.custom.default_ttl
  max_ttl     = each.value.custom.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
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

    # ----------------------------------------------
    # Compression
    # ----------------------------------------------

    enable_accept_encoding_gzip = try(
      each.value.custom.enable_accept_encoding_gzip,
      false
    )

    enable_accept_encoding_brotli = try(
      each.value.custom.enable_accept_encoding_brotli,
      false
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}
