
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.cluster_identifier

  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.secret_kms_key_id

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  availability_zones = (
    var.enable_availability_zones &&
    length(var.availability_zones) > 0
    ? var.availability_zones
    : null
  )
  db_cluster_parameter_group_name = (
    var.use_custom_parameter_groups
    ? aws_rds_cluster_parameter_group.this[0].name
    : null
  )

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.storage_encrypted ? var.kms_key_id : null
  storage_type      = var.storage_type

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  enabled_cloudwatch_logs_exports = (
    var.enabled_cloudwatch_logs_exports
  )

  iam_database_authentication_enabled = (
    var.iam_database_authentication_enabled
  )

  enable_http_endpoint = var.enable_http_endpoint

  deletion_protection = var.deletion_protection

  copy_tags_to_snapshot = true
  apply_immediately     = var.apply_immediately

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  database_insights_mode    = lower(var.database_insights_mode)

  network_type = upper(var.network_type)


  dynamic "serverlessv2_scaling_configuration" {
    for_each = lower(var.deployment_mode) == "serverless_v2" ? [1] : []

    content {
      min_capacity = var.serverless_v2_min_capacity
      max_capacity = var.serverless_v2_max_capacity
    }
  }



  tags = merge(local.common_tags, {
    Name = local.cluster_identifier
  })

  depends_on = [
    aws_iam_role_policy_attachment.monitoring
  ]
}
