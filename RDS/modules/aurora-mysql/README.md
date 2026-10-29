# Terraform AWS Aurora MySQL Module

## Overview

This module provisions an Amazon Aurora MySQL database cluster using Terraform. It supports provisioned and Serverless v2 deployment modes, configurable writer and reader instances, networking, encryption, backups, monitoring, parameter groups, and database security settings.

The module is designed to be reusable across AWS environments and can be used independently for testing or integrated into a root Terraform orchestration module.

## Scope and Naming Convention

This repository uses two naming conventions depending on the module layer:

- **Child module:** Uses unprefixed input variables, such as `name`, `engine_version`, `vpc_id`, and `reader_count`.
- **Root orchestration module:** Uses prefixed variables, such as `aurora_mysql_name`, `aurora_mysql_engine_version`, `aurora_mysql_vpc_id`, and `aurora_mysql_reader_count`.

The root module maps its prefixed variables to the corresponding unprefixed inputs of this child module.

## Contents

- Overview
- Features
- Repository placement
- Prerequisites
- Deployment modes
- Quick start
- Run Terraform safely
- Input variables
- Important variable combinations
- Network and security
- Outputs
- Deployment workflow
- Destroy and snapshot considerations
- Troubleshooting
- Maintainer notes

## Features

- Aurora MySQL cluster provisioning.
- Provisioned and Aurora Serverless v2 deployment modes.
- One writer instance and configurable reader instances.
- Existing VPC and subnet integration.
- DB subnet group and security group creation.
- Configurable inbound access rules.
- RDS-managed master credentials in AWS Secrets Manager.
- Optional KMS encryption for cluster storage and the managed secret.
- Configurable backup retention and maintenance windows.
- Deletion protection and final snapshot controls.
- Optional custom cluster and instance parameter groups.
- Enhanced Monitoring with an existing or module-created IAM role.
- CloudWatch log exports.
- Performance Insights and Database Insights configuration.
- Optional IAM database authentication and HTTP endpoint.
- IPv4 and dual-stack network configuration.
- Resource tagging and input validation.

## Repository Placement

Expected module structure:

```text
terraform-aws-rds/
├── modules/
│   ├── aurora-postgresql/
│   └── aurora-mysql/
│       ├── versions.tf
│       ├── variables.tf
│       ├── locals.tf
│       ├── validations.tf
│       ├── subnet-groups.tf
│       ├── security-groups.tf
│       ├── iam.tf
│       ├── parameter-groups.tf
│       ├── cluster.tf
│       ├── instances.tf
│       └── outputs.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
└── README.md
```

The root-level files are part of the proposed integration structure; their exact names may differ in your repository.

## Prerequisites

Before deploying the module, ensure that the following prerequisites are satisfied.

1. Terraform `>= 1.5.0`.
2. AWS provider version `~> 6.0`.
3. AWS credentials with the required RDS, EC2 networking, IAM, KMS, and Secrets Manager permissions.
4. An existing VPC.
5. At least two unique subnets spanning at least two Availability Zones.
6. An Aurora MySQL engine version supported in the target AWS Region.
7. An instance class compatible with the selected engine version.
8. Appropriate KMS key permissions if customer-managed keys are used.
9. An appropriate database access strategy and approved security group rules.

The module does not create the VPC or application subnets. It uses the VPC and subnet IDs provided through its input variables.

## Deployment Modes

The module supports two deployment modes through `deployment_mode`.

### 1. Provisioned

```hcl
deployment_mode = "provisioned"
instance_class  = "db.r7g.large"
reader_count    = 1
```

In provisioned mode, the module creates a writer instance and the configured number of reader instances using the selected instance classes.

If `reader_count = 0`, only the writer instance is created. If `reader_count = 1`, the cluster contains one writer and one reader.

The selected instance class must be supported by the chosen Aurora MySQL engine version and AWS Region.

### 2. Aurora Serverless v2

