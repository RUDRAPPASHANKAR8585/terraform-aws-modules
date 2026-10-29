output "cluster_id" {
  description = "EKS cluster ID."
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster."
  value       = aws_security_group.cluster.id
}

output "cluster_role_arn" {
  description = "IAM role ARN used by the EKS cluster."
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by EKS managed node groups."
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider associated with the EKS cluster."
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.this[0].arn : null
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN used by the Amazon EBS CSI driver."
  value = (
    contains(keys(var.addons), "ebs_csi") && var.enable_irsa
    ? aws_iam_role.ebs_csi[0].arn
    : null
  )
}

output "efs_csi_role_arn" {
  description = "IAM role ARN used by the EFS CSI driver."

  value = (
    contains(keys(var.addons), "efs_csi")
    ? aws_iam_role.efs_csi[0].arn
    : null
  )
}