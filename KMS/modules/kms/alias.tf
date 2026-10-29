
resource "aws_kms_alias" "this" {
  count = var.enable_alias ? 1 : 0

  name          = local.effective_alias_name
  target_key_id = aws_kms_key.this.key_id

  lifecycle {
    precondition {
      condition = (
        !local.uses_external_key_material ||
        var.confirm_external_key_material
      )
      error_message = "Confirm external key material before creating an alias for a key using EXTERNAL origin."
    }

    precondition {
      condition = (
        !local.uses_external_key_store ||
        var.confirm_external_key_store_risks
      )
      error_message = "Confirm the external key store risks before creating an alias for an external key store key."
    }
  }
}
