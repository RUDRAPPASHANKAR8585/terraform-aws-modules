resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode = var.authentication_mode

    bootstrap_cluster_creator_admin_permissions = (
      var.bootstrap_cluster_creator_admin_permissions
    )
  }

  deletion_protection = var.deletion_protection

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.cluster.id]

    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]
}