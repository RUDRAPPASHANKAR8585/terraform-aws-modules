/*
# Temporary Aurora MySQL module test inputs.
# Replace all example identifiers with your actual AWS resource IDs.
# Confirm the engine version is supported in ap-south-1 before planning.

name           = "dev-aurora-mysql-test"
engine_version = "8.0.mysql_aurora.3.08.2"

deployment_mode       = "provisioned"
instance_class        = "db.r7g.large"
reader_instance_class = null
reader_count          = 1

enable_availability_zones = true
availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

vpc_id = "vpc-09ccffec2c3bf59e1"

subnet_ids = [
  "subnet-021f7c17719bf5689",
  "subnet-0f350de5ccb05ea23",
  "subnet-0b61ab48db34e3df6"
]

ingress_rules = {}

database_name   = "devdb"
master_username = "dbadmin"

storage_encrypted = true
kms_key_id        = null
secret_kms_key_id = null
storage_type      = "aurora"

backup_retention_period      = 7
preferred_backup_window      = null
preferred_maintenance_window = null

deletion_protection        = false
skip_final_snapshot        = false
final_snapshot_identifier  = "dev-aurora-mysql-test-final"
apply_immediately          = false
auto_minor_version_upgrade = true

use_custom_parameter_groups       = true
enable_custom_cluster_parameters  = false
enable_custom_instance_parameters = false

cluster_parameters = {}

instance_parameters = {}

parameter_group_family = null

monitoring_interval = 60
monitoring_role_arn = null

enabled_cloudwatch_logs_exports = ["error", "slowquery"]

performance_insights_enabled          = true
performance_insights_kms_key_id       = null
performance_insights_retention_period = 7

enable_http_endpoint                = false
iam_database_authentication_enabled = false

#serverless_v2_min_capacity = 0.5
#serverless_v2_max_capacity = 2

database_insights_mode = "standard"
network_type           = "IPV4"

publicly_accessible = false
allow_public_access = false

tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}
*/