```hcl
deployment_mode        = "serverless_v2"
instance_class         = "db.serverless"
reader_count           = 1
serverless_min_capacity = 0.5
serverless_max_capacity = 2
```

In Serverless v2 mode, the module uses `db.serverless` for the writer and reader instances and configures the cluster's Serverless v2 scaling capacity.

The module validates that the minimum and maximum capacities are between 0.5 and 256 ACUs, in increments of 0.5, and that the minimum does not exceed the maximum.

Confirm that the selected Aurora MySQL version supports Serverless v2 in the target Region before deployment.

## Quick Start

### Option A: Direct child module

Use this approach to test the module independently.

Example `main.tf`:

```hcl
module "aurora_mysql" {
  source = "./modules/aurora-mysql"

  name           = "dev-aurora-mysql-test"
  engine_version = "8.0.mysql_aurora.3.08.2"

  deployment_mode      = "provisioned"
  instance_class       = "db.r7g.large"
  reader_instance_class = null
  reader_count         = 1

  vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

  subnet_ids = [
    "subnet-xxxxxxxxxxxxxxxxx",
    "subnet-yyyyyyyyyyyyyyyyy"
  ]

  ingress_rules = {}

  database_name   = "devdb"
  master_username = "dbadmin"

  storage_encrypted = true
  storage_type      = "aurora"

  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false
  final_snapshot_identifier = "dev-aurora-mysql-test-final"

  monitoring_interval = 60

  enabled_cloudwatch_logs_exports = [
    "error",
    "slowquery"
  ]

  performance_insights_enabled = true
  performance_insights_retention_period = 7

  database_insights_mode = "standard"
  network_type           = "IPV4"

  publicly_accessible = false
  allow_public_access = false

  tags = {
    Environment = "Dev"
    Project     = "RDS-Terraform-Module"
    ManagedBy   = "Terraform"
  }
}
```

**Important:** Replace the example VPC and subnet IDs with valid resources in your AWS account. Confirm that the example engine version and instance class are supported in your target Region. The snapshot identifier must be unique when creating the final snapshot.

The module manages the master password through RDS and AWS Secrets Manager. Do not add a plaintext master password to the configuration.

### Option B: Root orchestration layer

When integrating the module into the root Terraform configuration, use the root module's prefixed inputs.

Example:

```hcl
module "aurora_mysql" {
  source = "./modules/aurora-mysql"

  name           = var.aurora_mysql_name
  engine_version = var.aurora_mysql_engine_version

  deployment_mode = var.aurora_mysql_deployment_mode
  instance_class  = var.aurora_mysql_instance_class
  reader_count    = var.aurora_mysql_reader_count

  vpc_id     = var.aurora_mysql_vpc_id
  subnet_ids = var.aurora_mysql_subnet_ids

  ingress_rules = var.aurora_mysql_ingress_rules

  database_name   = var.aurora_mysql_database_name
  master_username = var.aurora_mysql_master_username

  tags = var.aurora_mysql_tags
}
```

This is an integration illustration, not a complete list of required arguments. Ensure that every required child-module input is mapped and that the root variable names match the actual root `variables.tf`.

## Run Terraform Safely

Run these commands from the child module directory during standalone testing.

### 1. Format the configuration

