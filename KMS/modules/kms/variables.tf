
# -----------------------------------------------------------------------------
# Key configuration
# -----------------------------------------------------------------------------

variable "key_name" {
  description = "Logical name for the requested KMS key. Used for resource identification and, when alias_name is not supplied, for generating the alias."
  type        = string

  validation {
    condition     = length(trimspace(var.key_name)) > 0
    error_message = "key_name must not be empty."
  }
}

variable "description" {
  description = "Optional description of the KMS key. Describes the key's intended purpose and can be changed after creation."
  type        = string
  default     = null
}

variable "key_spec" {
  description = "Cryptographic configuration of the KMS key. Examples include SYMMETRIC_DEFAULT, HMAC_256, RSA_2048, ECC_NIST_P256, and supported ML-DSA or SM2 specifications where available. The value is fixed when the key is created."
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

    error_message = "key_spec must be a recognized KMS key specification. Availability and valid combinations depend on the AWS Region and key usage."
  }
}

variable "key_usage" {
  description = "Cryptographic operations permitted for the KMS key. Common values are ENCRYPT_DECRYPT, SIGN_VERIFY, GENERATE_VERIFY_MAC, and KEY_AGREEMENT. Supported values depend on key_spec and AWS KMS capabilities."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition = contains([
      "ENCRYPT_DECRYPT",
      "SIGN_VERIFY",
      "GENERATE_VERIFY_MAC",
      "KEY_AGREEMENT"
    ], var.key_usage)

    error_message = "key_usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, GENERATE_VERIFY_MAC, or KEY_AGREEMENT."
  }
}


# -----------------------------------------------------------------------------
# Key material origin and regionality
# -----------------------------------------------------------------------------

variable "key_origin" {
  description = "Source of key material. AWS_KMS means AWS KMS creates and manages the material; EXTERNAL means material is imported; AWS_CLOUDHSM uses an AWS CloudHSM custom key store; EXTERNAL_KEY_STORE uses an external key manager."
  type        = string
  default     = "AWS_KMS"

  validation {
    condition = contains([
      "AWS_KMS",
      "EXTERNAL",
      "AWS_CLOUDHSM",
      "EXTERNAL_KEY_STORE"
    ], var.key_origin)

    error_message = "key_origin must be AWS_KMS, EXTERNAL, AWS_CLOUDHSM, or EXTERNAL_KEY_STORE."
  }
}

variable "multi_region" {
  description = "Whether to create a multi-Region primary key that can be replicated into other AWS Regions. Applicable only to supported key origins and specifications."
  type        = bool
  default     = false
}

variable "confirm_external_key_material" {
  description = "Explicit acknowledgement that imported key material has additional security, durability, availability, expiration, and recovery responsibilities. Required when key_origin is EXTERNAL."
  type        = bool
  default     = false
}

variable "custom_key_store_id" {
  description = "ID of an existing AWS CloudHSM custom key store. Required when key_origin is AWS_CLOUDHSM."
  type        = string
  default     = null
}

variable "external_key_store_id" {
  description = "ID of an existing external key store configured in AWS KMS. Required when key_origin is EXTERNAL_KEY_STORE."
  type        = string
  default     = null
}

variable "xks_key_id" {
  description = "Identifier of the external key in the external key manager. Required when creating a key with EXTERNAL_KEY_STORE origin."
  type        = string
  default     = null
}

variable "confirm_external_key_store_risks" {
  description = "Explicit acknowledgement that an external key store can have degraded latency, durability, and availability because it depends on an external key manager."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Alias, description, and tags
# -----------------------------------------------------------------------------

variable "alias_name" {
  description = "Optional KMS alias, including the alias/ prefix. For example alias/poc/dev/kms. If omitted, the module generates an alias from key_name."
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
  description = "Whether to create a KMS alias for the key."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Optional resource tags used to identify, organize, and track the KMS key. Mandatory organizational tags will be enforced by the module."
  type        = map(string)
  default     = {}
}


# -----------------------------------------------------------------------------
# Key administrative permissions
# -----------------------------------------------------------------------------

variable "key_administrator_arns" {
  description = "Existing IAM role or user ARNs to receive key-administration permissions in the generated standard key policy. These identities must already exist."
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
  description = "Whether the generated administrator policy should include permissions to schedule key deletion and cancel scheduled deletion. This does not itself delete or schedule deletion of the key."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Key usage permissions
# -----------------------------------------------------------------------------

variable "key_user_arns" {
  description = "Existing IAM role or user ARNs permitted to perform the cryptographic operations defined by the key policy. Permissions must be compatible with key_usage."
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
  description = "AWS account IDs whose principals may receive cross-account access through the generated key policy. Each external account must separately configure the required IAM permissions."
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


# -----------------------------------------------------------------------------
# Key policy configuration
# -----------------------------------------------------------------------------

variable "key_policy_mode" {
  description = "Policy configuration mode. STANDARD generates a policy from approved administrator, key-user, and external-account inputs. CUSTOM accepts a complete custom KMS key policy."
  type        = string
  default     = "STANDARD"

  validation {
    condition = contains(
      ["STANDARD", "CUSTOM"],
      var.key_policy_mode
    )

    error_message = "key_policy_mode must be STANDARD or CUSTOM."
  }
}

variable "key_policy_json" {
  description = "Complete custom KMS key policy as a JSON string. Required when key_policy_mode is CUSTOM. The policy must preserve authorized administration and comply with organizational security rules."
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
  description = "Whether to enable automatic key rotation for a supported KMS key. Availability depends on key specification, origin, and AWS KMS capabilities."
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Optional automatic rotation period in days. Null uses the AWS default where supported. Must comply with the selected key and origin."
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
  description = "Waiting period in days before a scheduled KMS key deletion takes effect. AWS accepts whole numbers from 7 through 30."
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
  description = "Optional expected 12-digit AWS account ID for the target deployment. When supplied, the module will verify it against the configured AWS provider identity."
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
  description = "Optional expected AWS Region for the KMS key. When supplied, the module will verify it against the configured AWS provider Region."
  type        = string
  default     = null
}

variable "key_type" {
  description = "High-level cryptographic key type selected in the AWS KMS console: SYMMETRIC or ASYMMETRIC. The selection must agree with key_spec and key_usage."
  type        = string
  default     = "SYMMETRIC"

  validation {
    condition = contains(
      ["SYMMETRIC", "ASYMMETRIC"],
      var.key_type
    )

    error_message = "key_type must be SYMMETRIC or ASYMMETRIC."
  }
}
