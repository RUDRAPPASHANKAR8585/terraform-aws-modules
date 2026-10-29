# General configuration
cluster_name    = "novartis-eks-poc"
cluster_version = "1.36"
environment     = "dev"

# Backend-controlled network configuration
vpc_id = "vpc-09ccffec2c3bf59e1"

subnet_ids = [
  "subnet-021f7c17719bf5689",
  "subnet-0f350de5ccb05ea23"
]

node_group_type = "both"
# Linux node-group configuration
linux_instance_types      = ["m6i.large"]
linux_ami_type            = "AL2023_x86_64_STANDARD"
linux_ami_release_version = null

# Windows node-group configuration
windows_instance_types      = ["m6i.large"]
windows_ami_type            = "WINDOWS_CORE_2022_x86_64"
windows_ami_release_version = null


# Linux node-group scaling
linux_min_nodes     = 2
linux_desired_nodes = 3
linux_max_nodes     = 3

# Windows node-group scaling
windows_min_nodes     = 2
windows_desired_nodes = 3
windows_max_nodes     = 3

# API endpoint security
endpoint_private_access = true
endpoint_public_access  = false


# Optional storage add-ons
enable_ebs_csi = true
enable_efs_csi = true

# Platform-controlled VPC CNI configuration
vpc_cni_enable_prefix_delegation = true
vpc_cni_warm_prefix_target       = 1
enable_windows_ipam              = true

# Cluster security and logging
deletion_protection = true

cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]

# Cluster access
access_entries = {
  iac_poc = {
    principal_arn = "arn:aws:iam::700030738273:user/iac-poc"
    user_name     = "iac-poc"

    policy_associations = {
      admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

        access_scope = {
          type       = "cluster"
          namespaces = []
        }
      }
    }
  }
}


# Additional tags
tags = {
  ManagedBy = "Terraform"
  Project   = "EKS"
}