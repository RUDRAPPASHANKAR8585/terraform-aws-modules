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
  description = "ARNs of the IP sets used by the Web ACL."
  value       = module.waf.ip_set_arns
}