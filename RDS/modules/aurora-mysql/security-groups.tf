
resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Security group for Aurora MySQL cluster ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = local.security_group_name
    }
  )

  lifecycle {
    precondition {
      condition = alltrue([
        for rule in values(var.ingress_rules) :
        (
          (rule.cidr_ipv4 != null) !=
          (rule.source_security_group_id != null)
        )
      ])

      error_message = "Each ingress rule must specify exactly one of cidr_ipv4 or source_security_group_id."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id

  description = each.value.description
  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  cidr_ipv4 = each.value.cidr_ipv4

  referenced_security_group_id = (
    each.value.source_security_group_id
  )

  lifecycle {
    precondition {
      condition = (
        (each.value.cidr_ipv4 != null) !=
        (each.value.source_security_group_id != null)
      )

      error_message = "Specify exactly one source per ingress rule: cidr_ipv4 or source_security_group_id."
    }
  }
}
