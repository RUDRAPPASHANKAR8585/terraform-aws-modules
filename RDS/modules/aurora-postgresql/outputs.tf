
output "cluster_identifier" {
  description = "Aurora PostgreSQL cluster identifier"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora PostgreSQL cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Cluster writer endpoint for read/write connections"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Cluster reader endpoint for read-only connections"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Aurora PostgreSQL port"
  value       = aws_rds_cluster.this.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master credentials secret"
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
}

output "writer_instance_id" {
  description = "Writer DB instance identifier"
  value       = aws_rds_cluster_instance.writer.id
}

output "reader_instance_ids" {
  description = "Reader DB instance identifiers"
  value       = [for reader in aws_rds_cluster_instance.reader : reader.id]
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.this.id
}

output "cluster_parameter_group_name" {
  description = "Name of the custom cluster parameter group, if created."
  value = (
    var.use_custom_parameter_groups
    ? aws_rds_cluster_parameter_group.this[0].name
    : null
  )
}

output "instance_parameter_group_name" {
  description = "Name of the custom instance parameter group, if created."
  value = (
    var.use_custom_parameter_groups
    ? aws_db_parameter_group.this[0].name
    : null
  )
}

output "parameter_group_family" {
  description = "Selected Aurora PostgreSQL parameter group family"
  value       = local.parameter_group_family
}
