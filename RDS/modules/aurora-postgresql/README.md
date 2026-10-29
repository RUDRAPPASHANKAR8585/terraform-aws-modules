# Aurora PostgreSQL Terraform Module

Reusable Terraform child module for deploying an Amazon Aurora PostgreSQL cluster, writer and optional reader instances, networking resources, parameter groups, monitoring, encryption, logging, and operational settings.

> **Scope:** This README documents the child module in `modules/aurora-postgresql/`. Its inputs use unprefixed names such as `name` and `deployment_mode`. When called through the repository root module, the corresponding root inputs use the `aurora_postgresql_` prefix.

## Contents

- [Features](#features)
- [Repository placement](#repository-placement)
- [Prerequisites](#prerequisites)
- [Deployment modes](#deployment-modes)
- [Quick start](#quick-start)
- [Input variables](#input-variables)
- [Important variable combinations](#important-variable-combinations)
- [Network and security](#network-and-security)
- [Outputs](#outputs)
- [Deployment workflow](#deployment-workflow)
- [Destroy and snapshot considerations](#destroy-and-snapshot-considerations)
- [Troubleshooting](#troubleshooting)

## Features

- Aurora PostgreSQL with one writer and configurable reader count.
- Provisioned instances or Aurora Serverless v2.
- Integration with an existing VPC and subnets.
- Database security group with configurable inbound rules.
- Optional custom cluster and instance parameter groups.
- Storage encryption and optional customer-managed AWS KMS keys.
- RDS-managed master credentials in AWS Secrets Manager.
- Automated backup retention, maintenance settings, deletion protection, and final-snapshot controls.
- Enhanced Monitoring and CloudWatch log exports.
- Performance Insights and Standard/Advanced Database Insights configuration.
- Optional IAM database authentication and Aurora Data API HTTP endpoint.
- Resource tags and input validation.

## Repository placement

Place this file here:

```text
terraform-aws-rds/
└── modules/
    └── aurora-postgresql/
        ├── README.md
        ├── variables.tf
        ├── outputs.tf
        └── *.tf
```

The repository root should have a separate `README.md` describing the whole repository, root orchestration layer, supported engines, and links to each module's README.

## Prerequisites

1. Terraform installed and available on `PATH`.
2. AWS credentials for the intended account, with permissions to manage RDS, EC2 networking/security groups, IAM monitoring roles (if created), KMS keys, and related resources.
3. An existing VPC and at least two unique subnets belonging to that VPC and spanning at least two Availability Zones.
4. An Aurora PostgreSQL engine version supported in the target AWS Region.
5. A reviewed network-access plan. No inbound database rules are added by default when `ingress_rules = {}`.
6. Required IAM and KMS permissions if using existing roles or customer-managed keys.

The child module does not select the AWS provider region. Configure the provider in the root configuration that calls this module.

## Deployment modes

Set `deployment_mode` to one of the following:

| Value | Description | Instance class behavior |
|---|---|---|
| `provisioned` (default) | Uses provisioned Aurora DB instances. | Writer uses `instance_class`. Readers use `reader_instance_class` if set; otherwise they use `instance_class`. |
| `serverless_v2` | Uses Aurora Serverless v2 capacity scaling. | The module selects `db.serverless` for writer and readers. `instance_class` and `reader_instance_class` do not determine the resulting class. |

For Serverless v2, `serverless_v2_min_capacity` and `serverless_v2_max_capacity` set the scaling range in Aurora Capacity Units (ACUs). The module validates values from 0.5 to 256 in 0.5 increments and requires the minimum not to exceed the maximum. Confirm the selected engine version and Region support the desired configuration.

A writer is always created. `reader_count = 0` creates no readers; `reader_count = 1` creates one reader in addition to the writer.

## Quick start

### Option A: Call the child module directly

Create a Terraform root configuration that references the module directory. Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "aurora_postgresql" {
  source = "./modules/aurora-postgresql"

  name           = "dev-aurora-pg-test"
  engine_version = "18.6"

  deployment_mode = "serverless_v2"
  instance_class  = "db.r7g.large" # Used only in provisioned mode
  reader_count    = 1

  serverless_v2_min_capacity = 0.5
  serverless_v2_max_capacity = 2

  vpc_id = "vpc-REPLACE_ME"
  subnet_ids = [
    "subnet-REPLACE_ME_A",
    "subnet-REPLACE_ME_B"
  ]

  database_name   = "devdb"
  master_username = "dbadmin"

  # Keep empty unless approved database access rules are required.
  ingress_rules = {}

  # Required when skip_final_snapshot = false.
  final_snapshot_identifier = "dev-aurora-pg-test-final-snapshot"

  tags = {
    Environment = "Dev"
    Project     = "RDS-Terraform-Module"
    ManagedBy   = "Terraform"
  }
}
```

Replace example IDs with valid values from the target AWS account. The engine version is an example from the current POC inputs, not a guarantee that it is available in every Region or account.

### Option B: Use the repository root orchestration layer

When using the repository root configuration, provide root-level variable names with the `aurora_postgresql_` prefix. For example:

```hcl
aurora_postgresql_name            = "dev-aurora-pg-test"
aurora_postgresql_engine_version  = "18.6"
aurora_postgresql_deployment_mode = "serverless_v2"

aurora_postgresql_vpc_id = "vpc-REPLACE_ME"
aurora_postgresql_subnet_ids = [
  "subnet-REPLACE_ME_A",
  "subnet-REPLACE_ME_B"
]
```

The root layer maps these prefixed inputs to the child module's unprefixed inputs. Use the root `variables.tf` and root `README.md` for the complete root-level interface.

### Run Terraform safely

Run commands from the intended Terraform **root directory**. If you are using the repository root orchestration layer, run them from `terraform-aws-rds/`, not from `modules/aurora-postgresql/`.

```powershell
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Review the AWS account, Region, proposed resources, reader count, network rules, and any replacement/deletion actions before applying. Run `terraform apply` only after the plan is reviewed and approved.

## Input variables

**Required** means the variable has no default in the child module and must be provided by the caller. Defaults below describe the module interface. Values can be overridden by the caller.

### 1. Cluster identity and deployment

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `name` | Required | Cluster identifier. Must be 1–63 characters, start with a lowercase letter, contain lowercase letters, numbers or hyphens, avoid consecutive hyphens, and not end with a hyphen. Also contributes to related resource names. |
| `engine_version` | Required | Numeric Aurora PostgreSQL engine version such as `17.9` or `16.4`, subject to AWS availability. The module derives the parameter group family from the major version. |
| `deployment_mode` | `provisioned` | `provisioned` or `serverless_v2`. Controls instance-class behavior and whether Serverless v2 scaling configuration is used. |
| `instance_class` | Required | Writer class for `provisioned` mode, e.g. a supported class such as `db.r7g.large`. In Serverless v2 mode the module selects `db.serverless`. |
| `reader_instance_class` | `null` | Optional reader class in provisioned mode. `null` means use `instance_class`. Serverless v2 uses `db.serverless`. |
| `reader_count` | `1` | Integer from 0 through 15. The writer is always created; this controls additional reader instances. |
| `serverless_v2_min_capacity` | `0.5` | Serverless v2 minimum ACUs; module range is 0.5–256 in 0.5 increments. |
| `serverless_v2_max_capacity` | `2` | Serverless v2 maximum ACUs; module range is 0.5–256 in 0.5 increments and must be at least the minimum. |

### 2. VPC, subnets, Availability Zones, and inbound access

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `vpc_id` | Required | Existing VPC ID where the database security group and database subnets reside. |
| `subnet_ids` | Required | At least two unique subnet IDs. The module validates VPC ownership and that subnets span at least two AZs. Prefer private subnets for private database deployments. |
| `enable_availability_zones` | `false` | Set to `true` to explicitly configure `availability_zones`; `false` allows AWS to choose based on the subnet group. |
| `availability_zones` | `[]` | Optional list of AZ names. Values must be unique and represented by the supplied subnets. Used when `enable_availability_zones = true` and the list is non-empty. |
| `ingress_rules` | `{}` | Map of inbound PostgreSQL TCP/5432 rules. Each rule needs a `description` and exactly one of `cidr_ipv4` or `source_security_group_id`. Empty map means no inbound rules are added by this input. |

Example using an application security group:

```hcl
ingress_rules = {
  app_tier = {
    description              = "PostgreSQL from approved application tier"
    source_security_group_id = "sg-REPLACE_ME"
  }
}
```

Or use an approved IPv4 CIDR:

```hcl
ingress_rules = {
  approved_network = {
    description = "Approved application subnet"
    cidr_ipv4   = "10.20.30.0/24"
  }
}
```

Do not set both source fields in a single rule. Avoid broad CIDRs such as `0.0.0.0/0` for database access.

### 3. Database and credentials

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `database_name` | `null` | Optional initial database name. When set, it must start with a letter and contain only letters, numbers, and underscores. `null` leaves it unset. |
| `master_username` | `"dbadmin"` | Master username. Must start with a letter and contain letters, numbers, or underscores; module validation limits its length to 1–63 characters. |
| `secret_kms_key_id` | `null` | Optional KMS key ID/ARN for encrypting the RDS-managed master credentials secret in Secrets Manager. `null` uses the service's default key behavior. |

The module enables RDS-managed master credentials through Secrets Manager. Do not put a plaintext database password in `.tf` or `.tfvars` files.

### 4. Storage and encryption

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `storage_encrypted` | `true` | Enables cluster storage encryption when `true`. |
| `kms_key_id` | `null` | Optional customer-managed KMS key for cluster storage. If omitted while encryption is enabled, AWS default key behavior applies where supported. Do not set a storage KMS key when `storage_encrypted = false`. |
| `storage_type` | `"aurora"` | `aurora` or `aurora-iopt1`. Confirm service availability and cost implications before selecting I/O-Optimized storage. |

### 5. Backups, maintenance, and deletion lifecycle

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `backup_retention_period` | `7` | Automated backup retention in days; module range is 1–35. |
| `preferred_backup_window` | `null` | Optional daily backup window in UTC. `null` lets AWS choose the window. |
| `preferred_maintenance_window` | `null` | Optional weekly maintenance window in UTC. `null` lets AWS choose the window. |
| `deletion_protection` | `true` | Helps prevent accidental cluster deletion. Disable only through an approved lifecycle process. |
| `skip_final_snapshot` | `false` | `true` skips a final snapshot during deletion; `false` requires a final snapshot identifier. |
| `final_snapshot_identifier` | `null` | Must be set when `skip_final_snapshot = false`; must be `null` when `skip_final_snapshot = true`. Use a unique valid identifier. |
| `apply_immediately` | `false` | `true` applies eligible modifications immediately; `false` follows the service's normal apply/maintenance behavior. Immediate changes may affect availability. |
| `auto_minor_version_upgrade` | `true` | Enables automatic minor-version upgrades for DB instances. |

**Important:** The defaults `skip_final_snapshot = false` and `final_snapshot_identifier = null` are not a valid combination under this module's validation. Supply a final snapshot identifier, or deliberately set `skip_final_snapshot = true`.

### 6. Parameter groups

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `use_custom_parameter_groups` | `true` | When `true`, creates custom cluster and DB instance parameter groups. When `false`, custom groups are not created/used by this module. |
| `parameter_group_family` | `null` | Optional explicit parameter group family. `null` derives it from the major engine version, e.g. `18.6` maps to `aurora-postgresql18`. An explicit value must match the family expected by module validation. |
| `enable_custom_cluster_parameters` | `false` | Must be `true` to apply values from `cluster_parameters`. |
| `cluster_parameters` | `{}` | Map of cluster parameter overrides. Each item has a `value` and optional `apply_method` (default `pending-reboot`). |
| `enable_custom_instance_parameters` | `false` | Must be `true` to apply values from `instance_parameters`. |
| `instance_parameters` | `{}` | Map of DB instance parameter overrides. Each item has a `value` and optional `apply_method` (default `pending-reboot`). |

Example:

```hcl
use_custom_parameter_groups = true

enable_custom_cluster_parameters = true
cluster_parameters = {
  timezone = {
    value        = "Asia/Kolkata"
    apply_method = "immediate"
  }
}

enable_custom_instance_parameters = true
instance_parameters = {
  log_min_duration_statement = {
    value        = "1000"
    apply_method = "pending-reboot"
  }
}
```

Parameter names, accepted values, and apply methods depend on the Aurora PostgreSQL engine family. Some changes require a reboot. Verify compatibility before using custom values.

### 7. Enhanced Monitoring and CloudWatch logs

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `monitoring_interval` | `60` | Enhanced Monitoring interval in seconds: `0`, `1`, `5`, `10`, `15`, `30`, or `60`. `0` disables Enhanced Monitoring. |
| `monitoring_role_arn` | `null` | Optional existing IAM role ARN. If `null` and monitoring is enabled, the module creates a role and attaches `AmazonRDSEnhancedMonitoringRole`. |
| `enabled_cloudwatch_logs_exports` | `["postgresql"]` | List of log exports supported by this module: `postgresql` and `iam-db-auth-error`. Confirm compatibility with the chosen engine/service configuration. |

If using an existing monitoring role, ensure its trust relationship and permissions are correct for RDS Enhanced Monitoring.

### 8. Performance Insights and Database Insights

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `performance_insights_enabled` | `true` | Enables Performance Insights where supported when `true`. |
| `performance_insights_kms_key_id` | `null` | Optional customer-managed KMS key for Performance Insights. Do not set when Performance Insights is disabled. |
| `performance_insights_retention_period` | `7` | Retention period in days. Confirm supported values for the selected engine and AWS offering. |
| `database_insights_mode` | `"standard"` | `standard` or `advanced` (module handling is case-insensitive). The module validates that Advanced mode has Performance Insights enabled and retention of at least 465 days. |

#### Standard vs. Advanced

| Setting | Standard | Advanced |
|---|---|---|
| `database_insights_mode` | `"standard"` | `"advanced"` |
| Performance Insights | Subject to service support | Must be enabled by module validation |
| Retention required by this module | Default is `7` days | At least `465` days |

Advanced configuration example:

```hcl
database_insights_mode                = "advanced"
performance_insights_enabled          = true
performance_insights_retention_period = 465
```

Advanced mode may have additional AWS service, engine, Region, and pricing requirements. Verify current AWS requirements before enabling it in production.

### 9. Networking and optional database features

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `network_type` | `"IPV4"` | `IPV4` or `DUAL`. Dual-stack requires compatible VPC/subnet networking and service support. |
| `publicly_accessible` | `false` | Requests public accessibility for DB instances. Module validation requires `allow_public_access = true` before this can be enabled. |
| `allow_public_access` | `false` | Explicit acknowledgement gate. Both this and `publicly_accessible` must be `true` for public accessibility to be enabled. Follow organizational security policy. |
| `enable_http_endpoint` | `false` | Enables the Aurora Data API HTTP endpoint where supported. |
| `iam_database_authentication_enabled` | `false` | Enables IAM database authentication. Database users and clients must also be configured for it. |

Public accessibility is disabled by default. Prefer private subnets and security-group-based connectivity.

### 10. Tags

| Variable | Required / default | Purpose and accepted values |
|---|---|---|
| `tags` | `{}` | Map of string key/value tags supplied by the caller. The module also merges standard tags such as `ManagedBy = "Terraform"`, `Engine = "aurora-postgresql"`, and a resource-specific `Name`. Individual resources may add `Type` or `Role` tags. |

Example:

```hcl
tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  CostCenter  = "REPLACE_ME"
}
```

## Important variable combinations

| Goal | Configuration |
|---|---|
| Provisioned deployment | `deployment_mode = "provisioned"` and a supported `instance_class` |
| Serverless v2 | `deployment_mode = "serverless_v2"` plus minimum and maximum ACUs; module uses `db.serverless` |
| Writer only | `reader_count = 0` |
| Writer plus one reader | `reader_count = 1` |
| Disable Enhanced Monitoring | `monitoring_interval = 0` |
| Reuse an existing monitoring role | Set `monitoring_role_arn` to the role ARN and ensure the role is correctly configured |
| Custom cluster parameters | `use_custom_parameter_groups = true`, `enable_custom_cluster_parameters = true`, and populate `cluster_parameters` |
| Custom instance parameters | `use_custom_parameter_groups = true`, `enable_custom_instance_parameters = true`, and populate `instance_parameters` |
| Advanced Database Insights | `database_insights_mode = "advanced"`, Performance Insights enabled, retention at least `465` days |
| Customer-managed storage key | `storage_encrypted = true` and set `kms_key_id` |
| Public accessibility | Both `publicly_accessible = true` and `allow_public_access = true`, after security review |
| Skip final snapshot | `skip_final_snapshot = true` and `final_snapshot_identifier = null` |
| Create final snapshot on deletion | `skip_final_snapshot = false` and set `final_snapshot_identifier` |

## Network and security

- The module uses an existing VPC and subnets; it does not create them.
- Inbound PostgreSQL TCP/5432 rules are created only from the entries in `ingress_rules`.
- Each ingress rule must specify exactly one source: IPv4 CIDR or source security group ID.
- Subnets must belong to the specified VPC and span at least two AZs.
- Keep public accessibility disabled unless there is a documented requirement and approved security design.
- Restrict access to the RDS-managed master credentials secret using IAM and Secrets Manager policies.
- Customer-managed KMS keys require suitable key policies and IAM permissions.

## Outputs

The module exposes these outputs:

| Output | Description |
|---|---|
| `cluster_identifier` | Aurora PostgreSQL cluster identifier |
| `cluster_arn` | Cluster ARN |
| `cluster_endpoint` | Writer endpoint for read/write connections |
| `reader_endpoint` | Reader endpoint for read-only connections |
| `port` | Database connection port |
| `master_user_secret_arn` | ARN of the RDS-managed master credentials secret, when available |
| `writer_instance_id` | Writer DB instance identifier |
| `reader_instance_ids` | List of reader DB instance identifiers |
| `db_subnet_group_name` | DB subnet group name |
| `db_security_group_id` | Database security group ID |
| `cluster_parameter_group_name` | Custom cluster parameter group name, or `null` if not created |
| `instance_parameter_group_name` | Custom instance parameter group name, or `null` if not created |
| `parameter_group_family` | Selected Aurora PostgreSQL parameter group family |

When called through the repository root module, the root `outputs.tf` should reference the child outputs and can expose them under root-level names such as `aurora_postgresql_cluster_endpoint`.

## Deployment workflow

1. Configure the AWS provider in the Terraform root.
2. Set required inputs in the root `terraform.tfvars` or another approved input mechanism.
3. Run `terraform init`.
4. Run `terraform fmt -check -recursive`.
5. Run `terraform validate`.
6. Run `terraform plan` and inspect all proposed resources and changes.
7. Confirm the AWS account, Region, network IDs, instance count, and security/cost implications.
8. Apply only after the plan is reviewed and approved.
9. Use Terraform outputs to retrieve the cluster endpoint and related identifiers.

For production, use remote state with locking and controlled state access. Do not commit state files, credentials, or sensitive environment-specific data to source control.

## Destroy and snapshot considerations

Destroying the module can remove the Aurora cluster and DB instances. With `deletion_protection = true`, protection must be handled before deletion can complete. When `skip_final_snapshot = false`, provide a valid `final_snapshot_identifier`. Review snapshot retention and recovery requirements before destroy operations.

Do not run `terraform destroy` as a routine test against shared or production infrastructure. Verify the active Terraform root and state before destructive operations.

## Troubleshooting

| Symptom | Checks |
|---|---|
| Subnet validation fails | Confirm subnet IDs exist in the target Region, belong to `vpc_id`, are unique, and span at least two AZs. |
| Explicit AZ validation fails | Ensure `availability_zones` values are unique and represented by supplied subnets; check `enable_availability_zones`. |
| Parameter group family error | Ensure `parameter_group_family` matches the family derived from `engine_version`, or leave it `null` to derive automatically. |
| Custom parameter validation fails | Enable the corresponding custom-parameter switch and confirm parameters are valid for the engine family. |
| Final snapshot validation fails | When `skip_final_snapshot = false`, set `final_snapshot_identifier`; when true, leave it `null`. |
| Advanced Database Insights validation fails | Enable Performance Insights and set retention to at least 465 days; verify AWS service requirements and costs. |
| Public accessibility validation fails | Both public-access variables must be true; still verify organizational approval and network prerequisites. |
| Serverless capacity validation fails | Use values in 0.5 increments from 0.5 to 256 ACUs, with minimum no greater than maximum. |
| Engine version unavailable | Verify the Aurora PostgreSQL version is supported in the selected Region and account. |
| IAM or KMS access denied | Check caller permissions, role trust policies, KMS key policies, and key usage permissions. |

## Maintainer notes

Keep this README synchronized with `variables.tf`, `outputs.tf`, and resource files whenever inputs, defaults, validations, or outputs change. Review documentation updates alongside code changes in pull requests.
