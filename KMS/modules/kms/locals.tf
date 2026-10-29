# -----------------------------------------------------------------------------
# Normalized KMS configuration
# -----------------------------------------------------------------------------

locals {
  normalized_key_type        = upper(var.key_type)
  normalized_key_usage       = upper(var.key_usage)
  normalized_key_spec        = upper(var.key_spec)
  normalized_key_origin      = upper(var.key_origin)
  normalized_key_policy_mode = upper(var.key_policy_mode)

  # ---------------------------------------------------------------------------
  # KMS alias
  # ---------------------------------------------------------------------------

  # An alias name is generated when alias_name is omitted.
  # Alias creation is controlled by enable_alias in alias.tf.
  effective_alias_name = (
    var.alias_name != null
    ? var.alias_name
    : "alias/${var.key_name}"
  )

  # ---------------------------------------------------------------------------
  # Key configuration classification
  # ---------------------------------------------------------------------------
  uses_hmac = local.normalized_key_usage == "GENERATE_VERIFY_MAC"

  uses_external_key_material = local.normalized_key_origin == "EXTERNAL"
  uses_cloudhsm_key_store    = local.normalized_key_origin == "AWS_CLOUDHSM"
  uses_external_key_store    = local.normalized_key_origin == "EXTERNAL_KEY_STORE"

  # ---------------------------------------------------------------------------
  # Standard organizational tags
  # Mandatory organizational tags override caller-provided values.
  # ---------------------------------------------------------------------------

  mandatory_tags = merge(
    {
      Name      = var.key_name
      ManagedBy = "Terraform"
    }
  )

  effective_tags = merge(var.tags, local.mandatory_tags)

  # ---------------------------------------------------------------------------
  # Effective key policy
  # CUSTOM mode uses the supplied JSON policy when present. The resource-level
  # precondition in main.tf must reject CUSTOM mode when the policy is absent.
  # ---------------------------------------------------------------------------

  effective_key_policy = (
    local.normalized_key_policy_mode == "CUSTOM" && var.key_policy_json != null
    ? jsonencode(jsondecode(var.key_policy_json))
    : data.aws_iam_policy_document.standard.json
  )
}
