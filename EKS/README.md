# AWS EKS Terraform Module

## 1. Overview

This repository contains a reusable Terraform configuration to create an
Amazon EKS cluster and its supporting resources.

The root configuration accepts environment/request inputs and calls the
child module in `module/`. The module currently supports Linux managed
node groups, Windows managed node groups, or both.

**Current status:** Initial POC / development phase. This README
explains the current design and intended usage; it does not certify the
module as production-ready. Some improvements are intentionally tracked
for a later phase.

## 2. What the module creates

Depending on the selected options, the module creates:

-   EKS cluster and control-plane logging
-   Cluster IAM role and managed policy attachment
-   Shared worker-node IAM role and required policy attachments
-   Cluster and node security groups
-   Linux and/or Windows EKS managed node groups
-   EKS access entries and access-policy associations
-   EKS managed add-ons: VPC CNI, CoreDNS, kube-proxy, and optional EBS
    CSI / EFS CSI
-   Optional OIDC provider and IRSA roles for CSI drivers
-   Common tags and a Name tag configured for future EC2 instances
    launched by node-group Auto Scaling Groups

The VPC and subnets are expected to exist already. This module does not
create the VPC.

## 3. Repository structure

``` text
EKS/
├── main.tf                 # Calls the child module
├── variables.tf            # Request-facing input variables and validation
├── locals.tf               # Common tags, node-group selection and add-on map
├── terraform.tfvars        # Environment-specific example values
├── versions.tf             # Terraform and provider constraints
└── module/
    ├── cluster.tf          # EKS cluster
    ├── node-groups.tf      # Managed node groups and ASG tags
    ├── addons.tf            # EKS add-ons and VPC CNI configuration
    ├── iam.tf               # Cluster, node and CSI IAM roles
    ├── access.tf            # EKS access entries and policy associations
    ├── security-groups.tf   # Cluster/node security groups and rules
    ├── locals.tf            # Child-module derived values
    ├── variables.tf         # Child-module input schemas and validation
    ├── outputs.tf           # Child-module outputs
    ├── main.tf
    └── versions.tf
```

Terraform loads all `.tf` files in a directory together; the file names
are used to organize the code.

## 4. How to use the module

The root configuration currently calls the local child module:

``` hcl
module "eks" {
  source = "./module"

  # The root main.tf maps the root variables and locals
  # to the child-module inputs.
}
```

Use the root configuration for this repository's current POC. For a
separate consumer repository or Terraform Enterprise private registry,
publish/version the child module and change the `source` to the approved
module source.

### Basic workflow

1.  Configure the AWS provider and approved target account/region.
2.  Set the request inputs in the approved `.tfvars` file or Terraform
    Enterprise workspace variables.
3.  Run formatting and validation.
4.  Review the plan and confirm the target account, VPC/subnets, cluster
    version, access entries, scaling, and security-group changes.
5.  Apply only after the required review and approval.

``` bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Run `terraform apply` only through the approved change and Terraform
Enterprise workflow. Creating EKS and EC2 resources can incur AWS
charges.

## 5. Basic inputs

The root configuration is the intended interface for requesters and
automation. The child module also has detailed variables, including
object inputs for node groups and access entries. Use the repository's
`variables.tf` as the source of truth for exact names, types, defaults,
and validations.

  ---------------------------------------------------------------------------
  Input / input group         Type                    Purpose
  --------------------------- ----------------------- -----------------------
  `cluster_name`              `string`                Name of the EKS cluster

  `cluster_version`           `string`                Kubernetes version for
                                                      the cluster

  `environment`               `string`                Environment label, such
                                                      as `dev`, `test`, or
                                                      `prod`

  `vpc_id`                    `string`                Existing VPC for the
                                                      cluster security groups

  `subnet_ids`                `list(string)`          Existing subnets used
                                                      by the cluster and, by
                                                      default, node groups

  `node_group_type`           `string`                Select `linux`,
                                                      `windows`, or `both`

  Linux node-group settings   strings / numbers       Linux instance type,
                                                      AMI type/release and
                                                      min/desired/max
                                                      capacity

  Windows node-group settings strings / numbers       Windows instance type,
                                                      AMI type/release and
                                                      min/desired/max
                                                      capacity

  `endpoint_private_access`   `bool`                  Enables private access
                                                      to the Kubernetes API
                                                      endpoint

  `endpoint_public_access`    `bool`                  Public API endpoint
                                                      setting; public access
                                                      is currently blocked by
                                                      root validation

  `public_access_cidrs`       `list(string)`          CIDRs for public API
                                                      endpoint access, if
                                                      allowed by policy

  `cluster_log_types`         `set(string)`           EKS control-plane log
                                                      types to enable

  `deletion_protection`       `bool`                  Controls EKS cluster
                                                      deletion protection

  EBS/EFS CSI options         `bool`                  Enable or disable the
                                                      corresponding storage
                                                      add-ons

  VPC CNI options             `bool` / `number`       Prefix delegation, warm
                                                      prefix target, and
                                                      Windows IPAM settings

  `access_entries`            `map(object(...))`      IAM principals and EKS
                                                      access-policy
                                                      associations

  `tags`                      `map(string)`           Additional tags to
                                                      merge with common
                                                      module tags
  ---------------------------------------------------------------------------

**Important:** Linux/Windows scaling inputs must satisfy
`min_size <= desired_size <= max_size` for each node group. Keep scaling
values within the capacity and cost limits approved for the target
environment.

Some values are platform-controlled rather than suitable for
unrestricted catalog input. In particular, account/region, VPC/subnets,
IAM principal ARNs, and EKS access-policy permissions should come from
approved configuration or trusted lookup/validation.

### Example configuration

The repository's `terraform.tfvars` is the working example for the exact
variable names and currently supported options. The values below are
illustrative only; replace them with values approved for the target
account and environment.

``` hcl
cluster_name       = "example-eks-dev"
cluster_version    = "1.XX"
environment        = "dev"
node_group_type    = "linux"

