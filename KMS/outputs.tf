
# -----------------------------------------------------------------------------
# KMS key identifiers
# -----------------------------------------------------------------------------

output "key_id" {
  description = "Unique identifier of the created KMS key."
  value       = module.kms.key_id
}

output "key_arn" {
  description = "ARN of the created KMS key."
  value       = module.kms.key_arn
}

output "key_description" {
  description = "Description associated with the KMS key."
  value       = module.kms.key_description
}

# -----------------------------------------------------------------------------
# Key configuration and state
# -----------------------------------------------------------------------------

output "key_spec" {
  description = "Cryptographic specification of the KMS key."
  value       = module.kms.key_spec
}

output "key_usage" {
  description = "Cryptographic operations supported by the KMS key."
  value       = module.kms.key_usage
}

output "multi_region" {
  description = "Whether the KMS key is a multi-Region key."
  value       = module.kms.multi_region
}

output "configured_key_rotation" {
  description = "Whether automatic key rotation was requested in the configuration."
  value       = module.kms.configured_key_rotation
}

# -----------------------------------------------------------------------------
# KMS alias
# -----------------------------------------------------------------------------

output "alias_name" {
  description = "Alias assigned to the KMS key, or null when alias creation is disabled."
  value       = module.kms.alias_name
}

output "alias_arn" {
  description = "ARN of the KMS alias, or null when alias creation is disabled."
  value       = module.kms.alias_arn
}

output "alias_target_key_id" {
  description = "Key ID targeted by the alias, or null when alias creation is disabled."
  value       = module.kms.alias_target_key_id
}

# -----------------------------------------------------------------------------
# Deployment context
# -----------------------------------------------------------------------------

output "account_id" {
  description = "AWS account ID from the active provider credentials."
  value       = module.kms.account_id
}

output "aws_region" {
  description = "AWS Region in which the KMS key is managed."
  value       = module.kms.aws_region
}
