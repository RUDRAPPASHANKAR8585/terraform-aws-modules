
# ============================================================
# Root Variables - Aurora PostgreSQL
# Other database modules will have their own variable groups.
# ============================================================

# --- Cluster identity and engine ---

variable "aurora_postgresql_name" {
  description = "Aurora PostgreSQL cluster identifier"
  type        = string
}

variable "aurora_postgresql_engine_version" {
  description = "Aurora PostgreSQL engine version, for example 18.6"
  type        = string
}

# --- Deployment mode and instances ---

variable "aurora_postgresql_deployment_mode" {
  description = "Deployment mode: provisioned or serverless_v2"
  type        = string
  default     = "provisioned"

  validation {
    condition = contains(
      ["provisioned", "serverless_v2"],
      lower(var.aurora_postgresql_deployment_mode)
    )
    error_message = "Choose provisioned or serverless_v2."
  }
}

variable "aurora_postgresql_instance_class" {
  description = "Writer instance class for provisioned deployments"
  type        = string
  default     = "db.r7g.large"
}

variable "aurora_postgresql_reader_instance_class" {
  description = "Optional reader instance class; null uses the writer class"
  type        = string
  default     = null
}

variable "aurora_postgresql_reader_count" {
  description = "Number of reader instances; valid range is 0-15"
  type        = number
  default     = 1
}

variable "aurora_postgresql_serverless_v2_min_capacity" {
  description = "Minimum Serverless v2 capacity in ACUs"
  type        = number
  default     = 0.5
}

variable "aurora_postgresql_serverless_v2_max_capacity" {
  description = "Maximum Serverless v2 capacity in ACUs"
  type        = number
  default     = 2
}

# --- Network ---

variable "aurora_postgresql_vpc_id" {
  description = "Existing VPC ID for Aurora PostgreSQL"
  type        = string
}

variable "aurora_postgresql_subnet_ids" {
  description = "Existing subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition = (
      length(var.aurora_postgresql_subnet_ids) >= 2 &&
      length(distinct(var.aurora_postgresql_subnet_ids)) ==
      length(var.aurora_postgresql_subnet_ids)
    )
    error_message = "Provide at least two unique subnet IDs."
  }
}

variable "aurora_postgresql_enable_availability_zones" {
  description = "Whether to explicitly configure cluster availability zones"
  type        = bool
  default     = false
}

variable "aurora_postgresql_availability_zones" {
  description = "Availability zones to use when explicitly enabled"
  type        = list(string)
  default     = []
}

variable "aurora_postgresql_ingress_rules" {
  description = "Approved inbound database access rules"
  type = map(object({
    description              = string
    cidr_ipv4                = optional(string)
    source_security_group_id = optional(string)
  }))
  default = {}
}

# --- Database ---

variable "aurora_postgresql_database_name" {
  description = "Optional initial database name"
  type        = string
  default     = null
}

variable "aurora_postgresql_master_username" {
  description = "Master username; password is managed by RDS in Secrets Manager"
  type        = string
  default     = "dbadmin"
}

# --- Encryption and storage ---

variable "aurora_postgresql_storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "aurora_postgresql_kms_key_id" {
  description = "Optional customer-managed KMS key for cluster storage"
  type        = string
  default     = null
}

variable "aurora_postgresql_secret_kms_key_id" {
  description = "Optional KMS key for the RDS-managed master secret"
  type        = string
  default     = null
}

variable "aurora_postgresql_storage_type" {
  description = "Aurora storage type: aurora or aurora-iopt1"
  type        = string
  default     = "aurora"

  validation {
    condition = contains(
      ["aurora", "aurora-iopt1"],
      var.aurora_postgresql_storage_type
    )
    error_message = "Choose aurora or aurora-iopt1."
  }
}

# --- Backups and lifecycle ---

variable "aurora_postgresql_backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "aurora_postgresql_preferred_backup_window" {
  description = "Optional daily backup window in UTC"
  type        = string
  default     = null
}

variable "aurora_postgresql_preferred_maintenance_window" {
  description = "Optional weekly maintenance window in UTC"
  type        = string
  default     = null
}

