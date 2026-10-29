
# ============================================================
# Root Inputs - Aurora PostgreSQL Development/Test POC
# AWS Region: ap-south-1 (Mumbai)
# ============================================================

# --- Cluster and engine ---

enable_aurora_postgresql = false
aurora_postgresql_name           = "dev-aurora-pg-test"
aurora_postgresql_engine_version = "18.6"

# --- Deployment and instances ---
aurora_postgresql_deployment_mode       = "serverless_v2"
aurora_postgresql_instance_class        = "db.r7g.large"
aurora_postgresql_reader_instance_class = null
aurora_postgresql_reader_count          = 1

aurora_postgresql_serverless_v2_min_capacity = 0.5
aurora_postgresql_serverless_v2_max_capacity = 2

# --- Network ---
aurora_postgresql_vpc_id = "vpc-09ccffec2c3bf59e1"

aurora_postgresql_subnet_ids = [
  "subnet-021f7c17719bf5689",
  "subnet-0f350de5ccb05ea23",
  "subnet-0b61ab48db34e3df6"
]

aurora_postgresql_enable_availability_zones = true

aurora_postgresql_availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

# No inbound access rules for this POC.
# Add only approved application sources when required.
aurora_postgresql_ingress_rules = {}

# --- Database ---
aurora_postgresql_database_name   = "devdb"
aurora_postgresql_master_username = "shankar"

# --- Encryption and storage ---
aurora_postgresql_storage_encrypted = true
aurora_postgresql_kms_key_id        = null
aurora_postgresql_secret_kms_key_id = null
aurora_postgresql_storage_type      = "aurora"

# --- Backups and lifecycle ---
aurora_postgresql_backup_retention_period      = 7
aurora_postgresql_preferred_backup_window      = null
aurora_postgresql_preferred_maintenance_window = null

aurora_postgresql_deletion_protection       = false
aurora_postgresql_skip_final_snapshot       = false
aurora_postgresql_final_snapshot_identifier = "dev-aurora-pg-test-final-snapshot"

aurora_postgresql_apply_immediately          = false
aurora_postgresql_auto_minor_version_upgrade = true

# --- Parameter groups ---
aurora_postgresql_use_custom_parameter_groups       = true
aurora_postgresql_enable_custom_cluster_parameters  = true
aurora_postgresql_enable_custom_instance_parameters = true
aurora_postgresql_parameter_group_family            = null

aurora_postgresql_cluster_parameters = {
  timezone = {
    value        = "Asia/Kolkata"
    apply_method = "immediate"
  }
}

aurora_postgresql_instance_parameters = {
  log_min_duration_statement = {
    value        = "1000"
    apply_method = "pending-reboot"
  }
}

# --- Enhanced Monitoring and CloudWatch logs ---
aurora_postgresql_monitoring_interval = 60
aurora_postgresql_monitoring_role_arn = null

aurora_postgresql_enabled_cloudwatch_logs_exports = [
  "postgresql"
]

# --- Performance Insights and Database Insights ---
aurora_postgresql_performance_insights_enabled          = true
aurora_postgresql_performance_insights_kms_key_id       = null
aurora_postgresql_performance_insights_retention_period = 7
aurora_postgresql_database_insights_mode                = "standard"

# --- Network options ---
aurora_postgresql_network_type        = "IPV4"
aurora_postgresql_publicly_accessible = false
aurora_postgresql_allow_public_access = false

# --- Optional database features ---
aurora_postgresql_enable_http_endpoint                = false
aurora_postgresql_iam_database_authentication_enabled = false

# --- Tags ---
aurora_postgresql_tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}



# Root terraform.tfvars — Aurora MySQL test inputs

# Enable Aurora MySQL
enable_aurora_mysql = true

# Cluster configuration
aurora_mysql_name           = "dev-aurora-mysql-test"
aurora_mysql_engine_version = "8.0.mysql_aurora.3.08.2"

aurora_mysql_deployment_mode       = "provisioned"
aurora_mysql_instance_class        = "db.r7g.large"
aurora_mysql_reader_instance_class = null
aurora_mysql_reader_count          = 1

# Network configuration
aurora_mysql_enable_availability_zones = true

aurora_mysql_availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

aurora_mysql_vpc_id = "vpc-09ccffec2c3bf59e1"

aurora_mysql_subnet_ids = [
  "subnet-021f7c17719bf5689",
  "subnet-0f350de5ccb05ea23",
  "subnet-0b61ab48db34e3df6"
]

aurora_mysql_ingress_rules = {}

# Database configuration
aurora_mysql_database_name   = "devdb"
aurora_mysql_master_username = "dbadmin"

# Encryption and storage
aurora_mysql_storage_encrypted = true
aurora_mysql_kms_key_id        = null
aurora_mysql_secret_kms_key_id = null
aurora_mysql_storage_type      = "aurora"

# Backup and maintenance
aurora_mysql_backup_retention_period      = 7
aurora_mysql_preferred_backup_window      = null
aurora_mysql_preferred_maintenance_window = null

# Deletion and update settings
aurora_mysql_deletion_protection        = false
aurora_mysql_skip_final_snapshot        = false
aurora_mysql_final_snapshot_identifier  = "dev-aurora-mysql-test-final"
aurora_mysql_apply_immediately          = false
aurora_mysql_auto_minor_version_upgrade = true

# Parameter groups
aurora_mysql_use_custom_parameter_groups        = true
aurora_mysql_enable_custom_cluster_parameters   = false
aurora_mysql_enable_custom_instance_parameters  = false

aurora_mysql_cluster_parameters  = {}
aurora_mysql_instance_parameters = {}

aurora_mysql_parameter_group_family = null

# Enhanced monitoring
aurora_mysql_monitoring_interval = 60
aurora_mysql_monitoring_role_arn = null

# CloudWatch logs
aurora_mysql_enabled_cloudwatch_logs_exports = [
  "error",
  "slowquery"
]

# Performance Insights
aurora_mysql_performance_insights_enabled          = true
aurora_mysql_performance_insights_kms_key_id       = null
aurora_mysql_performance_insights_retention_period = 7

# Database Insights
aurora_mysql_database_insights_mode = "standard"

# Network access
aurora_mysql_network_type           = "IPV4"
aurora_mysql_publicly_accessible    = false
aurora_mysql_allow_public_access    = false

# Additional features
aurora_mysql_enable_http_endpoint                = false
aurora_mysql_iam_database_authentication_enabled = false

# Serverless capacity settings — not used for provisioned mode
# aurora_mysql_serverless_min_capacity = 0.5
# aurora_mysql_serverless_max_capacity = 2

# Tags
aurora_mysql_tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}
