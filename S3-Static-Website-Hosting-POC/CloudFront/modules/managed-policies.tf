
# --------------------------------------------------
# AWS Managed Cache Policies
# --------------------------------------------------

data "aws_cloudfront_cache_policy" "managed" {
  for_each = local.managed_cache_policy_selections

  name = contains(
    [
      "UseOriginCacheControlHeaders",
      "UseOriginCacheControlHeaders-QueryStrings"
    ],
    each.value.managed_name
  ) ? each.value.managed_name : "Managed-${each.value.managed_name}"
}


# --------------------------------------------------
# AWS Managed Origin Request Policies
# --------------------------------------------------

data "aws_cloudfront_origin_request_policy" "managed" {
  for_each = local.managed_origin_request_policy_selections

  name = "Managed-${each.value.managed_name}"
}


# --------------------------------------------------
# AWS Managed Response Headers Policies
# --------------------------------------------------

data "aws_cloudfront_response_headers_policy" "managed" {
  for_each = local.managed_response_headers_policy_selections

  name = "Managed-${each.value.managed_name}"
}
