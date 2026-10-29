
data "aws_partition" "current" {}

data "aws_iam_policy_document" "standard" {
  # Allow the owning account to delegate KMS permissions through IAM.
  statement {
    sid    = "EnableAccountIAMDelegation"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${coalesce(var.account_id, data.aws_caller_identity.current.account_id)}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Optional key administrators.
  dynamic "statement" {
    for_each = length(var.key_administrator_arns) > 0 ? [1] : []

    content {
      sid    = "AllowKeyAdministration"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.key_administrator_arns
      }

      actions = concat(
        [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Enable*",
          "kms:Disable*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:RetireGrant"
        ],
        var.enable_key_deletion ? [
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ] : []
      )

      resources = ["*"]
    }
  }

  # Optional key users. Permissions depend on the selected key usage.
  dynamic "statement" {
    for_each = length(var.key_user_arns) > 0 ? [1] : []

    content {
      sid    = "AllowKeyUsage"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.key_user_arns
      }

      actions = (
        local.uses_hmac ? [
          "kms:DescribeKey",
          "kms:GenerateMac",
          "kms:VerifyMac"
        ] :
        local.normalized_key_usage == "SIGN_VERIFY" ? [
          "kms:DescribeKey",
          "kms:Sign",
          "kms:Verify"
        ] :
        local.normalized_key_usage == "KEY_AGREEMENT" ? [
          "kms:DescribeKey",
          "kms:DeriveSharedSecret"
          ] : [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
      )

      resources = ["*"]
    }
  }

  # Optional cross-account key usage.
  dynamic "statement" {
    for_each = length(var.external_account_ids) > 0 ? [1] : []

    content {
      sid    = "AllowExternalAccountUsage"
      effect = "Allow"

      principals {
        type = "AWS"
        identifiers = [
          for account_id in var.external_account_ids :
          "arn:${data.aws_partition.current.partition}:iam::${account_id}:root"
        ]
      }

      actions = (
        local.uses_hmac ? [
          "kms:DescribeKey",
          "kms:GenerateMac",
          "kms:VerifyMac"
        ] :
        local.normalized_key_usage == "SIGN_VERIFY" ? [
          "kms:DescribeKey",
          "kms:Sign",
          "kms:Verify"
        ] :
        local.normalized_key_usage == "KEY_AGREEMENT" ? [
          "kms:DescribeKey",
          "kms:DeriveSharedSecret"
          ] : [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
      )

      resources = ["*"]
    }
  }
}
