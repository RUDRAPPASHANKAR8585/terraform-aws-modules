
# -----------------------------------------------------------------------------
# KMS key configuration - local testing
# -----------------------------------------------------------------------------

key_name    = "kms-module-poc"
description = "Temporary KMS Terraform module validation"

key_type     = "SYMMETRIC"
key_spec     = "SYMMETRIC_DEFAULT"
key_usage    = "ENCRYPT_DECRYPT"
key_origin   = "AWS_KMS"
multi_region = false

# -----------------------------------------------------------------------------
# Alias and tags
# -----------------------------------------------------------------------------

alias_name   = "alias/kms-module-poc"
enable_alias = true

tags = {
  Environment = "dev"
  Purpose     = "terraform-module-testing"
}

# -----------------------------------------------------------------------------
# Key policy and permissions
# -----------------------------------------------------------------------------

key_administrator_arns = []
key_user_arns          = []
external_account_ids   = []

key_policy_mode = "STANDARD"
# key_policy_mode = "CUSTOM"

# Uncomment when testing a custom key policy.
# key_policy_json = <<-JSON
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "EnableAccountIAMDelegation",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "arn:aws:iam::700030738273:root"
#       },
#       "Action": "kms:*",
#       "Resource": "*"
#     }
#   ]
# }
# JSON

enable_key_deletion = false

# -----------------------------------------------------------------------------
# Rotation and lifecycle
# -----------------------------------------------------------------------------

enable_key_rotation     = true
rotation_period_in_days = null
key_enabled             = true
deletion_window_in_days = 30

# -----------------------------------------------------------------------------
# Deployment context
# -----------------------------------------------------------------------------

account_id = "700030738273"
aws_region = "ap-south-1"
