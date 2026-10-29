/*
# ============================================================
# Aurora PostgreSQL - Development / Test POC
# Region is configured through the AWS provider, not this file.
# ============================================================

# --- Cluster identity and engine ---
name           = "dev-aurora-pg-test"
engine_version = "18.6"

# Provisioned options:
#   instance_class = "db.r7g.large"
#   reader_instance_class = null  # Uses writer class
#
# Serverless v2:
#   deployment_mode = "serverless_v2"
#   Writer and reader use db.serverless automatically.
#deployment_mode     = "provisioned" # provisioned | serverless_v2
deployment_mode       = "serverless_v2"
instance_class        = "db.r7g.large"
reader_instance_class = null

# Number of reader instances: 0-15.
# One writer is always created.
reader_count = 1

# Serverless v2 capacity (ACUs; increments of 0.5).
# Used only when deployment_mode = "serverless_v2".
serverless_v2_min_capacity = 0.5
serverless_v2_max_capacity = 2

# --- Existing network ---
vpc_id = "vpc-09ccffec2c3bf59e1"

subnet_ids = [
  "subnet-021f7c17719bf5689",
  "subnet-0f350de5ccb05ea23",
  "subnet-0b61ab48db34e3df6"
]

# true = explicitly provide AZs below.
# false = let AWS select AZs based on the subnet group.
enable_availability_zones = true

availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

# Approved database inbound rules.
# Empty means no ingress rules are supplied by this input.
# Add only approved application CIDRs or security group IDs.
ingress_rules = {}

# --- Database credentials ---
database_name   = "devdb"
master_username = "shankar"

# The master password is managed by RDS in Secrets Manager.
# Do not put the password in this file.

# --- Storage encryption ---
# true = enable storage encryption.
storage_encrypted = true

# null = use the AWS-managed default key where applicable.
# Supply a customer-managed KMS key ARN/ID when required.
kms_key_id        = null
secret_kms_key_id = null

# Storage type: aurora | aurora-iopt1
storage_type = "aurora"

# --- Backups and lifecycle ---
# Automated backup retention: 1-35 days.
backup_retention_period = 7

# null = use the AWS default maintenance/backup window.
preferred_backup_window      = null
preferred_maintenance_window = null

# true = prevent accidental cluster deletion.
deletion_protection = true

# false = require a final snapshot when deleting.
# A final snapshot identifier is therefore required.
skip_final_snapshot       = false
final_snapshot_identifier = "dev-aurora-pg-test-final-snapshot"

# true = apply eligible changes immediately.
# false = follow the service's normal maintenance/apply behavior.
apply_immediately = false

# true = allow automatic minor version upgrades.
auto_minor_version_upgrade = true

# --- Parameter groups ---
# true = create custom cluster and instance parameter groups.
use_custom_parameter_groups = true

# Enable these switches when supplying custom parameter maps.
enable_custom_cluster_parameters  = true
enable_custom_instance_parameters = true

# null = derive parameter group family from engine_version.
parameter_group_family = null

cluster_parameters = {
  "timezone" = {
    value        = "Asia/Kolkata"
    apply_method = "immediate"
  }
}

instance_parameters = {
  "log_min_duration_statement" = {
    value        = "1000"
    apply_method = "pending-reboot"
  }
}

# --- Enhanced Monitoring ---
# 0 = disabled; valid intervals: 1, 5, 10, 15, 30, 60 seconds.
monitoring_interval = 60

# null = let the module use its configured monitoring role behavior.
monitoring_role_arn = null

# --- CloudWatch database logs ---
# Supported by this module: postgresql, iam-db-auth-error.
enabled_cloudwatch_logs_exports = ["postgresql"]

# --- Performance Insights ---
performance_insights_enabled = true

# Optional customer-managed KMS key; null uses the service default.
performance_insights_kms_key_id = null

# Retention in days; 7 is the current POC setting.
# Advanced Database Insights requires Performance Insights
# enabled and retention of at least 465 days.
performance_insights_retention_period = 7

# Database Insights mode: standard | advanced
database_insights_mode = "standard"

# To use advanced mode, review the requirements above and set:
# database_insights_mode                = "advanced"
# performance_insights_enabled          = true
# performance_insights_retention_period = 465

# --- Network configuration ---
# IPV4 = IPv4 networking.
# DUAL = dual-stack networking, subject to AWS prerequisites.
network_type = "IPV4"

# --- Optional database features ---
# true = enable the Aurora Data API where supported.
enable_http_endpoint = false

# true = allow IAM database authentication.
iam_database_authentication_enabled = false

# --- Public accessibility ---
# Both must be true for DB instances to be publicly accessible.
# Keep both false for private application/database networking.
publicly_accessible = false
allow_public_access = false

# --- Resource tags ---
# Add/update tags according to your organization's standards.
tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}
*/