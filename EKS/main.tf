# --------------------------------------------------
# EKS module deployment
# --------------------------------------------------

module "eks" {
  source = "./module"

  # General configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Existing network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster endpoint security
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = []

  # Control-plane configuration
  cluster_log_types   = var.cluster_log_types
  authentication_mode = "API"

  bootstrap_cluster_creator_admin_permissions = false
  deletion_protection                         = var.deletion_protection

  # Conditional node groups
  node_groups = local.node_groups

  # Managed add-ons
  addons = local.addons

  # VPC CNI configuration
  vpc_cni_enable_prefix_delegation = var.vpc_cni_enable_prefix_delegation
  vpc_cni_warm_prefix_target       = var.vpc_cni_warm_prefix_target
  enable_windows_ipam              = local.effective_enable_windows_ipam

  # IRSA for add-ons that require AWS permissions
  enable_irsa = true

  # Approved Kubernetes access principals
  access_entries = var.access_entries

  tags = local.common_tags
}