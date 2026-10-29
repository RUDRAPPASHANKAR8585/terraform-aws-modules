
module "kms" {
  source = "./modules/kms"

  # Key configuration
  key_name     = var.key_name
  description  = var.description
  key_type     = var.key_type
  key_spec     = var.key_spec
  key_usage    = var.key_usage
  key_origin   = var.key_origin
  multi_region = var.multi_region

  # Key material and custom key stores
  confirm_external_key_material    = var.confirm_external_key_material
  custom_key_store_id              = var.custom_key_store_id
  external_key_store_id            = var.external_key_store_id
  xks_key_id                       = var.xks_key_id
  confirm_external_key_store_risks = var.confirm_external_key_store_risks

  # Alias and tags
  alias_name   = var.alias_name
  enable_alias = var.enable_alias
  tags         = var.tags

  # Key policy and permissions
  key_administrator_arns = var.key_administrator_arns
  enable_key_deletion    = var.enable_key_deletion
  key_user_arns          = var.key_user_arns
  external_account_ids   = var.external_account_ids
  key_policy_mode        = var.key_policy_mode
  key_policy_json        = var.key_policy_json

  # Rotation and lifecycle
  enable_key_rotation     = var.enable_key_rotation
  rotation_period_in_days = var.rotation_period_in_days
  is_enabled              = var.key_enabled
  deletion_window_in_days = var.deletion_window_in_days

  # Deployment context
  account_id = var.account_id
  aws_region = var.aws_region
}
