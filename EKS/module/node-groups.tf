resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key

  node_role_arn = aws_iam_role.node.arn

  subnet_ids = coalesce(
    each.value.subnet_ids,
    var.subnet_ids
  )

  ami_type        = each.value.ami_type
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  release_version = each.value.release_version

  disk_size = each.value.disk_size

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.cluster_name}-${each.key}"
      NodeGroup = each.key
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_ecr
  ]
}

resource "aws_autoscaling_group_tag" "node_instance_name" {
  for_each = aws_eks_node_group.this

  autoscaling_group_name = each.value.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-${each.key}"
    propagate_at_launch = true
  }
}