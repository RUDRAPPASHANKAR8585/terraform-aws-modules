
resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Aurora PostgreSQL access for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.source_security_group_id

  lifecycle {
    precondition {
      condition = (
        (try(each.value.cidr_ipv4, null) != null) !=
        (try(each.value.source_security_group_id, null) != null)
      )
      error_message = "Each ingress rule must specify exactly one CIDR or source security group ID."
    }
  }
}