```bash
terraform fmt -recursive
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate the configuration

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

### 4. Review the execution plan

```bash
terraform plan
```

Review the plan carefully before making any changes.

For the current test configuration, Terraform reported:

```text
Plan: 11 to add, 0 to change, 0 to destroy.
```

This confirms that Terraform generated a plan for the supplied configuration. It does not confirm that AWS will accept every resource setting during deployment.

**Do not run `terraform apply` until the plan, engine version, networking, IAM permissions, costs, and snapshot settings have been reviewed and deployment has been explicitly approved.**

When integrating the module into the root configuration, use the root provider and backend configuration. Remove temporary standalone testing files such as the child `provider.tf` and `terraform.tfvars` when they are no longer required. Keep `versions.tf` in the child module to declare its Terraform and provider requirements.

## Input Variables

The following sections describe the module's main inputs. Defaults and validation rules should be checked against the current `variables.tf` before changing the module.

### 1. Cluster identity and deployment

| Variable | Required | Default | Description |
|---|---|---|---|
| `name` | Yes | — | Cluster naming value used to derive resource names. |
| `engine_version` | Yes | — | Aurora MySQL engine version. |
| `deployment_mode` | No | `provisioned` | Selects provisioned or `serverless_v2`. |
| `instance_class` | Yes | — | Writer instance class in provisioned mode. |
| `reader_instance_class` | No | `null` | Reader class; defaults to the writer class in provisioned mode. |
| `reader_count` | No | `1` | Number of reader instances, from 0 to 15. |
| `enable_availability_zones` | No | `false` | Enables explicit Availability Zone configuration. |
| `availability_zones` | No | `[]` | Optional Availability Zone list. |

### 2. VPC, subnets, Availability Zones, and inbound access

| Variable | Required | Default | Description |
|---|---|---|---|
| `vpc_id` | Yes | — | Existing VPC ID. |
| `subnet_ids` | Yes | — | Existing subnet IDs used for the DB subnet group. |
| `ingress_rules` | No | `{}` | Map of inbound security group rules. |

The module validates that the supplied subnets belong to the specified VPC, are unique, and span at least two distinct Availability Zones.

An ingress rule contains a description and exactly one source:

- `cidr_ipv4`
- `source_security_group_id`

Example:

```hcl
ingress_rules = {
  application = {
    description              = "MySQL access from application subnet"
    cidr_ipv4                = "10.20.10.0/24"
    source_security_group_id = null
  }
}
```

Use only one source field per rule. The module uses TCP port `3306` for Aurora MySQL ingress. An empty map creates no explicit inbound rules.

### 3. Database and credentials

| Variable | Required | Default | Description |
|---|---|---|---|
| `database_name` | No | `null` | Optional initial database name. |
| `master_username` | No | `dbadmin` | Master username. |

The module configures RDS-managed master credentials using `manage_master_user_password = true`. The generated password is managed through AWS Secrets Manager.

The module does not accept a plaintext master password as an input. Retrieve the secret only through approved IAM access and the organization's secret-handling process.

### 4. Storage and encryption

| Variable | Required | Default | Description |
|---|---|---|---|
| `storage_encrypted` | No | `true` | Enables storage encryption. |
| `kms_key_id` | No | `null` | Optional KMS key for cluster storage. |
| `secret_kms_key_id` | No | `null` | Optional KMS key for the managed secret. |
| `storage_type` | No | `aurora` | Storage type: `aurora` or `aurora-iopt1`. |

If a storage KMS key is specified, storage encryption must remain enabled. Confirm the selected storage type is supported by the target cluster configuration.

### 5. Backups, maintenance, and deletion lifecycle

| Variable | Required | Default | Description |
|---|---|---|---|
| `backup_retention_period` | No | `7` | Backup retention in days; validated from 1 to 35. |
| `preferred_backup_window` | No | `null` | Preferred backup window. |
| `preferred_maintenance_window` | No | `null` | Preferred maintenance window. |
| `deletion_protection` | No | `true` | Protects the cluster from deletion. |
| `skip_final_snapshot` | No | `false` | Controls whether a final snapshot is skipped. |
| `final_snapshot_identifier` | No | `null` | Identifier for the final snapshot. |
| `apply_immediately` | No | `false` | Controls immediate application of supported modifications. |
| `auto_minor_version_upgrade` | No | `true` | Controls automatic minor upgrades for DB instances. |

When `skip_final_snapshot = false`, a non-null `final_snapshot_identifier` is required. When `skip_final_snapshot = true`, the identifier must be null.

Deletion protection should be disabled only when deletion is approved and the operational recovery requirements have been reviewed.

### 6. Parameter groups

| Variable | Required | Default | Description |
|---|---|---|---|
| `use_custom_parameter_groups` | No | `true` | Enables creation of custom cluster and instance parameter groups. |
| `create_custom_cluster_parameter_group` | No | `false` | Enables the custom cluster parameter configuration. |
| `create_custom_instance_parameter_group` | No | `false` | Enables the custom instance parameter configuration. |
| `parameter_group_family` | No | `null` | Optional explicit parameter group family. |
| `cluster_parameters` | No | `{}` | Map of cluster parameters. |
| `instance_parameters` | No | `{}` | Map of instance parameters. |

Parameter values use the following object structure:

```hcl
cluster_parameters = {
  example_parameter = {
    value        = "example-value"
    apply_method = "pending-reboot"
  }
}
```

The example illustrates the input structure only. Replace the parameter name and value with a parameter supported by the selected Aurora MySQL family.

Parameter names, values, and apply methods must be checked against the documentation for the selected engine version. Do not copy PostgreSQL parameter settings into the MySQL module.

The current implementation derives the parameter group family for recognized Aurora MySQL 8.0 and 8.4 engine-version formats. Confirm the family for any other engine version before enabling custom parameter groups.

### 7. Enhanced Monitoring and CloudWatch logs

| Variable | Required | Default | Description |
|---|---|---|---|
| `monitoring_interval` | No | `60` | Enhanced Monitoring interval in seconds. |
| `monitoring_role_arn` | No | `null` | Existing Enhanced Monitoring role ARN, if supplied. |
| `enabled_cloudwatch_logs_exports` | No | `["error", "slowquery"]` | Aurora MySQL log exports. |

Valid monitoring intervals are `0`, `1`, `5`, `10`, `15`, `30`, and `60`.

An interval of `0` disables Enhanced Monitoring. If the interval is greater than zero and no existing role ARN is supplied, the module creates a monitoring role and attaches the AWS-managed `AmazonRDSEnhancedMonitoringRole` policy.

The current module accepts these log export values:

- `audit`
- `error`
- `general`
- `slowquery`

Confirm that the selected log exports are supported by the target Aurora MySQL engine version.

### 8. Performance Insights and Database Insights

| Variable | Required | Default | Description |
|---|---|---|---|
| `performance_insights_enabled` | No | `true` | Enables Performance Insights. |
| `performance_insights_kms_key_id` | No | `null` | Optional KMS key for Performance Insights data. |
| `performance_insights_retention_period` | No | `7` | Performance Insights retention period. |
| `database_insights_mode` | No | `standard` | Database Insights mode: `standard` or `advanced`. |

The current validation requires Performance Insights to be enabled for advanced Database Insights and requires a retention period of at least 465 days for advanced mode.

Review feature availability, retention options, and applicable costs before selecting advanced monitoring.

### 9. Networking and optional database features

| Variable | Required | Default | Description |
|---|---|---|---|
| `enable_http_endpoint` | No | `false` | Enables the cluster HTTP endpoint where supported. |
| `iam_database_authentication_enabled` | No | `false` | Enables IAM database authentication. |
| `network_type` | No | `IPV4` | Network type: `IPV4` or `DUAL`. |
| `publicly_accessible` | No | `false` | Configures public accessibility for DB instances. |
| `allow_public_access` | No | `false` | Additional explicit approval flag required for public access. |

Public accessibility is permitted by the module only when both `publicly_accessible` and `allow_public_access` are true.

Prefer private database instances and narrowly scoped ingress rules unless public access is an explicitly approved requirement.

Confirm support for the HTTP endpoint, network type, and IAM authentication settings for the selected engine version and deployment mode.

### 10. Tags

| Variable | Required | Default | Description |
|---|---|---|---|
| `tags` | No | `{}` | Additional tags applied to supported resources. |

The module merges user-provided tags with module-managed tags, including `ManagedBy`, `Engine`, and `Name`. Avoid relying on user-supplied values to override module-managed tags.

## Important Variable Combinations

| Requirement | Configuration |
|---|---|
| Writer only | `reader_count = 0` |
| Writer and one reader | `reader_count = 1` |
| Provisioned cluster | `deployment_mode = "provisioned"` |
| Serverless v2 cluster | `deployment_mode = "serverless_v2"` |
| Disable Enhanced Monitoring | `monitoring_interval = 0` |
| Use an existing monitoring role | Set `monitoring_role_arn` to the approved role ARN. |
| Enable custom parameter groups | `use_custom_parameter_groups = true` and supply a supported parameter group family. |
| Skip the final snapshot | `skip_final_snapshot = true` and `final_snapshot_identifier = null` |
| Require a final snapshot | `skip_final_snapshot = false` and provide a valid, unique `final_snapshot_identifier`. |
| Permit public access | Set both `publicly_accessible = true` and `allow_public_access = true`; review security approval first. |
| Use advanced Database Insights | Enable Performance Insights and configure retention of at least 465 days. |

## Network and Security

The module creates the database security group and DB subnet group, but it does not create the VPC or the application subnets.

### Network requirements

- Use at least two unique subnets.
- Ensure the subnets span at least two Availability Zones.
- Ensure every subnet belongs to the supplied VPC.
- Configure routing, DNS, and connectivity according to the application architecture.
- Keep the database private unless a documented requirement justifies public access.

### Security group requirements

The module uses TCP port `3306` for inbound MySQL traffic.

Keep `ingress_rules` empty when no explicit inbound access is required. When access is needed, prefer a source security group representing the application tier rather than a broad CIDR range.

Example:

```hcl
ingress_rules = {
  application = {
    description              = "Allow MySQL from application security group"
    cidr_ipv4                = null
    source_security_group_id = "sg-xxxxxxxxxxxxxxxxx"
  }
}
```

Use a valid security group ID from the intended VPC.

### Credential and encryption requirements

- Use RDS-managed master credentials and Secrets Manager.
- Do not commit credentials or secret values to source control.
- Grant KMS permissions only to the required principals.
- Restrict access to the managed secret.
- Review the effective IAM permissions for Terraform execution.

## Outputs

The module exposes the following outputs:

| Output | Description |
|---|---|
| `cluster_identifier` | Aurora MySQL cluster identifier. |
| `cluster_arn` | ARN of the Aurora cluster. |
| `cluster_endpoint` | Writer/cluster endpoint for database connections. |
| `reader_endpoint` | Reader endpoint for read-oriented connections. |
| `port` | Database port, normally `3306` for Aurora MySQL. |
| `master_user_secret_arn` | ARN of the RDS-managed master secret. |
| `writer_instance_id` | Writer DB instance identifier. |
| `reader_instance_ids` | List of reader DB instance identifiers. |
| `db_subnet_group_name` | DB subnet group name. |
| `db_security_group_id` | Created database security group ID. |
| `cluster_parameter_group_name` | Custom cluster parameter group name, when created. |
| `instance_parameter_group_name` | Custom instance parameter group name, when created. |
| `parameter_group_family` | Effective parameter group family. |

Use the cluster endpoint for writer connections and the reader endpoint for read traffic where appropriate. Application connection handling should account for failover and endpoint DNS changes.

## Deployment Workflow

Follow this workflow for a new deployment.

1. Confirm the target AWS account and Region.
2. Verify the Aurora MySQL engine version and instance class.
3. Validate VPC and subnet IDs.
4. Review the ingress rules and database access requirements.
5. Review KMS keys and IAM permissions.
6. Confirm backup retention, deletion protection, and final snapshot settings.
7. Review monitoring and log export requirements.
8. Run `terraform fmt -recursive`.
9. Run `terraform init`.
10. Run `terraform validate`.
11. Run `terraform plan`.
12. Review the complete plan with the appropriate reviewer.
13. Run `terraform apply` only after explicit approval.
14. Validate the cluster, writer and reader instances, endpoints, secret, logs, and connectivity.
15. Record deployment details and any follow-up tasks.

For root-module integration, ensure that provider configuration, state management, and environment-specific variable values are supplied by the root configuration.

## Destroy and Snapshot Considerations

The module enables deletion protection by default and configures final snapshot behavior through explicit variables.

Before destroying a cluster:

1. Obtain the required approval.
2. Review whether deletion protection must be disabled.
3. Confirm the final snapshot identifier and snapshot retention requirements.
4. Check dependencies, application connections, and recovery requirements.
5. Review the destroy plan.
6. Confirm that the cluster and related resources are the intended deletion targets.

Do not disable deletion protection or skip a final snapshot merely to make Terraform destroy succeed. Follow the organization's change management and data retention requirements.

## Troubleshooting

### 1. Engine version is unavailable

**Possible cause:** The requested Aurora MySQL version is not supported in the selected Region or is no longer available for the requested configuration.

**Resolution:** Verify the engine version in the target Region and update `engine_version` to an available, approved version. Recheck instance class and deployment mode compatibility.

### 2. Parameter group family mismatch

**Possible cause:** The configured parameter group family does not match the selected Aurora MySQL engine family.

**Resolution:** Confirm the family supported by the selected engine version. Review `parameter_group_family` and any custom parameter group configuration before planning again.

### 3. Subnet validation fails

**Possible cause:** The subnet IDs are duplicated, belong to another VPC, or do not span at least two Availability Zones.

**Resolution:** Supply at least two unique subnet IDs from the specified VPC and confirm that they cover at least two Availability Zones.

### 4. Security group ingress validation fails

**Possible cause:** An ingress rule specifies neither source field or specifies both `cidr_ipv4` and `source_security_group_id`.

**Resolution:** Specify exactly one source for each ingress rule and verify the source is appropriate for the intended application.

### 5. Final snapshot validation fails

**Possible cause:** The final snapshot identifier is missing when snapshots are required or is populated when `skip_final_snapshot` is true.

**Resolution:** Set `skip_final_snapshot` and `final_snapshot_identifier` to a valid combination, as documented under backups and lifecycle settings.

### 6. Enhanced Monitoring role errors

**Possible cause:** The supplied monitoring role is invalid or the Terraform execution identity lacks permission to create or attach the required IAM resources.

**Resolution:** Verify the existing role ARN, trust relationship, and IAM permissions. If the module creates the role, review the role and policy attachment in the plan.

### 7. KMS access denied

**Possible cause:** The Terraform execution identity or RDS service does not have the required access to the selected KMS key.

**Resolution:** Review the key policy, IAM permissions, key status, and account/Region alignment.

### 8. Terraform plan succeeds but deployment fails

**Possible cause:** Terraform validation does not check every AWS-side constraint, including all engine-version availability, quota, IAM, and feature-compatibility requirements.

**Resolution:** Review the AWS error message, verify the target Region and configuration support, and update the module inputs or permissions as appropriate. Re-run `terraform plan` after changes.

## Maintainer Notes

- Keep the child module inputs unprefixed.
- Use `aurora_mysql_` prefixes for root orchestration variables.
- Keep provider configuration and backend configuration in the root module for integrated deployments.
- Keep `versions.tf` in the child module to declare Terraform and provider requirements.
- Avoid hardcoding account IDs, subnet IDs, VPC IDs, KMS key IDs, and environment-specific values in reusable module code.
- Verify engine versions, instance classes, parameter group families, parameter names, and log exports against the target Aurora MySQL version.
- Preserve validation for subnet placement, security group ingress, snapshots, encryption, monitoring, and deployment mode.
- Test changes with formatting, validation, and plan before considering deployment.
- Do not run apply or destroy operations without the required approval.