variable "aurora_postgresql_deletion_protection" {
  description = "Prevent accidental cluster deletion"
  type        = bool
  default     = true
}

variable "aurora_postgresql_skip_final_snapshot" {
  description = "Whether to skip the final snapshot during deletion"
  type        = bool
  default     = false
}

variable "aurora_postgresql_final_snapshot_identifier" {
  description = "Final snapshot identifier when snapshot creation is enabled"
  type        = string
  default     = null
}

variable "aurora_postgresql_apply_immediately" {
  description = "Apply eligible modifications immediately"
  type        = bool
  default     = false
}

variable "aurora_postgresql_auto_minor_version_upgrade" {
  description = "Enable automatic minor engine version upgrades"
  type        = bool
  default     = true
}

# --- Parameter groups ---

variable "aurora_postgresql_use_custom_parameter_groups" {
  description = "Create custom cluster and instance parameter groups"
  type        = bool
  default     = true
}

variable "aurora_postgresql_enable_custom_cluster_parameters" {
  description = "Enable supplied cluster parameter overrides"
  type        = bool
  default     = false
}

variable "aurora_postgresql_enable_custom_instance_parameters" {
  description = "Enable supplied instance parameter overrides"
  type        = bool
  default     = false
}

variable "aurora_postgresql_parameter_group_family" {
  description = "Optional parameter group family; null derives it from engine version"
  type        = string
  default     = null
}

variable "aurora_postgresql_cluster_parameters" {
  description = "Custom Aurora cluster parameter overrides"
  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = {}
}

variable "aurora_postgresql_instance_parameters" {
  description = "Custom Aurora instance parameter overrides"
  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = {}
}

# --- Enhanced Monitoring and logs ---

variable "aurora_postgresql_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds; 0 disables it"
  type        = number
  default     = 60
}

variable "aurora_postgresql_monitoring_role_arn" {
  description = "Optional existing Enhanced Monitoring IAM role ARN"
  type        = string
  default     = null
}

variable "aurora_postgresql_enabled_cloudwatch_logs_exports" {
  description = "Aurora PostgreSQL log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

# --- Performance Insights and Database Insights ---

variable "aurora_postgresql_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "aurora_postgresql_performance_insights_kms_key_id" {
  description = "Optional KMS key for Performance Insights"
  type        = string
  default     = null
}

variable "aurora_postgresql_performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "aurora_postgresql_database_insights_mode" {
  description = "Database Insights mode: standard or advanced"
  type        = string
  default     = "standard"

  validation {
    condition = contains(
      ["standard", "advanced"],
      lower(var.aurora_postgresql_database_insights_mode)
    )
    error_message = "Choose standard or advanced."
  }
}

# --- Network and optional features ---

variable "aurora_postgresql_network_type" {
  description = "Network type: IPV4 or DUAL"
  type        = string
  default     = "IPV4"

  validation {
    condition = contains(
      ["IPV4", "DUAL"],
      upper(var.aurora_postgresql_network_type)
    )
    error_message = "Choose IPV4 or DUAL."
  }
}

variable "aurora_postgresql_publicly_accessible" {
  description = "Request public accessibility for DB instances"
  type        = bool
  default     = false
}

variable "aurora_postgresql_allow_public_access" {
  description = "Explicit safety approval for public accessibility"
  type        = bool
  default     = false
}

variable "aurora_postgresql_enable_http_endpoint" {
  description = "Enable the Aurora Data API where supported"
  type        = bool
  default     = false
}

variable "aurora_postgresql_iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# --- Tags ---

variable "aurora_postgresql_tags" {
  description = "Tags to apply to Aurora PostgreSQL resources"
  type        = map(string)
  default     = {}
}

variable "enable_aurora_postgresql" {
  description = "Enable Aurora PostgreSQL deployment"
  type        = bool
  default     = false
}


# ============================================================
# Root Variables - Aurora MySQL
# ============================================================

# --- Cluster identity and engine ---

variable "aurora_mysql_name" {
  description = "Aurora MySQL cluster identifier"
  type        = string
}

