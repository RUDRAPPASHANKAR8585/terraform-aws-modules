resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name = aws_eks_cluster.this.name

  addon_name = local.addon_names[each.key]

  addon_version = each.value.version


  configuration_values = (
    each.key == "vpc_cni"
    ? jsonencode({
      enableWindowsIpam = tostring(
        local.windows_nodes_enabled && var.enable_windows_ipam
      )

      env = {
        ENABLE_PREFIX_DELEGATION = tostring(
          var.vpc_cni_enable_prefix_delegation
        )

        WARM_PREFIX_TARGET = tostring(
          var.vpc_cni_warm_prefix_target
        )
      }
    })
    : each.key == "coredns"
    ? each.value.configuration_values
    : each.value.configuration_values
  )


  service_account_role_arn = (
    each.key == "ebs_csi" && each.value.service_account_role_arn == null
    ? aws_iam_role.ebs_csi[0].arn
    : each.key == "efs_csi" && each.value.service_account_role_arn == null
    ? aws_iam_role.efs_csi[0].arn
    : each.value.service_account_role_arn
  )

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.ebs_csi,
    aws_iam_role_policy_attachment.efs_csi
  ]
}