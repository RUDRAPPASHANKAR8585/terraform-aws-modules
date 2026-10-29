# --------------------------------------------------
# General configuration
# --------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster requested through ServiceNow."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-Za-z][0-9A-Za-z-]{0,99}$", var.cluster_name))
    error_message = "Cluster name must be 1-100 characters, start with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], lower(var.environment))
    error_message = "environment must be dev, test, or prod."
  }
}

variable "cluster_version" {
  description = "Kubernetes version approved by the platform team."
  type        = string
  default     = "1.34"
}

# --------------------------------------------------
# Backend-controlled network configuration
# --------------------------------------------------

variable "vpc_id" {
  description = "Existing VPC ID supplied by approved backend configuration."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a validly formatted VPC ID."
  }
}

variable "subnet_ids" {
  description = "Approved subnet IDs supplied by backend configuration."
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) >= 2 &&
      length(distinct(var.subnet_ids)) == length(var.subnet_ids) &&
      alltrue([for subnet in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet))])
    )
    error_message = "Provide at least two unique, validly formatted subnet IDs."
  }
}

# --------------------------------------------------
# Node-group selection
# --------------------------------------------------

variable "node_group_type" {
  description = "Node groups to create: linux, windows, or both."
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows", "both"], lower(var.node_group_type))
    error_message = "node_group_type must be linux, windows, or both."
  }
}

# --------------------------------------------------
# Linux node-group scaling
# --------------------------------------------------

variable "linux_min_nodes" {
  description = "Minimum Linux worker nodes. Used when Linux is enabled."
  type        = number
  default     = 2

  validation {
    condition     = var.linux_min_nodes >= 1 && var.linux_min_nodes == floor(var.linux_min_nodes)
    error_message = "linux_min_nodes must be a positive whole number."
  }
}

variable "linux_desired_nodes" {
  description = "Desired Linux worker nodes. Used when Linux is enabled."
  type        = number
  default     = 2

  validation {
    condition     = var.linux_desired_nodes >= 1 && var.linux_desired_nodes == floor(var.linux_desired_nodes)
    error_message = "linux_desired_nodes must be a positive whole number."
  }
}

variable "linux_max_nodes" {
  description = "Maximum Linux worker nodes. Used when Linux is enabled."
  type        = number
  default     = 5

  validation {
    condition     = var.linux_max_nodes >= 1 && var.linux_max_nodes == floor(var.linux_max_nodes)
    error_message = "linux_max_nodes must be a positive whole number."
  }
}

# --------------------------------------------------
# Windows node-group scaling
# --------------------------------------------------

variable "windows_min_nodes" {
  description = "Minimum Windows worker nodes. Used when Windows is enabled."
  type        = number
  default     = 1

  validation {
    condition     = var.windows_min_nodes >= 1 && var.windows_min_nodes == floor(var.windows_min_nodes)
    error_message = "windows_min_nodes must be a positive whole number."
  }
}

variable "windows_desired_nodes" {
  description = "Desired Windows worker nodes. Used when Windows is enabled."
  type        = number
  default     = 1

  validation {
    condition     = var.windows_desired_nodes >= 1 && var.windows_desired_nodes == floor(var.windows_desired_nodes)
    error_message = "windows_desired_nodes must be a positive whole number."
  }
}

variable "windows_max_nodes" {
  description = "Maximum Windows worker nodes. Used when Windows is enabled."
  type        = number
  default     = 3

  validation {
    condition     = var.windows_max_nodes >= 1 && var.windows_max_nodes == floor(var.windows_max_nodes)
    error_message = "windows_max_nodes must be a positive whole number."
  }
}

# --------------------------------------------------
# Optional storage add-ons
# --------------------------------------------------

variable "enable_ebs_csi" {
  description = "Whether to install the Amazon EBS CSI driver."
  type        = bool
  default     = true
}

variable "enable_efs_csi" {
  description = "Whether to install the Amazon EFS CSI driver."
  type        = bool
  default     = false
}

# --------------------------------------------------
# API endpoint security
# --------------------------------------------------

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API endpoint."
  type        = bool
  default     = false

  validation {
    condition     = var.endpoint_public_access == false
    error_message = "Public endpoint access is disabled in this initial catalog configuration. Any exception must be implemented through an approved security workflow."
  }
}

# --------------------------------------------------
# Cluster access
# --------------------------------------------------


variable "access_entries" {
  description = "IAM principals and their EKS access policy associations."

  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(set(string), [])
    user_name         = optional(string)

    policy_associations = optional(map(object({
      policy_arn = string

      access_scope = object({
        type       = string
        namespaces = optional(set(string), [])
      })
    })), {})
  }))

  default = {}
}

# --------------------------------------------------
# Platform-controlled add-on configuration
# --------------------------------------------------

variable "vpc_cni_enable_prefix_delegation" {
  description = "Enable prefix delegation for the VPC CNI."
  type        = bool
  default     = true
}

variable "vpc_cni_warm_prefix_target" {
  description = "Number of warm prefixes maintained by the VPC CNI."
  type        = number
  default     = 1

  validation {
    condition     = var.vpc_cni_warm_prefix_target >= 1 && var.vpc_cni_warm_prefix_target == floor(var.vpc_cni_warm_prefix_target)
    error_message = "vpc_cni_warm_prefix_target must be a positive whole number."
  }
}

variable "enable_windows_ipam" {
  description = "Enable Windows IP address management in the VPC CNI when Windows nodes are deployed."
  type        = bool
  default     = false
}

# --------------------------------------------------
# Platform controls
# --------------------------------------------------

variable "deletion_protection" {
  description = "Enable EKS cluster deletion protection."
  type        = bool
  default     = true
}

variable "cluster_log_types" {
  description = "EKS control-plane logs enabled by platform policy."
  type        = set(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  validation {
    condition = length(setsubtract(
      var.cluster_log_types,
      toset([
        "api",
        "audit",
        "authenticator",
        "controllerManager",
        "scheduler"
      ])
    )) == 0
    error_message = "cluster_log_types contains an unsupported log type."
  }
}

variable "tags" {
  description = "Additional tags supplied by approved platform configuration."
  type        = map(string)
  default     = {}
}

variable "linux_instance_types" {
  description = "EC2 instance types for the Linux managed node group."
  type        = list(string)
  default     = ["m6i.large"]

  validation {
    condition     = length(var.linux_instance_types) > 0
    error_message = "At least one Linux instance type must be specified."
  }
}

variable "linux_ami_type" {
  description = "EKS managed node group AMI type for Linux."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "linux_ami_release_version" {
  description = "Optional pinned EKS-optimized Linux AMI release version."
  type        = string
  default     = null
  nullable    = true
}

variable "windows_instance_types" {
  description = "EC2 instance types for the Windows managed node group."
  type        = list(string)
  default     = ["m6i.large"]

  validation {
    condition     = length(var.windows_instance_types) > 0
    error_message = "At least one Windows instance type must be specified."
  }
}

variable "windows_ami_type" {
  description = "EKS managed node group AMI type for Windows."
  type        = string
  default     = "WINDOWS_CORE_2022_x86_64"
}

variable "windows_ami_release_version" {
  description = "Optional pinned EKS-optimized Windows AMI release version."
  type        = string
  default     = null
  nullable    = true
}