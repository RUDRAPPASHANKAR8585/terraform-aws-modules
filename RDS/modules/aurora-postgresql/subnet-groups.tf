
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

locals {
  subnet_azs = toset([
    for subnet in data.aws_subnet.selected :
    subnet.availability_zone
  ])
  /*
  subnet_vpc_ids = toset([
    for subnet in data.aws_subnet.selected :
    subnet.vpc_id
  ])
  */
}

resource "terraform_data" "validate_network" {
  input = var.subnet_ids

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.selected :
        subnet.vpc_id == var.vpc_id
      ])
      error_message = "All subnet IDs must belong to the supplied VPC."
    }

    precondition {
      condition     = length(local.subnet_azs) >= 2
      error_message = "Aurora PostgreSQL requires subnets spanning at least two Availability Zones."
    }

    precondition {
      condition = (
        length(var.subnet_ids) == length(distinct(var.subnet_ids))
      )
      error_message = "Subnet IDs must be unique. Remove duplicate subnet IDs."
    }

    precondition {
      condition = (
        length(var.availability_zones) == 0 ||
        (
          length(distinct(var.availability_zones)) ==
          length(var.availability_zones) &&
          alltrue([
            for az in var.availability_zones :
            contains(tolist(local.subnet_azs), az)
          ])
        )
      )
      error_message = "Specified Availability Zones must be unique and represented in the supplied subnet group."
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name        = local.subnet_group_name
  description = "Aurora PostgreSQL subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = local.subnet_group_name
  })

  depends_on = [terraform_data.validate_network]
}
