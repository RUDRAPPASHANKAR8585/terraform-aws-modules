# Root Outputs - Aurora PostgreSQL

output "aurora_postgresql_cluster_identifier" {
  description = "Aurora PostgreSQL cluster identifier"
  value       = try(module.aurora_postgresql[0].cluster_identifier, null)
}

output "aurora_postgresql_cluster_endpoint" {
  description = "Aurora PostgreSQL writer endpoint"
  value       = try(module.aurora_postgresql[0].cluster_endpoint, null)
}

output "aurora_postgresql_reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint"
  value       = try(module.aurora_postgresql[0].reader_endpoint, null)
}

output "aurora_postgresql_cluster_arn" {
  description = "Aurora PostgreSQL cluster ARN"
  value       = try(module.aurora_postgresql[0].cluster_arn, null)
}


# Root Outputs - Aurora MySQL

output "aurora_mysql_cluster_identifier" {
  description = "Aurora MySQL cluster identifier"
  value       = try(module.aurora_mysql[0].cluster_identifier, null)
}

output "aurora_mysql_cluster_arn" {
  description = "Aurora MySQL cluster ARN"
  value       = try(module.aurora_mysql[0].cluster_arn, null)
}

output "aurora_mysql_cluster_endpoint" {
  description = "Aurora MySQL writer endpoint"
  value       = try(module.aurora_mysql[0].cluster_endpoint, null)
}

output "aurora_mysql_reader_endpoint" {
  description = "Aurora MySQL reader endpoint"
  value       = try(module.aurora_mysql[0].reader_endpoint, null)
}

output "aurora_mysql_port" {
  description = "Aurora MySQL database port"
  value       = try(module.aurora_mysql[0].port, null)
}

output "aurora_mysql_master_user_secret_arn" {
  description = "Aurora MySQL master credentials secret ARN"
  value       = try(module.aurora_mysql[0].master_user_secret_arn, null)
}

output "aurora_mysql_writer_instance_id" {
  description = "Aurora MySQL writer instance ID"
  value       = try(module.aurora_mysql[0].writer_instance_id, null)
}

output "aurora_mysql_reader_instance_ids" {
  description = "Aurora MySQL reader instance IDs"
  value       = try(module.aurora_mysql[0].reader_instance_ids, [])
}

output "aurora_mysql_db_subnet_group_name" {
  description = "Aurora MySQL DB subnet group name"
  value       = try(module.aurora_mysql[0].db_subnet_group_name, null)
}

output "aurora_mysql_db_security_group_id" {
  description = "Aurora MySQL security group ID"
  value       = try(module.aurora_mysql[0].db_security_group_id, null)
}

output "aurora_mysql_cluster_parameter_group_name" {
  description = "Aurora MySQL cluster parameter group name"
  value       = try(module.aurora_mysql[0].cluster_parameter_group_name, null)
}

output "aurora_mysql_instance_parameter_group_name" {
  description = "Aurora MySQL instance parameter group name"
  value       = try(module.aurora_mysql[0].instance_parameter_group_name, null)
}

output "aurora_mysql_parameter_group_family" {
  description = "Aurora MySQL parameter group family"
  value       = try(module.aurora_mysql[0].parameter_group_family, null)
}