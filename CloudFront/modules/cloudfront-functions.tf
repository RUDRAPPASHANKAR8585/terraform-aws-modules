
# --------------------------------------------------
# CloudFront Functions
# --------------------------------------------------

resource "aws_cloudfront_function" "this" {
  for_each = var.cloudfront_functions

  name    = each.value.name
  runtime = each.value.runtime
  comment = each.value.comment
  publish = each.value.publish
  code    = each.value.code
}
