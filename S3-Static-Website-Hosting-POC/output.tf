
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
  description = "Current deployment status of the CloudFront distribution."
  value       = module.cloudfront.cloudfront_distribution_status
}

output "cloudfront_waf_web_acl_arn" {
  value = module.cloudfront.cloudfront_waf_web_acl_arn
}

output "cloudfront_pricing_model" {
  value = module.cloudfront.cloudfront_pricing_model
}



output "bucket_name" {

  value = module.s3.bucket_name

}


output "bucket_id" {

  value = module.s3.bucket_id

}


output "bucket_arn" {

  value = module.s3.bucket_arn

}


output "bucket_region" {

  value = module.s3.bucket_region

}


output "bucket_domain_name" {

  value = module.s3.bucket_domain_name

}


output "bucket_regional_domain_name" {

  value = module.s3.bucket_regional_domain_name

}


output "hosted_zone_id" {

  value = module.s3.hosted_zone_id

}


output "bucket_tags" {
  description = "Tags associated with the S3 bucket."
  value       = module.s3.bucket_tags
}



# Web ACL details
output "web_acl_id" {
  description = "ID of the created AWS WAF Web ACL."
  value       = module.waf.web_acl_id
}

output "web_acl_arn" {
  description = "ARN of the created AWS WAF Web ACL."
  value       = module.waf.web_acl_arn
}

output "web_acl_name" {
  description = "Name of the created AWS WAF Web ACL."
  value       = module.waf.web_acl_name
}

output "web_acl_capacity" {
  description = "WCU capacity consumed by the Web ACL."
  value       = module.waf.web_acl_capacity
}

# Application configuration
output "application_configuration" {
  description = "Application categories and focus configured for the Web ACL."
  value       = module.waf.application_configuration
}

# IP set details
output "ip_set_arns" {
  description = "ARNs of IP sets associated with the WAF Web ACL."
  value       = module.waf.ip_set_arns
}