
locals {
  # Cluster identifier
  cluster_identifier = var.name

  # Derive the Aurora MySQL parameter group family from the engine version.
  # For example: 8.0.mysql_aurora.3.08.2 -> aurora-mysql8.0
  derived_parameter_group_family = (
    can(regex("^8\\.0\\.mysql_aurora\\.", var.engine_version))
    ? "aurora-mysql8.0"
    : can(regex("^8\\.4\\.mysql_aurora\\.", var.engine_version))
    ? "aurora-mysql8.4"
    : null
  )

  parameter_group_family = (
    var.parameter_group_family != null
    ? var.parameter_group_family
    : local.derived_parameter_group_family
  )

  # Writer and reader instance classes
  writer_instance_class = (
    lower(var.deployment_mode) == "serverless_v2"
    ? "db.serverless"
    : var.instance_class
  )

  reader_instance_class = (
    lower(var.deployment_mode) == "serverless_v2"
    ? "db.serverless"
    : coalesce(var.reader_instance_class, var.instance_class)
  )

  # Resource names
  subnet_group_name       = "${var.name}-subnet-group"
  security_group_name     = "${var.name}-sg"
  cluster_parameter_name  = "${var.name}-cluster-pg"
  instance_parameter_name = "${var.name}-instance-pg"
  monitoring_role_name    = "${var.name}-rds-monitoring"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Engine    = "aurora-mysql"
      Name      = var.name
    }
  )

  # Reader instance indexes
  reader_indices = toset([
    for i in range(var.reader_count) : tostring(i + 1)
  ])
}
