
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

locals {
  subnet_azs = [
    for subnet in data.aws_subnet.selected :
    subnet.availability_zone
  ]

  subnet_vpc_ids = [
    for subnet in data.aws_subnet.selected :
    subnet.vpc_id
  ]

  subnet_group_name   = "${var.name}-subnets"
  security_group_name = "${var.name}-db-sg"
}

resource "terraform_data" "validate_subnets" {
  input = var.subnet_ids

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet_vpc_id in local.subnet_vpc_ids :
        subnet_vpc_id == var.vpc_id
      ])

      error_message = "All supplied subnets must belong to the selected VPC."
    }

    precondition {
      condition     = length(distinct(local.subnet_azs)) >= 2
      error_message = "Database subnets must span at least two Availability Zones."
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name        = local.subnet_group_name
  description = "Database subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = local.subnet_group_name
  })

  depends_on = [terraform_data.validate_subnets]
}

resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Database access for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = local.security_group_name
  })
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port

  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.source_security_group_id

  lifecycle {
    precondition {
      condition = (
        (try(each.value.cidr_ipv4, null) != null) !=
        (try(each.value.source_security_group_id, null) != null)
      )

      error_message = "Each ingress rule must specify exactly one IPv4 CIDR or source security group ID."
    }
  }
}