variable "aurora_mysql_engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
}

# --- Deployment mode and instances ---

variable "aurora_mysql_deployment_mode" {
  description = "Deployment mode: provisioned or serverless_v2"
  type        = string
  default     = "provisioned"

  validation {
    condition = contains(
      ["provisioned", "serverless_v2"],
      lower(var.aurora_mysql_deployment_mode)
    )
    error_message = "Choose provisioned or serverless_v2."
  }
}

variable "aurora_mysql_instance_class" {
  description = "Writer instance class for provisioned deployments"
  type        = string
  default     = "db.r7g.large"
}

variable "aurora_mysql_reader_instance_class" {
  description = "Optional reader instance class; null uses the writer class"
  type        = string
  default     = null
}

variable "aurora_mysql_reader_count" {
  description = "Number of reader instances; valid range is 0-15"
  type        = number
  default     = 1

  validation {
    condition = (
      var.aurora_mysql_reader_count >= 0 &&
      var.aurora_mysql_reader_count <= 15 &&
      var.aurora_mysql_reader_count == floor(var.aurora_mysql_reader_count)
    )
    error_message = "Reader count must be an integer between 0 and 15."
  }
}

variable "aurora_mysql_serverless_min_capacity" {
  description = "Minimum Serverless v2 capacity in ACUs"
  type        = number
  default     = 0.5
}

variable "aurora_mysql_serverless_max_capacity" {
  description = "Maximum Serverless v2 capacity in ACUs"
  type        = number
  default     = 2
}

# --- Network ---

variable "aurora_mysql_vpc_id" {
  description = "Existing VPC ID for Aurora MySQL"
  type        = string
}

variable "aurora_mysql_subnet_ids" {
  description = "Existing subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition = (
      length(var.aurora_mysql_subnet_ids) >= 2 &&
      length(distinct(var.aurora_mysql_subnet_ids)) ==
      length(var.aurora_mysql_subnet_ids)
    )
    error_message = "Provide at least two unique subnet IDs."
  }
}

variable "aurora_mysql_enable_availability_zones" {
  description = "Whether to explicitly configure cluster Availability Zones"
  type        = bool
  default     = false
}

variable "aurora_mysql_availability_zones" {
  description = "Availability Zones to use when explicitly enabled"
  type        = list(string)
  default     = []
}

variable "aurora_mysql_ingress_rules" {
  description = "Approved inbound MySQL database access rules"
  type = map(object({
    description              = string
    cidr_ipv4                = optional(string)
    source_security_group_id = optional(string)
  }))
  default = {}
}

# --- Database ---

variable "aurora_mysql_database_name" {
  description = "Optional initial database name"
  type        = string
  default     = null
}

variable "aurora_mysql_master_username" {
  description = "Master username; password is managed by RDS in Secrets Manager"
  type        = string
  default     = "dbadmin"
}

# --- Encryption and storage ---

variable "aurora_mysql_storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "aurora_mysql_kms_key_id" {
  description = "Optional customer-managed KMS key for cluster storage"
  type        = string
  default     = null
}

variable "aurora_mysql_secret_kms_key_id" {
  description = "Optional KMS key for the RDS-managed master secret"
  type        = string
  default     = null
}

variable "aurora_mysql_storage_type" {
  description = "Aurora storage type: aurora or aurora-iopt1"
  type        = string
  default     = "aurora"

  validation {
    condition = contains(
      ["aurora", "aurora-iopt1"],
      var.aurora_mysql_storage_type
    )
    error_message = "Choose aurora or aurora-iopt1."
  }
}

# --- Backups and lifecycle ---

variable "aurora_mysql_backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "aurora_mysql_preferred_backup_window" {
  description = "Optional daily backup window in UTC"
  type        = string
  default     = null
}

variable "aurora_mysql_preferred_maintenance_window" {
  description = "Optional weekly maintenance window in UTC"
  type        = string
  default     = null
}

variable "aurora_mysql_deletion_protection" {
  description = "Prevent accidental cluster deletion"
  type        = bool
  default     = true
}

