
variable "name" {
  description = "Aurora MySQL cluster identifier"
  type        = string

  validation {
    condition = (
      length(var.name) >= 1 &&
      length(var.name) <= 63 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$|^[a-z]$", var.name)) &&
      !strcontains(var.name, "--")
    )
    error_message = "Name must be 1-63 characters, start with a lowercase letter, contain only lowercase letters, numbers or hyphens, not contain consecutive hyphens, and not end with a hyphen."
  }
}

variable "engine_version" {
  description = "Concrete Aurora MySQL engine version, for example 8.0.mysql_aurora.3.08.2."
  type        = string

  validation {
    condition = can(regex(
      "^[0-9]+\\.[0-9]+\\.mysql_aurora\\.[0-9]+\\.[0-9]+(\\.[0-9]+)?$",
      var.engine_version
    ))
    error_message = "engine_version must use a concrete Aurora MySQL version format, such as 8.0.mysql_aurora.3.08.2. Verify that the version is supported in the target AWS region."
  }
}

variable "instance_class" {
  description = "Aurora MySQL writer instance class"
  type        = string
}

variable "reader_instance_class" {
  description = "Optional reader instance class; defaults to writer class"
  type        = string
  default     = null
}

variable "reader_count" {
  description = "Number of Aurora MySQL reader instances; one writer is always created"
  type        = number
  default     = 1

  validation {
    condition = (
      var.reader_count >= 0 &&
      var.reader_count == floor(var.reader_count) &&
      var.reader_count <= 15
    )
    error_message = "reader_count must be a whole number from 0 through 15."
  }
}

variable "enable_availability_zones" {
  description = "Whether to explicitly specify Availability Zones for the Aurora cluster"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Availability Zones for the Aurora cluster when explicitly specified"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Existing DB subnet IDs spanning at least two Availability Zones"
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) >= 2 &&
      length(distinct(var.subnet_ids)) == length(var.subnet_ids)
    )
    error_message = "Provide at least two unique subnet IDs."
  }
}

variable "ingress_rules" {
  description = "Approved inbound Aurora MySQL access rules"

  type = map(object({
    description              = string
    cidr_ipv4                = optional(string)
    source_security_group_id = optional(string)
  }))

  default = {}
}

variable "database_name" {
  description = "Optional initial database name"
  type        = string
  default     = null

  validation {
    condition = (
      var.database_name == null ||
      can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.database_name))
    )
    error_message = "database_name must start with a letter and contain only letters, numbers and underscores."
  }
}

variable "master_username" {
  description = "Aurora MySQL master username; password is managed by RDS in Secrets Manager"
  type        = string
  default     = "dbadmin"

  validation {
    condition = (
      length(var.master_username) >= 1 &&
      length(var.master_username) <= 16 &&
      can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.master_username))
    )
    error_message = "The master username must be 1-16 characters, start with a letter, and contain only letters, numbers and underscores."
  }
}

variable "kms_key_id" {
  description = "Optional customer-managed KMS key for cluster storage encryption"
  type        = string
  default     = null
}

variable "secret_kms_key_id" {
  description = "Optional KMS key for the RDS-managed master secret"
  type        = string
  default     = null
}

variable "storage_encrypted" {
  description = "Enable Aurora storage encryption"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "Aurora storage configuration: aurora or aurora-iopt1"
  type        = string
  default     = "aurora"

  validation {
    condition = contains(
      ["aurora", "aurora-iopt1"],
      var.storage_type
    )
    error_message = "storage_type must be aurora or aurora-iopt1."
  }
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7

  validation {
    condition = (
      var.backup_retention_period >= 1 &&
      var.backup_retention_period <= 35 &&
      var.backup_retention_period == floor(var.backup_retention_period)
    )
    error_message = "Aurora backup retention must be a whole number from 1 through 35."
  }
}

variable "preferred_backup_window" {
  description = "Optional daily backup window in UTC"
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "Optional weekly maintenance window in UTC"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protect the cluster against accidental deletion"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when destroying the cluster"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier used when skip_final_snapshot is false"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply eligible modifications immediately"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades for instances"
  type        = bool
  default     = true
}

