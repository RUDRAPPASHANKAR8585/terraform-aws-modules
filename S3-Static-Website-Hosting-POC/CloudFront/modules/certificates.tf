
# --------------------------------------------------
# CloudFront Viewer Certificate Configuration
# --------------------------------------------------


locals {
  viewer_certificate_config = var.use_default_certificate ? {
    cloudfront_default_certificate = true
    acm_certificate_arn            = null
    ssl_support_method             = null
    minimum_protocol_version       = var.minimum_protocol_version
    } : {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
  }
}

