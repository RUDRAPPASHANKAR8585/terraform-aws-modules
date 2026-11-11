
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.69.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "s3"
  region = var.s3_bucket_region
}

provider "aws" {
  alias  = "logging_s3"
  region = var.logging_s3_bucket_region
}