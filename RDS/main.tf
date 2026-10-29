
# ============================================================
# Root Module - AWS RDS
# Currently integrated: Aurora PostgreSQL
# Future integrations: Aurora MySQL, MySQL, PostgreSQL, Oracle
# ============================================================

module "aurora_postgresql" {
  count  = var.enable_aurora_postgresql ? 1 : 0
  source = "./modules/aurora-postgresql"

  # Cluster
  name           = var.aurora_postgresql_name
  engine_version = var.aurora_postgresql_engine_version

  # Deployment mode and instances
  deployment_mode       = var.aurora_postgresql_deployment_mode
  instance_class        = var.aurora_postgresql_instance_class
  reader_instance_class = var.aurora_postgresql_reader_instance_class
  reader_count          = var.aurora_postgresql_reader_count

  # Network
  vpc_id                    = var.aurora_postgresql_vpc_id
  subnet_ids                = var.aurora_postgresql_subnet_ids
  enable_availability_zones = var.aurora_postgresql_enable_availability_zones
  availability_zones        = var.aurora_postgresql_availability_zones
  ingress_rules             = var.aurora_postgresql_ingress_rules

  # Database
  database_name   = var.aurora_postgresql_database_name
  master_username = var.aurora_postgresql_master_username

  # Encryption and storage
  storage_encrypted = var.aurora_postgresql_storage_encrypted
  kms_key_id        = var.aurora_postgresql_kms_key_id
  secret_kms_key_id = var.aurora_postgresql_secret_kms_key_id
  storage_type      = var.aurora_postgresql_storage_type

  # Serverless v2 capacity
  serverless_v2_min_capacity = var.aurora_postgresql_serverless_v2_min_capacity
  serverless_v2_max_capacity = var.aurora_postgresql_serverless_v2_max_capacity

  # Backups and lifecycle
  backup_retention_period = (
    var.aurora_postgresql_backup_retention_period
  )
  preferred_backup_window = (
    var.aurora_postgresql_preferred_backup_window
  )
  preferred_maintenance_window = (
    var.aurora_postgresql_preferred_maintenance_window
  )
  deletion_protection = var.aurora_postgresql_deletion_protection
  skip_final_snapshot = var.aurora_postgresql_skip_final_snapshot
  final_snapshot_identifier = (
    var.aurora_postgresql_final_snapshot_identifier
  )
  apply_immediately = var.aurora_postgresql_apply_immediately
  auto_minor_version_upgrade = (
    var.aurora_postgresql_auto_minor_version_upgrade
  )

  # Parameter groups
  use_custom_parameter_groups = (
    var.aurora_postgresql_use_custom_parameter_groups
  )
  enable_custom_cluster_parameters = (
    var.aurora_postgresql_enable_custom_cluster_parameters
  )
  enable_custom_instance_parameters = (
    var.aurora_postgresql_enable_custom_instance_parameters
  )
  parameter_group_family = (
    var.aurora_postgresql_parameter_group_family
  )
  cluster_parameters  = var.aurora_postgresql_cluster_parameters
  instance_parameters = var.aurora_postgresql_instance_parameters

  # Enhanced Monitoring and CloudWatch logs
  monitoring_interval = var.aurora_postgresql_monitoring_interval
  monitoring_role_arn = var.aurora_postgresql_monitoring_role_arn
  enabled_cloudwatch_logs_exports = (
    var.aurora_postgresql_enabled_cloudwatch_logs_exports
  )

  # Performance Insights and Database Insights
  performance_insights_enabled = (
    var.aurora_postgresql_performance_insights_enabled
  )
  performance_insights_kms_key_id = (
    var.aurora_postgresql_performance_insights_kms_key_id
  )
  performance_insights_retention_period = (
    var.aurora_postgresql_performance_insights_retention_period
  )
  database_insights_mode = var.aurora_postgresql_database_insights_mode

  # Network and optional features
  network_type = var.aurora_postgresql_network_type
  publicly_accessible = (
    var.aurora_postgresql_publicly_accessible
  )
  allow_public_access = (
    var.aurora_postgresql_allow_public_access
  )
  enable_http_endpoint = (
    var.aurora_postgresql_enable_http_endpoint
  )
  iam_database_authentication_enabled = (
    var.aurora_postgresql_iam_database_authentication_enabled
  )

