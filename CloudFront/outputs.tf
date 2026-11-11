
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID."
  value       = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_status" {
  value = module.cloudfront.cloudfront_distribution_status
}

output "cloudfront_waf_web_acl_arn" {
  value = module.cloudfront.cloudfront_waf_web_acl_arn
}

output "cloudfront_pricing_model" {
  value = module.cloudfront.cloudfront_pricing_model
}
