
locals {
  cluster_identifier = var.name

  # Derive the parameter group family from the concrete engine version.
  # Examples:
  # 17.1 -> aurora-postgresql17
  # 17.9 -> aurora-postgresql17
  # 16.4 -> aurora-postgresql16
  derived_parameter_group_family = (
    can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", var.engine_version))
    ? "aurora-postgresql${split(".", var.engine_version)[0]}"
    : null
  )

  parameter_group_family = (
    var.parameter_group_family != null
    ? var.parameter_group_family
    : local.derived_parameter_group_family
  )


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

  subnet_group_name       = "${var.name}-subnet-group"
  security_group_name     = "${var.name}-sg"
  cluster_parameter_name  = "${var.name}-cluster-pg"
  instance_parameter_name = "${var.name}-instance-pg"
  monitoring_role_name    = "${var.name}-rds-monitoring"

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Engine    = "aurora-postgresql"
      Name      = var.name
    }
  )

  reader_indices = toset([
    for i in range(var.reader_count) : tostring(i + 1)
  ])
}
