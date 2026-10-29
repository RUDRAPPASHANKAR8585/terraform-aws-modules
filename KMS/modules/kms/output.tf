
output "key_id" {
  description = "The KMS key ID."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "The KMS key ARN."
  value       = aws_kms_key.this.arn
}

output "key_description" {
  description = "The KMS key description."
  value       = aws_kms_key.this.description
}

output "key_spec" {
  description = "The KMS key specification."
  value       = aws_kms_key.this.customer_master_key_spec
}

output "key_usage" {
  description = "The intended cryptographic usage of the KMS key."
  value       = aws_kms_key.this.key_usage
}

output "multi_region" {
  description = "Whether the KMS key is a multi-Region key."
  value       = aws_kms_key.this.multi_region
}

output "configured_key_rotation" {
  description = "Whether automatic key rotation was requested in this configuration."
  value       = var.enable_key_rotation
}

output "alias_name" {
  description = "The alias name, or null when alias creation is disabled."
  value       = var.enable_alias ? aws_kms_alias.this[0].name : null
}

output "alias_arn" {
  description = "The alias ARN, or null when alias creation is disabled."
  value       = var.enable_alias ? aws_kms_alias.this[0].arn : null
}

output "alias_target_key_id" {
  description = "The KMS key ID targeted by the alias, or null when alias creation is disabled."
  value       = var.enable_alias ? aws_kms_alias.this[0].target_key_id : null
}

output "account_id" {
  description = "The AWS account ID from the active provider credentials."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "The AWS Region configured for the provider."
  value       = data.aws_region.current.name
}
