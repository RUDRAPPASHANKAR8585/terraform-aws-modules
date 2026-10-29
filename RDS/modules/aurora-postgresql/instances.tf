
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.this.id

  engine         = "aurora-postgresql"
  engine_version = var.engine_version
  instance_class = local.writer_instance_class

  db_parameter_group_name = (
    var.use_custom_parameter_groups
    ? aws_db_parameter_group.this[0].name
    : null
  )

  db_subnet_group_name = aws_db_subnet_group.this.name

  publicly_accessible = (
    var.publicly_accessible &&
    var.allow_public_access
  )

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.effective_monitoring_role_arn

  performance_insights_enabled = (
    var.performance_insights_enabled
  )

  performance_insights_kms_key_id = (
    var.performance_insights_enabled
    ? var.performance_insights_kms_key_id
    : null
  )

  performance_insights_retention_period = (
    var.performance_insights_enabled
    ? var.performance_insights_retention_period
    : null
  )

  auto_minor_version_upgrade = (
    var.auto_minor_version_upgrade
  )

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.name}-writer"
    Role = "writer"
  })

  depends_on = [
    aws_iam_role_policy_attachment.monitoring
  ]
}

resource "aws_rds_cluster_instance" "reader" {
  for_each = local.reader_indices

  identifier         = "${var.name}-reader-${each.key}"
  cluster_identifier = aws_rds_cluster.this.id

  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  instance_class = local.reader_instance_class

  db_parameter_group_name = (
    var.use_custom_parameter_groups
    ? aws_db_parameter_group.this[0].name
    : null
  )

  db_subnet_group_name = aws_db_subnet_group.this.name

  publicly_accessible = (
    var.publicly_accessible &&
    var.allow_public_access
  )

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.effective_monitoring_role_arn

  performance_insights_enabled = (
    var.performance_insights_enabled
  )

  performance_insights_kms_key_id = (
    var.performance_insights_enabled
    ? var.performance_insights_kms_key_id
    : null
  )

  performance_insights_retention_period = (
    var.performance_insights_enabled
    ? var.performance_insights_retention_period
    : null
  )

  auto_minor_version_upgrade = (
    var.auto_minor_version_upgrade
  )

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.name}-reader-${each.key}"
    Role = "reader"
  })

  depends_on = [
    aws_iam_role_policy_attachment.monitoring
  ]
}