variable "cluster_parameters" {
  description = "Custom Aurora MySQL cluster parameter overrides"

  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))

  default = {}
}

variable "enable_custom_cluster_parameters" {
  description = "Allow custom overrides for cluster parameters"
  type        = bool
  default     = false
}

variable "enable_custom_instance_parameters" {
  description = "Allow custom overrides for instance parameters"
  type        = bool
  default     = false
}

variable "instance_parameters" {
  description = "Custom Aurora MySQL DB instance parameter overrides"

  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))

  default = {}
}

variable "deployment_mode" {
  description = "Aurora MySQL deployment mode: provisioned or serverless_v2"
  type        = string
  default     = "provisioned"

  validation {
    condition = contains(
      ["provisioned", "serverless_v2"],
      lower(var.deployment_mode)
    )
    error_message = "deployment_mode must be provisioned or serverless_v2."
  }
}

variable "serverless_v2_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs"
  type        = number
  default     = 0.5

  validation {
    condition = (
      var.serverless_v2_min_capacity >= 0.5 &&
      var.serverless_v2_min_capacity <= 256 &&
      var.serverless_v2_min_capacity * 2 ==
      floor(var.serverless_v2_min_capacity * 2)
    )
    error_message = "Minimum capacity must be between 0.5 and 256 ACUs in increments of 0.5."
  }
}

variable "serverless_v2_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs"
  type        = number
  default     = 2

  validation {
    condition = (
      var.serverless_v2_max_capacity >= 0.5 &&
      var.serverless_v2_max_capacity <= 256 &&
      var.serverless_v2_max_capacity * 2 ==
      floor(var.serverless_v2_max_capacity * 2)
    )
    error_message = "Maximum capacity must be between 0.5 and 256 ACUs in increments of 0.5."
  }
}

variable "parameter_group_family" {
  description = "Optional explicit Aurora MySQL parameter group family; otherwise derived from engine_version"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds; 0 disables it"
  type        = number
  default     = 60

  validation {
    condition = contains(
      [0, 1, 5, 10, 15, 30, 60],
      var.monitoring_interval
    )
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30 or 60."
  }
}

variable "monitoring_role_arn" {
  description = "Optional existing IAM role ARN for Enhanced Monitoring"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Aurora MySQL log types to export to CloudWatch Logs"
  type        = list(string)
  default     = ["error", "slowquery"]

  validation {
    condition = alltrue([
      for log_type in var.enabled_cloudwatch_logs_exports :
      contains(
        ["audit", "error", "general", "slowquery"],
        log_type
      )
    ])
    error_message = "Supported Aurora MySQL log export values are audit, error, general and slowquery; verify availability for the selected engine version."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights where supported"
  type        = bool
  default     = true
}

variable "performance_insights_kms_key_id" {
  description = "Optional KMS key for Performance Insights"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "enable_http_endpoint" {
  description = "Enable the Aurora Data API where supported"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication where supported"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to Aurora MySQL resources"
  type        = map(string)
  default     = {}
}

variable "use_custom_parameter_groups" {
  description = "Whether to create custom cluster and instance parameter groups"
  type        = bool
  default     = true
}

variable "database_insights_mode" {
  description = "Database Insights mode: standard or advanced"
  type        = string
  default     = "standard"

  validation {
    condition = contains(
      ["standard", "advanced"],
      lower(var.database_insights_mode)
    )
    error_message = "database_insights_mode must be standard or advanced."
  }
}

variable "network_type" {
  description = "Network type for the Aurora MySQL cluster: IPV4 or DUAL"
  type        = string
  default     = "IPV4"

  validation {
    condition = contains(
      ["IPV4", "DUAL"],
      upper(var.network_type)
    )
    error_message = "network_type must be IPV4 or DUAL."
  }
}

variable "publicly_accessible" {
  description = "Whether Aurora MySQL DB instances should be publicly accessible"
  type        = bool
  default     = false
}

variable "allow_public_access" {
  description = "Explicitly permit public accessibility when organizational policy allows it"
  type        = bool
  default     = false
}
