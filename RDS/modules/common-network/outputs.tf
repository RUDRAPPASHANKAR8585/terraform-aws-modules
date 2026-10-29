
output "db_subnet_group_name" {
  description = "Created DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "db_security_group_id" {
  description = "Created database security group ID"
  value       = aws_security_group.this.id
}

output "db_security_group_arn" {
  description = "Created database security group ARN"
  value       = aws_security_group.this.arn
}