variable "aurora_mysql_skip_final_snapshot" {
  description = "Whether to skip the final snapshot during deletion"
  type        = bool
  default     = false
}

variable "aurora_mysql_final_snapshot_identifier" {
  description = "Final snapshot identifier when snapshot creation is enabled"
  type        = string
  default     = null
}

variable "aurora_mysql_apply_immediately" {
  description = "Apply eligible modifications immediately"
  type        = bool
  default     = false
}

variable "aurora_mysql_auto_minor_version_upgrade" {
  description = "Enable automatic minor engine version upgrades"
  type        = bool
  default     = true
}

# --- Parameter groups ---

variable "aurora_mysql_use_custom_parameter_groups" {
  description = "Create custom cluster and instance parameter groups"
  type        = bool
  default     = true
}

variable "aurora_mysql_enable_custom_cluster_parameters" {
  description = "Enable supplied cluster parameter overrides"
  type        = bool
  default     = false
}

variable "aurora_mysql_enable_custom_instance_parameters" {
  description = "Enable supplied instance parameter overrides"
  type        = bool
  default     = false
}

variable "aurora_mysql_parameter_group_family" {
  description = "Optional parameter group family; null derives it from engine version"
  type        = string
  default     = null
}

variable "aurora_mysql_cluster_parameters" {
  description = "Custom Aurora MySQL cluster parameter overrides"
  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = {}
}

variable "aurora_mysql_instance_parameters" {
  description = "Custom Aurora MySQL instance parameter overrides"
  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = {}
}

# --- Enhanced Monitoring and logs ---

variable "aurora_mysql_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds; 0 disables it"
  type        = number
  default     = 60
}

variable "aurora_mysql_monitoring_role_arn" {
  description = "Optional existing Enhanced Monitoring IAM role ARN"
  type        = string
  default     = null
}

variable "aurora_mysql_enabled_cloudwatch_logs_exports" {
  description = "Aurora MySQL log types to export to CloudWatch"
  type        = list(string)
  default     = ["error", "slowquery"]

  validation {
    condition = alltrue([
      for log_type in var.aurora_mysql_enabled_cloudwatch_logs_exports :
      contains(["audit", "error", "general", "slowquery"], log_type)
    ])
    error_message = "Supported log types are audit, error, general, and slowquery."
  }
}

# --- Performance Insights and Database Insights ---

variable "aurora_mysql_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "aurora_mysql_performance_insights_kms_key_id" {
  description = "Optional KMS key for Performance Insights"
  type        = string
  default     = null
}

variable "aurora_mysql_performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "aurora_mysql_database_insights_mode" {
  description = "Database Insights mode: standard or advanced"
  type        = string
  default     = "standard"

  validation {
    condition = contains(
      ["standard", "advanced"],
      lower(var.aurora_mysql_database_insights_mode)
    )
    error_message = "Choose standard or advanced."
  }
}

# --- Network and optional features ---

variable "aurora_mysql_network_type" {
  description = "Network type: IPV4 or DUAL"
  type        = string
  default     = "IPV4"

  validation {
    condition = contains(
      ["IPV4", "DUAL"],
      upper(var.aurora_mysql_network_type)
    )
    error_message = "Choose IPV4 or DUAL."
  }
}

variable "aurora_mysql_publicly_accessible" {
  description = "Request public accessibility for DB instances"
  type        = bool
  default     = false
}

variable "aurora_mysql_allow_public_access" {
  description = "Explicit safety approval for public accessibility"
  type        = bool
  default     = false
}

variable "aurora_mysql_enable_http_endpoint" {
  description = "Enable the Aurora HTTP endpoint where supported"
  type        = bool
  default     = false
}

variable "aurora_mysql_iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# --- Tags ---

variable "aurora_mysql_tags" {
  description = "Tags to apply to Aurora MySQL resources"
  type        = map(string)
  default     = {}
}

# --- Deployment control ---

variable "enable_aurora_mysql" {
  description = "Whether to deploy Aurora MySQL"
  type        = bool
  default     = false
}

