variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name must not be empty."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC where the EKS cluster will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of existing subnet IDs for the EKS cluster."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs are required for an EKS cluster."
  }
}

variable "endpoint_private_access" {
  description = "Whether the EKS Kubernetes API endpoint is privately accessible."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS Kubernetes API endpoint is publicly accessible."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = set(string)

  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "tags" {
  description = "Common tags to apply to EKS resources."
  type        = map(string)
  default     = {}
}

variable "authentication_mode" {
  description = "EKS authentication mode."
  type        = string
  default     = "API"

  validation {
    condition = contains(
      ["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"],
      var.authentication_mode
    )

    error_message = "authentication_mode must be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether to grant the cluster creator administrator permissions through EKS access configuration."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether to enable EKS cluster deletion protection."
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Map of EKS managed node groups."

  type = map(object({
    ami_type        = string
    instance_types  = list(string)
    capacity_type   = string
    release_version = optional(string)

    min_size     = number
    max_size     = number
    desired_size = number

    subnet_ids = optional(list(string))

    disk_size = optional(number, 50)

    labels = optional(map(string), {})

    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))

  default = {}

  validation {
    condition = alltrue([
      for group in values(var.node_groups) :
      contains(["ON_DEMAND", "SPOT"], group.capacity_type)
    ])

    error_message = "Node group capacity_type must be ON_DEMAND or SPOT."
  }

  validation {
    condition = alltrue([
      for group in values(var.node_groups) :
      group.min_size <= group.desired_size &&
      group.desired_size <= group.max_size
    ])

    error_message = "For every node group, min_size must be <= desired_size <= max_size."
  }

  validation {
    condition = alltrue([
      for group in values(var.node_groups) :
      length(group.instance_types) > 0
    ])

    error_message = "Every node group must specify at least one instance type."
  }
}

variable "addons" {
  description = "Map of EKS managed add-ons."

  type = map(object({
    version = optional(string)

    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")

    configuration_values = optional(string)

    service_account_role_arn = optional(string)

    preserve = optional(bool, false)

    tags = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for addon in values(var.addons) :
      contains(
        ["OVERWRITE", "NONE"],
        addon.resolve_conflicts_on_create
      )
    ])

    error_message = "resolve_conflicts_on_create must be OVERWRITE or NONE."
  }

  validation {
    condition = alltrue([
      for addon in values(var.addons) :
      contains(
        ["OVERWRITE", "NONE"],
        addon.resolve_conflicts_on_update
      )
    ])

    error_message = "resolve_conflicts_on_update must be OVERWRITE or NONE."
  }

  validation {
    condition = alltrue([
      for addon in values(var.addons) :
      addon.configuration_values == null ||
      can(jsondecode(addon.configuration_values))
    ])

    error_message = "configuration_values must contain valid JSON when specified."
  }
}

variable "enable_irsa" {
  description = "Whether to create the IAM OIDC provider required for IAM Roles for Service Accounts (IRSA)."
  type        = bool
  default     = false
}

variable "access_entries" {
  description = "IAM principals that should have access to the EKS cluster."

  type = map(object({
    principal_arn = string

    kubernetes_groups = optional(set(string), [])

    user_name = optional(string)

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

variable "vpc_cni_enable_prefix_delegation" {
  description = "Enable prefix delegation for the Amazon VPC CNI add-on."
  type        = bool
  default     = false
}

variable "vpc_cni_warm_prefix_target" {
  description = "Number of prefixes to keep warm for the Amazon VPC CNI add-on."
  type        = number
  default     = 1

  validation {
    condition     = var.vpc_cni_warm_prefix_target >= 0
    error_message = "vpc_cni_warm_prefix_target must be greater than or equal to 0."
  }
}

variable "enable_windows_ipam" {
  description = "Enable Windows IP address management in the Amazon VPC CNI add-on."
  type        = bool
  default     = false
}
