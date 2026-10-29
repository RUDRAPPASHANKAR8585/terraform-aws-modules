# --------------------------------------------------
# Common tags
# --------------------------------------------------

locals {
  common_tags = merge(
    var.tags,
    {
      Name        = var.cluster_name
      Environment = title(lower(var.environment))
      ManagedBy   = "Terraform"
      Module      = "EKS"
      Project     = "EKS"
    }
  )
}

# --------------------------------------------------
# Node group selection
# --------------------------------------------------

locals {
  normalized_node_group_type = lower(var.node_group_type)

  linux_nodes_enabled = contains(
    ["linux", "both"],
    local.normalized_node_group_type
  )

  windows_nodes_enabled = contains(
    ["windows", "both"],
    local.normalized_node_group_type
  )

  # Platform-controlled node-group settings.
  # Users provide scaling values through the catalog.

  node_group_defaults = {
    linux = {
      ami_type        = var.linux_ami_type
      instance_types  = var.linux_instance_types
      release_version = var.linux_ami_release_version
      capacity_type   = "ON_DEMAND"
    }

    windows = {
      ami_type        = var.windows_ami_type
      instance_types  = var.windows_instance_types
      release_version = var.windows_ami_release_version
      capacity_type   = "ON_DEMAND"
    }
  }


  # Only enabled node groups will be passed to the module.
  node_groups = merge(
    local.linux_nodes_enabled ? {
      linux = merge(
        local.node_group_defaults.linux,
        {
          min_size     = var.linux_min_nodes
          desired_size = var.linux_desired_nodes
          max_size     = var.linux_max_nodes
        }
      )
    } : {},

    local.windows_nodes_enabled ? {
      windows = merge(
        local.node_group_defaults.windows,
        {
          min_size     = var.windows_min_nodes
          desired_size = var.windows_desired_nodes
          max_size     = var.windows_max_nodes
        }
      )
    } : {}
  )
}

# --------------------------------------------------
# EKS managed add-ons
# --------------------------------------------------

locals {
  addons = merge(
    {
      vpc_cni = {
        version = null
      }

      coredns = {
        version = null
      }

      kube_proxy = {
        version = null
      }
    },

    var.enable_ebs_csi ? {
      ebs_csi = {
        version = null
      }
    } : {},

    var.enable_efs_csi ? {
      efs_csi = {
        version = null
      }
    } : {}
  )
}

# --------------------------------------------------
# Effective module configuration
# --------------------------------------------------

locals {
  effective_enable_windows_ipam = (
    local.windows_nodes_enabled && var.enable_windows_ipam
  )
}