  # Tags
  tags = var.aurora_postgresql_tags
}



# ============================================================
# Root Module - Aurora MySQL
# ============================================================

module "aurora_mysql" {
  count  = var.enable_aurora_mysql ? 1 : 0
  source = "./modules/aurora-mysql"

  # Cluster
  name           = var.aurora_mysql_name
  engine_version = var.aurora_mysql_engine_version

  # Deployment mode and instances
  deployment_mode       = var.aurora_mysql_deployment_mode
  instance_class        = var.aurora_mysql_instance_class
  reader_instance_class = var.aurora_mysql_reader_instance_class
  reader_count          = var.aurora_mysql_reader_count

  # Network
  vpc_id                    = var.aurora_mysql_vpc_id
  subnet_ids                = var.aurora_mysql_subnet_ids
  enable_availability_zones = var.aurora_mysql_enable_availability_zones
  availability_zones        = var.aurora_mysql_availability_zones
  ingress_rules             = var.aurora_mysql_ingress_rules

  # Database
  database_name   = var.aurora_mysql_database_name
  master_username = var.aurora_mysql_master_username

  # Encryption and storage
  storage_encrypted = var.aurora_mysql_storage_encrypted
  kms_key_id        = var.aurora_mysql_kms_key_id
  secret_kms_key_id = var.aurora_mysql_secret_kms_key_id
  storage_type      = var.aurora_mysql_storage_type

  # Backups and lifecycle
  backup_retention_period = (
    var.aurora_mysql_backup_retention_period
  )
  preferred_backup_window = (
    var.aurora_mysql_preferred_backup_window
  )
  preferred_maintenance_window = (
    var.aurora_mysql_preferred_maintenance_window
  )
  deletion_protection = var.aurora_mysql_deletion_protection
  skip_final_snapshot = var.aurora_mysql_skip_final_snapshot
  final_snapshot_identifier = (
    var.aurora_mysql_final_snapshot_identifier
  )
  apply_immediately = var.aurora_mysql_apply_immediately
  auto_minor_version_upgrade = (
    var.aurora_mysql_auto_minor_version_upgrade
  )

  # Parameter groups
  use_custom_parameter_groups = (
    var.aurora_mysql_use_custom_parameter_groups
  )
  enable_custom_cluster_parameters = (
    var.aurora_mysql_enable_custom_cluster_parameters
  )
  enable_custom_instance_parameters = (
    var.aurora_mysql_enable_custom_instance_parameters
  )
  parameter_group_family = (
    var.aurora_mysql_parameter_group_family
  )
  cluster_parameters  = var.aurora_mysql_cluster_parameters
  instance_parameters = var.aurora_mysql_instance_parameters

  # Enhanced Monitoring and CloudWatch logs
  monitoring_interval = var.aurora_mysql_monitoring_interval
  monitoring_role_arn = var.aurora_mysql_monitoring_role_arn
  enabled_cloudwatch_logs_exports = (
    var.aurora_mysql_enabled_cloudwatch_logs_exports
  )

  # Performance Insights and Database Insights
  performance_insights_enabled = (
    var.aurora_mysql_performance_insights_enabled
  )
  performance_insights_kms_key_id = (
    var.aurora_mysql_performance_insights_kms_key_id
  )
  performance_insights_retention_period = (
    var.aurora_mysql_performance_insights_retention_period
  )
  database_insights_mode = var.aurora_mysql_database_insights_mode

  # Network and optional features
  network_type = var.aurora_mysql_network_type
  publicly_accessible = (
    var.aurora_mysql_publicly_accessible
  )
  allow_public_access = (
    var.aurora_mysql_allow_public_access
  )
  enable_http_endpoint = (
    var.aurora_mysql_enable_http_endpoint
  )
  iam_database_authentication_enabled = (
    var.aurora_mysql_iam_database_authentication_enabled
  )

  # Tags
  tags = var.aurora_mysql_tags
}

