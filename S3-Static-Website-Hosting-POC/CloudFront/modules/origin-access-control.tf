resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_access_controls

  name                              = each.value.name
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = "sigv4"
}