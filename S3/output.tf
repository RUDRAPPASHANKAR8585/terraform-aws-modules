
output "bucket_name" {
  description = "The name of the S3 bucket."
  value       = module.s3.bucket_name
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the S3 bucket."
  value       = module.s3.bucket_arn
}

output "bucket_region" {
  description = "The AWS region where the S3 bucket is created."
  value       = module.s3.bucket_region
}

output "bucket_domain_name" {
  description = "The bucket's global domain name."
  value       = module.s3.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket's regional domain name."
  value       = module.s3.bucket_regional_domain_name
}

output "hosted_zone_id" {
  description = "The Route 53 hosted zone ID associated with the S3 bucket's regional endpoint."
  value       = module.s3.hosted_zone_id
}

output "bucket_tags" {
  description = "A map of tags associated with the S3 bucket."
  value       = module.s3.bucket_tags
}
