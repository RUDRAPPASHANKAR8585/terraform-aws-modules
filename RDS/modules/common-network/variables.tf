
variable "name" {
  type        = string
  description = "Database deployment name"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Existing private subnet IDs"

  validation {
    condition     = length(distinct(var.subnet_ids)) == length(var.subnet_ids)
    error_message = "Subnet IDs must be unique."
  }
}

variable "ingress_rules" {
  description = "Approved inbound database access rules"

  type = map(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = optional(string, "tcp")
    cidr_ipv4                = optional(string)
    source_security_group_id = optional(string)
  }))

  default = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to networking resources"
  default     = {}
}
