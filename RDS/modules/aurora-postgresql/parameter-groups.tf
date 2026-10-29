
resource "aws_rds_cluster_parameter_group" "this" {
  count       = var.use_custom_parameter_groups ? 1 : 0
  name        = local.cluster_parameter_name
  family      = local.parameter_group_family
  description = "Aurora PostgreSQL cluster parameters for ${var.name}"

  dynamic "parameter" {
    for_each = (
      var.enable_custom_cluster_parameters
      ? var.cluster_parameters
      : {}
    )

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_parameter_name
    Type = "cluster"
  })
}

resource "aws_db_parameter_group" "this" {
  count       = var.use_custom_parameter_groups ? 1 : 0
  name        = local.instance_parameter_name
  family      = local.parameter_group_family
  description = "Aurora PostgreSQL instance parameters for ${var.name}"

  dynamic "parameter" {
    for_each = (
      var.enable_custom_instance_parameters
      ? var.instance_parameters
      : {}
    )

    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, {
    Name = local.instance_parameter_name
    Type = "instance"
  })
}
