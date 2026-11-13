# --------------------------------------------------
# CloudFront Distribution Status
# --------------------------------------------------

output "cloudfront_distribution_status" {
  description = "Current CloudFront distribution status."
  value       = aws_cloudfront_distribution.this.status
}

output "cloudfront_distribution_enabled" {
  description = "Whether the CloudFront distribution is enabled."
  value       = aws_cloudfront_distribution.this.enabled
}

# --------------------------------------------------
# WAF Association
# --------------------------------------------------

output "cloudfront_waf_web_acl_arn" {
  description = "WAF Web ACL ARN associated with the CloudFront distribution. Null when disabled."
  value       = aws_cloudfront_distribution.this.web_acl_id
}

# --------------------------------------------------
# CloudFront Functions
# --------------------------------------------------

output "cloudfront_function_arns" {
  description = "Map of created CloudFront Function ARNs."
  value = {
    for key, function in aws_cloudfront_function.this :
    key => function.arn
  }
}

# --------------------------------------------------
# Custom CloudFront Policies
# --------------------------------------------------

output "custom_cache_policy_ids" {
  description = "Map of created custom CloudFront cache policy IDs."
  value = {
    for key, policy in aws_cloudfront_cache_policy.custom :
    key => policy.id
  }
}

output "custom_origin_request_policy_ids" {
  description = "Map of created custom CloudFront origin request policy IDs."
  value = {
    for key, policy in aws_cloudfront_origin_request_policy.custom :
    key => policy.id
  }
}

output "custom_response_headers_policy_ids" {
  description = "Map of created custom CloudFront response headers policy IDs."
  value = {
    for key, policy in aws_cloudfront_response_headers_policy.custom :
    key => policy.id
  }
}

# --------------------------------------------------
# CloudFront Standard Logging V2
# --------------------------------------------------

output "cloudfront_logging_v2_delivery_arn" {
  description = "ARN of the CloudFront standard logging v2 delivery configuration."
  value       = try(aws_cloudwatch_log_delivery.cloudfront[0].arn, null)
}

output "cloudfront_logging_v2_destination_arn" {
  description = "ARN of the CloudFront standard logging v2 destination."
  value       = try(aws_cloudwatch_log_delivery_destination.cloudfront[0].arn, null)
}

output "cloudfront_logging_v2_source_arn" {
  description = "ARN of the CloudFront standard logging v2 delivery source."
  value       = try(aws_cloudwatch_log_delivery_source.cloudfront[0].arn, null)
}

# --------------------------------------------------
# CloudFront Pricing
# --------------------------------------------------

output "cloudfront_pricing_model" {
  description = "Selected CloudFront pricing model."
  value       = var.pricing.model
}

output "cloudfront_pricing_plan_tier" {
  description = "Selected CloudFront flat-rate plan tier. Null when PAY_AS_YOU_GO is selected."
  value       = try(var.pricing.flat_rate.plan_tier, null)
}

output "cloudfront_pricing_usage_level" {
  description = "Selected CloudFront flat-rate usage level. Null when PAY_AS_YOU_GO is selected."
  value       = try(var.pricing.flat_rate.usage_level, null)
}

output "cloudfront_pricing_subscription_arn" {
  description = "ARN of the CloudFront Pricing Plan Manager subscription. Null when PAY_AS_YOU_GO is selected."
  value       = try(aws_pricingplanmanager_subscription.cloudfront[0].arn, null)
}

output "cloudfront_pricing_subscription_status" {
  description = "Current status of the CloudFront Pricing Plan Manager subscription."
  value       = try(aws_pricingplanmanager_subscription.cloudfront[0].status, null)
}

output "cloudfront_pricing_subscription_status_reason" {
  description = "Reason associated with the CloudFront Pricing Plan Manager subscription status."
  value       = try(aws_pricingplanmanager_subscription.cloudfront[0].status_reason, null)
}

# --------------------------------------------------
# CloudFront Distribution Details
# --------------------------------------------------

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name assigned to the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}