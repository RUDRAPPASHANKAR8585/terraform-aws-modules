
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.69.0, < 7.0.0"
    }
  }
}

# Default AWS provider - S3 region
provider "aws" {
  region = var.s3_bucket_region
}

# S3 bucket provider
provider "aws" {
  alias  = "s3"
  region = var.s3_bucket_region
}

# CloudFront provider
provider "aws" {
  alias  = "cloudfront"
  region = var.cloudfront_region
}

# WAF provider
provider "aws" {
  alias  = "waf"
  region = var.waf_region
}

# Logging S3 provider
provider "aws" {
  alias  = "logging_s3"
  region = var.cloudfront_logging_s3_bucket_region
}