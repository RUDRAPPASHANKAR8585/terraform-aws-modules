
resource "aws_wafv2_ip_set" "this" {
  for_each = local.active_ip_sets

  name               = each.value.name
  description        = "IP set managed by Terraform for ${var.name}"
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = {
    Name      = each.value.name
    ManagedBy = "Terraform"
  }
}
