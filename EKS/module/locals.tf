locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "EKS"
    }
  )

  access_policy_associations = merge([
    for entry_key, entry in var.access_entries : {
      for policy_key, policy in entry.policy_associations :
      "${entry_key}-${policy_key}" => {
        principal_arn = entry.principal_arn
        policy_arn    = policy.policy_arn
        access_scope  = policy.access_scope
      }
    }
  ]...)

  windows_nodes_enabled = anytrue([
    for group in values(var.node_groups) :
    startswith(group.ami_type, "WINDOWS")
  ])

  addon_names = {
    vpc_cni      = "vpc-cni"
    coredns      = "coredns"
    kube_proxy   = "kube-proxy"
    ebs_csi      = "aws-ebs-csi-driver"
    efs_csi      = "aws-efs-csi-driver"
    pod_identity = "eks-pod-identity-agent"
  }
}