
resource "aws_pricingplanmanager_subscription" "cloudfront" {
  count = var.pricing.model == "FLAT_RATE" ? 1 : 0

  plan_family = "CloudFront"
  plan_tier   = var.pricing.flat_rate.plan_tier

  resource_arns = [
    aws_cloudfront_distribution.this.arn,
    var.waf_web_acl_arn
  ]

  approval_mode = var.pricing.flat_rate.approval_mode
  usage_level   = var.pricing.flat_rate.usage_level

  lifecycle {
    precondition {
      condition = (
        var.waf_enabled &&
        var.waf_web_acl_arn != null &&
        trimspace(var.waf_web_acl_arn) != ""
      )

      error_message = "FLAT_RATE pricing requires an existing WAF Web ACL ARN and waf_enabled = true. The CloudFront flat-rate subscription must include one distribution and one WAF Web ACL."
    }
  }
}
