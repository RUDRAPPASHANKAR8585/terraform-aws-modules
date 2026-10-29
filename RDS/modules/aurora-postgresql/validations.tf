
resource "terraform_data" "validate_inputs" {
  input = {
    name           = var.name
    engine_version = var.engine_version
  }

  lifecycle {
    precondition {
      condition = (
        var.storage_encrypted ||
        var.kms_key_id == null
      )
      error_message = "kms_key_id cannot be set when storage_encrypted is false."
    }

    precondition {
      condition = (
        !var.skip_final_snapshot ||
        var.final_snapshot_identifier == null
      )
      error_message = "Do not specify final_snapshot_identifier when skip_final_snapshot is true."
    }

    precondition {
      condition = (
        var.skip_final_snapshot ||
        var.final_snapshot_identifier != null
      )
      error_message = "A final_snapshot_identifier is required when skip_final_snapshot is false."
    }

    precondition {
      condition = (
        var.performance_insights_enabled ||
        var.performance_insights_kms_key_id == null
      )
      error_message = "Do not set performance_insights_kms_key_id when Performance Insights is disabled."
    }

    precondition {
      condition = (
        lower(var.database_insights_mode) != "advanced" ||
        (
          var.performance_insights_enabled &&
          var.performance_insights_retention_period >= 465
        )
      )

      error_message = "Advanced Database Insights requires Performance Insights to be enabled and retention to be at least 465 days."
    }


    precondition {
      condition = (
        !var.publicly_accessible ||
        var.allow_public_access
      )
      error_message = "Public accessibility requires allow_public_access = true. Confirm organizational security policy before enabling it."
    }


    precondition {
      condition = (
        lower(var.deployment_mode) != "serverless_v2" ||
        var.serverless_v2_min_capacity <= var.serverless_v2_max_capacity
      )
      error_message = "For Serverless v2, minimum capacity must be less than or equal to maximum capacity."
    }


    precondition {
      condition = (
        local.derived_parameter_group_family == null ||
        var.parameter_group_family == null ||
        var.parameter_group_family == local.derived_parameter_group_family
      )
      error_message = "The parameter-group family must match the Aurora PostgreSQL engine version."
    }
  }
}

resource "terraform_data" "validate_cluster_parameters" {
  input = var.cluster_parameters

  lifecycle {
    precondition {
      condition = (
        var.enable_custom_cluster_parameters ||
        length(var.cluster_parameters) == 0
      )

      error_message = "Set enable_custom_cluster_parameters to true when supplying cluster parameter overrides."
    }
  }
}

resource "terraform_data" "validate_instance_parameters" {
  input = var.instance_parameters

  lifecycle {
    precondition {
      condition = (
        var.enable_custom_instance_parameters ||
        length(var.instance_parameters) == 0
      )

      error_message = "Set enable_custom_instance_parameters to true when supplying instance parameter overrides."
    }
  }
}