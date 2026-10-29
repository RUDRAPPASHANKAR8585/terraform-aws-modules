
resource "terraform_data" "validate_inputs" {
  input = var.name

  lifecycle {
    precondition {
      condition = (
        var.storage_encrypted ||
        var.kms_key_id == null
      )
      error_message = "kms_key_id must be null when storage_encrypted is false."
    }

    precondition {
      condition = (
        !var.skip_final_snapshot ||
        var.final_snapshot_identifier == null
      )
      error_message = "final_snapshot_identifier must be null when skip_final_snapshot is true."
    }

    precondition {
      condition = (
        var.skip_final_snapshot ||
        (
          var.final_snapshot_identifier != null &&
          length(trimspace(var.final_snapshot_identifier)) > 0
        )
      )
      error_message = "final_snapshot_identifier must be provided when skip_final_snapshot is false."
    }

    precondition {
      condition = (
        var.performance_insights_enabled ||
        var.performance_insights_kms_key_id == null
      )
      error_message = "performance_insights_kms_key_id must be null when Performance Insights is disabled."
    }

    precondition {
      condition = (
        lower(var.database_insights_mode) != "advanced" ||
        (
          var.performance_insights_enabled &&
          var.performance_insights_retention_period >= 465
        )
      )
      error_message = "Advanced Database Insights requires Performance Insights to be enabled and retention of at least 465 days."
    }

    precondition {
      condition = (
        !var.publicly_accessible ||
        var.allow_public_access
      )
      error_message = "Set allow_public_access to true to explicitly permit publicly accessible DB instances."
    }

    precondition {
      condition = (
        var.serverless_v2_min_capacity <=
        var.serverless_v2_max_capacity
      )
      error_message = "serverless_v2_min_capacity must be less than or equal to serverless_v2_max_capacity."
    }

    precondition {
      condition = (
        var.parameter_group_family == null ||
        local.derived_parameter_group_family == null ||
        var.parameter_group_family == local.derived_parameter_group_family
      )
      error_message = "parameter_group_family does not match the family derived from engine_version. Confirm the engine version and parameter group family."
    }

    precondition {
      condition = (
        var.use_custom_parameter_groups ||
        (
          length(var.cluster_parameters) == 0 &&
          length(var.instance_parameters) == 0
        )
      )
      error_message = "Cluster and instance parameter maps must be empty when use_custom_parameter_groups is false."
    }

    precondition {
      condition = (
        var.enable_custom_cluster_parameters ||
        length(var.cluster_parameters) == 0
      )
      error_message = "cluster_parameters must be empty unless enable_custom_cluster_parameters is true."
    }

    precondition {
      condition = (
        var.enable_custom_instance_parameters ||
        length(var.instance_parameters) == 0
      )
      error_message = "instance_parameters must be empty unless enable_custom_instance_parameters is true."
    }
  }
}
