
data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

locals {
  subnet_azs = [
    for subnet in data.aws_subnet.selected :
    subnet.availability_zone
  ]
}

resource "terraform_data" "validate_network" {
  input = {
    vpc_id     = var.vpc_id
    subnet_ids = var.subnet_ids
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.selected :
        subnet.vpc_id == var.vpc_id
      ])

      error_message = "All subnet_ids must belong to the VPC specified by vpc_id."
    }

    precondition {
      condition     = length(distinct(local.subnet_azs)) >= 2
      error_message = "The DB subnet group must include subnets in at least two distinct Availability Zones."
    }

    precondition {
      condition     = length(distinct(var.subnet_ids)) == length(var.subnet_ids)
      error_message = "subnet_ids must contain unique subnet IDs."
    }

    precondition {
      condition = (
        !var.enable_availability_zones ||
        length(var.availability_zones) == 0 ||
        (
          length(distinct(var.availability_zones)) == length(var.availability_zones) &&
          alltrue([
            for az in var.availability_zones :
            contains(local.subnet_azs, az)
          ])
        )
      )

      error_message = "When explicitly configured, availability_zones must be unique and must correspond to the supplied subnets."
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name        = local.subnet_group_name
  description = "Aurora MySQL DB subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = local.subnet_group_name
    }
  )

  depends_on = [
    terraform_data.validate_network
  ]
}
