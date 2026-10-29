
# -----------------------------------------------------------------------------
# KMS key configuration
# -----------------------------------------------------------------------------

variable "key_name" {
  description = "Logical name for the KMS key."
  type        = string

  validation {
    condition     = length(trimspace(var.key_name)) > 0
    error_message = "key_name must not be empty."
  }
}

variable "description" {
  description = "Optional description of the KMS key."
  type        = string
  default     = null
}

variable "key_type" {
  description = "KMS key type: SYMMETRIC or ASYMMETRIC."
  type        = string
  default     = "SYMMETRIC"

  validation {
    condition     = contains(["SYMMETRIC", "ASYMMETRIC"], var.key_type)
    error_message = "key_type must be SYMMETRIC or ASYMMETRIC."
  }
}

variable "key_spec" {
  description = "Cryptographic specification for the KMS key."
  type        = string
  default     = "SYMMETRIC_DEFAULT"

  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "HMAC_224",
      "HMAC_256",
      "HMAC_384",
      "HMAC_512",
      "RSA_2048",
      "RSA_3072",
      "RSA_4096",
      "ECC_NIST_P256",
      "ECC_NIST_P384",
      "ECC_NIST_P521",
      "ECC_SECG_P256K1",
      "SM2",
      "ECC_NIST_EDWARDS25519",
      "ML_DSA_44",
      "ML_DSA_65",
      "ML_DSA_87"
    ], var.key_spec)

    error_message = "key_spec must be a recognized KMS key specification."
  }
}

variable "key_usage" {
  description = "Permitted cryptographic operations for the KMS key."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition = contains([
      "ENCRYPT_DECRYPT",
      "SIGN_VERIFY",
      "GENERATE_VERIFY_MAC",
      "KEY_AGREEMENT"
    ], var.key_usage)

    error_message = "Invalid key_usage value."
  }
}

variable "key_origin" {
  description = "Source of KMS key material."
  type        = string
  default     = "AWS_KMS"

  validation {
    condition = contains([
      "AWS_KMS",
      "EXTERNAL",
      "AWS_CLOUDHSM",
      "EXTERNAL_KEY_STORE"
    ], var.key_origin)

    error_message = "Invalid key_origin value."
  }
}

variable "multi_region" {
  description = "Whether to create a multi-Region KMS key."
  type        = bool
  default     = false
}

variable "confirm_external_key_material" {
  description = "Acknowledges the additional responsibilities of imported key material."
  type        = bool
  default     = false
}

variable "custom_key_store_id" {
  description = "Existing CloudHSM custom key store ID, when applicable."
  type        = string
  default     = null
}

variable "external_key_store_id" {
  description = "Existing AWS KMS external key store ID, when applicable."
  type        = string
  default     = null
}

variable "xks_key_id" {
  description = "External key identifier for an external key store."
  type        = string
  default     = null
}

variable "confirm_external_key_store_risks" {
  description = "Acknowledges external key store availability and latency risks."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Alias and tags
# -----------------------------------------------------------------------------

variable "alias_name" {
  description = "Optional KMS alias, including the alias/ prefix."
  type        = string
  default     = null

  validation {
    condition = (
      var.alias_name == null ||
      can(regex("^alias/[A-Za-z0-9/_-]+$", var.alias_name))
    )
    error_message = "alias_name must begin with alias/ and contain valid alias characters."
  }
}

variable "enable_alias" {
  description = "Whether to create a KMS alias."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for the KMS key."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Key policy and permissions
# -----------------------------------------------------------------------------

variable "key_administrator_arns" {
  description = "IAM role or user ARNs granted key-administration permissions in the standard policy."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.key_administrator_arns :
      can(regex("^arn:[^:]+:iam::[0-9]{12}:(role|user)/.+$", arn))
    ])
    error_message = "Each administrator must be an IAM role or user ARN."
  }
}

variable "enable_key_deletion" {
  description = "Whether the generated administrator policy includes key deletion scheduling permissions."
  type        = bool
  default     = false
}

variable "key_user_arns" {
  description = "IAM role or user ARNs granted cryptographic key-use permissions in the standard policy."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.key_user_arns :
      can(regex("^arn:[^:]+:iam::[0-9]{12}:(role|user)/.+$", arn))
    ])
    error_message = "Each key user must be an IAM role or user ARN."
  }
}

variable "external_account_ids" {
  description = "AWS account IDs granted cross-account access through the generated key policy."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for account_id in var.external_account_ids :
      can(regex("^[0-9]{12}$", account_id))
    ])
    error_message = "Each external account ID must contain exactly 12 digits."
  }
}

variable "key_policy_mode" {
  description = "STANDARD to generate a policy, or CUSTOM to supply a complete policy JSON document."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "CUSTOM"], var.key_policy_mode)
    error_message = "key_policy_mode must be STANDARD or CUSTOM."
  }
}

variable "key_policy_json" {
  description = "Complete custom KMS key policy JSON. Required when key_policy_mode is CUSTOM."
  type        = string
  default     = null

  validation {
    condition = (
      var.key_policy_json == null ||
      can(jsondecode(var.key_policy_json))
    )
    error_message = "key_policy_json must contain valid JSON."
  }
}

# -----------------------------------------------------------------------------
# Rotation and lifecycle
# -----------------------------------------------------------------------------

variable "enable_key_rotation" {
  description = "Whether automatic key rotation is enabled for a supported key."
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Optional automatic key rotation interval in days. Null uses the AWS default where supported."
  type        = number
  default     = null

  validation {
    condition = (
      var.rotation_period_in_days == null ||
      (
        var.rotation_period_in_days >= 90 &&
        var.rotation_period_in_days <= 2560 &&
        floor(var.rotation_period_in_days) == var.rotation_period_in_days
      )
    )
    error_message = "rotation_period_in_days must be a whole number between 90 and 2560."
  }
}

variable "key_enabled" {
  description = "Whether the KMS key should be enabled after creation."
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled KMS key deletion takes effect."
  type        = number
  default     = 30

  validation {
    condition = (
      var.deletion_window_in_days >= 7 &&
      var.deletion_window_in_days <= 30 &&
      floor(var.deletion_window_in_days) == var.deletion_window_in_days
    )
    error_message = "deletion_window_in_days must be a whole number from 7 through 30."
  }
}

# -----------------------------------------------------------------------------
# Deployment context
# -----------------------------------------------------------------------------

variable "account_id" {
  description = "Optional expected AWS account ID used to verify the deployment target."
  type        = string
  default     = null

  validation {
    condition = (
      var.account_id == null ||
      can(regex("^[0-9]{12}$", var.account_id))
    )
    error_message = "When supplied, account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_region" {
  description = "AWS Region in which the KMS key will be managed."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}