endpoint_private_access = true
endpoint_public_access  = false

# Example capacity relationship:
# min_size     = 2
# desired_size = 2
# max_size     = 4

enable_ebs_csi = true
enable_efs_csi = false

tags = {
  Application = "example"
  Owner       = "platform-team"
}
```

Do not copy the example Kubernetes version or environment-specific
identifiers without checking the actual root variable declarations and
supported versions.

## 6. Node group selection

  Value       Result
  ----------- ----------------------------------------
  `linux`     Creates the Linux managed node group
  `windows`   Creates the Windows managed node group
  `both`      Creates both managed node groups

The current implementation uses a shared worker-node IAM role. Node
groups support instance types, AMI type, optional release version,
scaling configuration, disk size, optional subnet overrides, labels, and
taints through the child module's node-group object.

## 7. Add-ons, IAM and access

-   VPC CNI, CoreDNS, and kube-proxy are included by the current root
    locals.
-   EBS CSI and EFS CSI are optional.
-   IRSA can create an OIDC provider and dedicated CSI driver IAM roles
    when enabled and when the related add-on is selected.
-   EKS access entries are configured through `access_entries`.

The current example includes a cluster-admin access policy. Treat this
as a powerful permission: use only approved principals and access
scopes, and do not allow requesters to assign themselves administrator
access.

Add-on versions currently use provider/EKS defaults rather than an
explicitly pinned version in root locals. Version compatibility and
rollout policy remain follow-up work.

## 8. Outputs

The child module exposes outputs for the cluster identifiers and
connection information, security-group ID, IAM role ARNs, OIDC details,
and CSI driver role ARNs. Typical output categories are:

  -----------------------------------------------------------------------
  Output category                     What it is used for
  ----------------------------------- -----------------------------------
  Cluster name / ID / ARN             Identify the created EKS cluster

  Cluster endpoint and Kubernetes     Connection metadata and reporting
  version                             

  Cluster security-group ID           Network integration and
                                      troubleshooting

  Cluster and node IAM role ARNs      IAM auditing and integration

  OIDC issuer / provider details      IRSA integrations

  EBS CSI / EFS CSI role ARNs         Storage driver integration
  -----------------------------------------------------------------------

**Root-output note:** Terraform does not automatically expose
child-module outputs to callers. The current repository has no
root-level `outputs.tf` in the shared structure. Add root outputs that
forward the child outputs required by Terraform Enterprise, ServiceNow,
or downstream automation before depending on them externally.

## 9. Current known gaps --- to address later

These are tracked follow-up items, not blockers to documenting the
initial phase.

1.  **Initial EC2 Name tags:** the current ASG tag resource may be
    created after the EKS managed node group has already launched its
    initial instances. The tag propagates to future launches, but the
    initial instances may not receive it. Investigate a creation-time
    tagging solution and test it on a fresh deployment.
2.  **Scaling validation:** verify that root-level inputs enforce
    `min_size <= desired_size <= max_size` for both Linux and Windows
    node groups, in addition to any child-module validation.
3.  **Root outputs:** expose selected child outputs through root-level
    output blocks.
4.  **Security-group least privilege:** review the current broad
    cluster/node rules and node egress against the approved EKS network
    design.
5.  **Version compatibility:** validate Kubernetes, AMI and add-on
    compatibility in the target region; consider explicit add-on version
    pinning.
6.  **Network validation:** verify subnet/VPC relationship, Availability
    Zone coverage, free IP capacity, routing, and EKS subnet tags.
7.  **Access governance:** define approved principal resolution, policy
    choices, scopes, and approval controls for ServiceNow/TFE.
8.  **Testing and release controls:** add automated validation,
    security/policy checks, representative Linux/Windows/both test
    cases, and a module versioning process.
9.  **Operational readiness:** document upgrades, monitoring, alerting,
    maintenance, recovery, and safe teardown.
10. **ServiceNow/TFE contract:** define catalog fields, request JSON
    schema, variable mapping, approvals, run-status feedback, and error
    handling.

## 10. Source control and Terraform Enterprise

-   Keep `.terraform.lock.hcl` under source control.
-   Do not commit Terraform state, saved plan files, credentials, or
    secret values.
-   Use a sanitized `terraform.tfvars.example` for documentation; keep
    environment-specific values in approved workspace variables or
    protected files.
-   Use Terraform Enterprise workspace controls, state access controls,
    variable sets, reviewed runs, and approvals according to the team's
    standard.
-   The ServiceNow-to-TFE integration is a planned workflow; it is not
    implemented by the Terraform files in this repository.

Example `.gitignore` entries:

``` gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan
crash.log
crash.*.log
*.tfvars
!terraform.tfvars.example
```

Review these patterns against repository policy before adopting them.

## 11. Validation checklist

Before requesting approval for a run:

-   [ ] `terraform fmt -recursive` completes successfully.
-   [ ] `terraform init` completes successfully in the intended
    workspace.
-   [ ] `terraform validate` passes.
-   [ ] The target AWS account and region are correct.
-   [ ] VPC and subnet IDs are approved and valid.
-   [ ] Cluster version, AMI types and instance types are supported.
-   [ ] Node-group scaling values are valid.
-   [ ] Access entries and permissions are approved.
-   [ ] The plan contains only expected resource changes.
-   [ ] Required change approval is recorded before apply.

## 12. Support and ownership

Before wider publication, add the approved module owner, support
contact, contribution guidance, and license information.
