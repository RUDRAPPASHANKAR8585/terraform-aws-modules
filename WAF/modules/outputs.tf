output "web_acl_id" {
  description = "ID of the AWS WAF Web ACL."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "ARN of the AWS WAF Web ACL. Pass this to CloudFront."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "Name of the AWS WAF Web ACL."
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "Web ACL capacity in WCUs."
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_set_arns" {
  description = "ARNs of the IP sets created or referenced by this module."
  value = {
    for key, rule in local.ip_set_rules :
    key => rule.arn
  }
}

output "application_configuration" {
  description = "Application category and traffic focus selected by the requester."
  value       = local.application_configuration
}