
output "cluster_identifier" {
  description = "Aurora MySQL cluster identifier"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the Aurora MySQL cluster"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora MySQL cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint of the Aurora MySQL cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Port used by the Aurora MySQL cluster"
  value       = aws_rds_cluster.this.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master user secret"
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
}

output "writer_instance_id" {
  description = "Identifier of the Aurora MySQL writer instance"
  value       = aws_rds_cluster_instance.writer.id
}

output "reader_instance_ids" {
  description = "Identifiers of the Aurora MySQL reader instances"
  value       = [for instance in aws_rds_cluster_instance.reader : instance.id]
}

output "db_subnet_group_name" {
  description = "Name of the Aurora MySQL DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "ID of the Aurora MySQL security group"
  value       = aws_security_group.this.id
}

output "cluster_parameter_group_name" {
  description = "Name of the custom cluster parameter group, if created"
  value       = try(aws_rds_cluster_parameter_group.this[0].name, null)
}

output "instance_parameter_group_name" {
  description = "Name of the custom DB instance parameter group, if created"
  value       = try(aws_db_parameter_group.this[0].name, null)
}

output "parameter_group_family" {
  description = "Aurora MySQL parameter group family selected for the module"
  value       = local.parameter_group_family
}
