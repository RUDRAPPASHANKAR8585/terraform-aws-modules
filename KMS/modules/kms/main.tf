data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  description              = var.description
  customer_master_key_spec = local.normalized_key_spec
  key_usage                = local.normalized_key_usage
  policy                   = local.effective_key_policy

  # AWS CloudHSM and External Key Store configurations.
  # AWS infers the key origin from these arguments.
  custom_key_store_id = (
    local.uses_cloudhsm_key_store
    ? var.custom_key_store_id
    : local.uses_external_key_store
    ? var.external_key_store_id
    : null
  )

  xks_key_id = (
    local.uses_external_key_store
    ? var.xks_key_id
    : null
  )

  multi_region            = var.multi_region
  key_enabled               = var.key_enabled 
  deletion_window_in_days = var.deletion_window_in_days

  enable_key_rotation = var.enable_key_rotation

  rotation_period_in_days = (
    var.enable_key_rotation
    ? var.rotation_period_in_days
    : null
  )

  tags = local.effective_tags

  lifecycle {
    prevent_destroy = true

    # -------------------------------------------------------------------------
    # Key type, specification, and usage compatibility
    # -------------------------------------------------------------------------

    precondition {
      condition = (
        # Symmetric encryption key
        (
          local.normalized_key_spec == "SYMMETRIC_DEFAULT" &&
          local.normalized_key_type == "SYMMETRIC" &&
          local.normalized_key_usage == "ENCRYPT_DECRYPT"
        ) ||

        # Symmetric HMAC keys
        (
          contains([
            "HMAC_224",
            "HMAC_256",
            "HMAC_384",
            "HMAC_512"
          ], local.normalized_key_spec) &&
          local.normalized_key_type == "SYMMETRIC" &&
          local.normalized_key_usage == "GENERATE_VERIFY_MAC"
        ) ||

        # Asymmetric RSA keys
        (
          contains([
            "RSA_2048",
            "RSA_3072",
            "RSA_4096"
          ], local.normalized_key_spec) &&
          local.normalized_key_type == "ASYMMETRIC" &&
          contains([
            "ENCRYPT_DECRYPT",
            "SIGN_VERIFY"
          ], local.normalized_key_usage)
        ) ||

        # NIST elliptic-curve keys
        (
          contains([
            "ECC_NIST_P256",
            "ECC_NIST_P384",
            "ECC_NIST_P521"
          ], local.normalized_key_spec) &&
          local.normalized_key_type == "ASYMMETRIC" &&
          contains([
            "SIGN_VERIFY",
            "KEY_AGREEMENT"
          ], local.normalized_key_usage)
        ) ||

        # secp256k1 supports signing and verification
        (
          local.normalized_key_spec == "ECC_SECG_P256K1" &&
          local.normalized_key_type == "ASYMMETRIC" &&
          local.normalized_key_usage == "SIGN_VERIFY"
        ) ||

        # Edwards25519 supports signing and verification
        (
          local.normalized_key_spec == "ECC_NIST_EDWARDS25519" &&
          local.normalized_key_type == "ASYMMETRIC" &&
          local.normalized_key_usage == "SIGN_VERIFY"
        ) ||

        # ML-DSA keys support signing and verification
        (
          contains([
            "ML_DSA_44",
            "ML_DSA_65",
            "ML_DSA_87"
          ], local.normalized_key_spec) &&
          local.normalized_key_type == "ASYMMETRIC" &&
          local.normalized_key_usage == "SIGN_VERIFY"
        ) ||

        # SM2: supported usages in eligible AWS Regions
        (
          local.normalized_key_spec == "SM2" &&
          local.normalized_key_type == "ASYMMETRIC" &&
          contains([
            "ENCRYPT_DECRYPT",
            "SIGN_VERIFY",
            "KEY_AGREEMENT"
          ], local.normalized_key_usage)
        )
      )

      error_message = "Invalid key_type, key_spec, and key_usage combination. Select a combination supported by AWS KMS."
    }

    # -------------------------------------------------------------------------
    # Account and Region safeguards
    # -------------------------------------------------------------------------

    precondition {
      condition = (
        var.account_id == null ||
        data.aws_caller_identity.current.account_id == var.account_id
      )

      error_message = "The active AWS account does not match account_id."
    }

    precondition {
      condition = (
        var.aws_region == null ||
        data.aws_region.current.name == var.aws_region
      )

      error_message = "The configured AWS Region does not match aws_region."
    }

    # -------------------------------------------------------------------------
    # Key material origin safeguards
    # -------------------------------------------------------------------------

    # Imported external key material requires a separate workflow.
    precondition {
      condition     = local.normalized_key_origin != "EXTERNAL"
      error_message = "EXTERNAL key material is not supported by this creation path. Implement a dedicated import-key-material workflow before selecting this origin."
    }

    # CloudHSM requires a custom key store.
    precondition {
      condition = (
        !local.uses_cloudhsm_key_store ||
        (
          var.custom_key_store_id != null &&
          trimspace(var.custom_key_store_id) != ""
        )
      )

      error_message = "For AWS_CLOUDHSM origin, provide custom_key_store_id."
    }

    # External Key Store requires both identifiers.
    precondition {
      condition = (
        !local.uses_external_key_store ||
        (
          var.external_key_store_id != null &&
          trimspace(var.external_key_store_id) != "" &&
          var.xks_key_id != null &&
          trimspace(var.xks_key_id) != ""
        )
      )

      error_message = "For EXTERNAL_KEY_STORE origin, provide external_key_store_id and xks_key_id."
    }

    # Custom key stores support symmetric encryption keys only.
    precondition {
      condition = (
        !(local.uses_cloudhsm_key_store || local.uses_external_key_store) ||
        (
          local.normalized_key_type == "SYMMETRIC" &&
          local.normalized_key_spec == "SYMMETRIC_DEFAULT" &&
          local.normalized_key_usage == "ENCRYPT_DECRYPT" &&
          !var.multi_region
        )
      )

      error_message = "CloudHSM and External Key Store keys must use SYMMETRIC_DEFAULT, ENCRYPT_DECRYPT, and single-Region configuration."
    }

    # -------------------------------------------------------------------------
    # Automatic rotation safeguards
    # -------------------------------------------------------------------------

    precondition {
      condition = (
        !var.enable_key_rotation ||
        (
          local.normalized_key_origin == "AWS_KMS" &&
          local.normalized_key_type == "SYMMETRIC" &&
          local.normalized_key_spec == "SYMMETRIC_DEFAULT" &&
          local.normalized_key_usage == "ENCRYPT_DECRYPT"
        )
      )

      error_message = "Automatic rotation is supported by this module only for AWS_KMS symmetric encryption keys using SYMMETRIC_DEFAULT."
    }

    precondition {
      condition = (
        var.rotation_period_in_days == null ||
        var.enable_key_rotation
      )

      error_message = "Set enable_key_rotation = true when specifying rotation_period_in_days."
    }

    # -------------------------------------------------------------------------
    # Key policy safeguards
    # -------------------------------------------------------------------------

    # CUSTOM policy mode must provide policy JSON.
    precondition {
      condition = (
        local.normalized_key_policy_mode != "CUSTOM" ||
        (
          var.key_policy_json != null &&
          trimspace(var.key_policy_json) != ""
        )
      )

      error_message = "Provide key_policy_json when key_policy_mode is CUSTOM."
    }

    # Standard policy must retain account-level IAM delegation.
    precondition {
      condition = (
        local.normalized_key_policy_mode != "STANDARD" ||
        var.account_id != null ||
        data.aws_caller_identity.current.account_id != ""
      )

      error_message = "Unable to determine the AWS account for the standard key policy."
    }
  }
}