# Aurora MySQL – Terraform Module Guide

This document explains how to deploy and manage the **Aurora MySQL** child module through the repository's **root Terraform configuration**.

> **Important:** Run Terraform commands from the repository root (`terraform-aws-rds/`). The root configuration owns the AWS provider configuration and Terraform state. Do not run the root deployment workflow from inside `modules/aurora-mysql/`.

## 1. Repository structure

```text
terraform-aws-rds/
├── modules/
│   ├── aurora-mysql/
│   │   ├── cluster.tf
│   │   ├── iam.tf
│   │   ├── instances.tf
│   │   ├── locals.tf
│   │   ├── parameter-groups.tf
│   │   ├── security-groups.tf
│   │   ├── subnet-groups.tf
│   │   ├── validations.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── aurora-postgresql/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
├── aurora-mysql-readme.md
└── aurora-postgresql-readme.md
```

The child module contains the reusable Aurora MySQL resources. The root files provide environment inputs, provider configuration, module selection, and root outputs.

## 2. What this module creates

Depending on the selected inputs, the module can create:

- An Aurora MySQL DB cluster.
- One writer DB instance and the configured number of reader instances.
- A DB subnet group using subnets from an existing VPC.
- A database security group and configured inbound rules.
- Custom cluster and DB instance parameter groups, when enabled.
- An IAM role and policy attachment for RDS Enhanced Monitoring, when required.
- RDS-managed master credentials in AWS Secrets Manager.
- Supporting Terraform validation resources.

The module does **not** create the VPC or application subnets. Supply existing network IDs.

## 3. Prerequisites

Before planning a deployment, confirm:

1. Terraform `>= 1.5.0` is installed.
2. AWS provider `~> 6.0` is configured by the root module.
3. AWS credentials point to the intended account.
4. The execution identity has the required RDS, EC2 networking, IAM, KMS, and Secrets Manager permissions.
5. The VPC and at least two unique subnets exist in the target Region and span at least two Availability Zones.
6. The Aurora MySQL engine version and DB instance class are supported in the target Region.
7. Required KMS key policies and permissions are in place if customer-managed keys are used.
8. Database ingress sources have been reviewed and approved.

The current root provider configuration in `versions.tf` selects `ap-south-1`. Change it only when the deployment target requires another Region.

## 4. Enable or disable Aurora MySQL

The root module uses a Boolean switch to decide whether to instantiate Aurora MySQL:

```hcl
enable_aurora_mysql = true
```

- `true`: Terraform includes the Aurora MySQL child module.
- `false`: Terraform does not instantiate the Aurora MySQL child module.

For an Aurora MySQL-only test, use:

```hcl
enable_aurora_postgresql = false
enable_aurora_mysql      = true
```

For a PostgreSQL-only test, reverse the values. To plan both engines together, set both to `true`.

> **State warning:** Changing a module switch from `true` to `false` after resources have been applied can cause Terraform to plan destruction of that module's managed resources. Always inspect the plan before applying. Do not toggle a deployed module off merely to run an isolated test.

## 5. Configure root inputs

The root `variables.tf` declares prefixed inputs for this engine. The root `main.tf` maps those values to the child module's unprefixed variables.

The main inputs are grouped below.

| Input group | Root variable examples | Purpose |
|---|---|---|
| Enablement | `enable_aurora_mysql` | Include or exclude the module |
| Cluster | `aurora_mysql_name`, `aurora_mysql_engine_version` | Cluster identifier and engine version |
| Deployment and instances | `aurora_mysql_deployment_mode`, `aurora_mysql_instance_class`, `aurora_mysql_reader_instance_class`, `aurora_mysql_reader_count` | Provisioned/Serverless selection and DB instance sizing |
| Network | `aurora_mysql_vpc_id`, `aurora_mysql_subnet_ids`, `aurora_mysql_ingress_rules` | Existing VPC, subnets, and inbound access |
| Availability Zones | `aurora_mysql_enable_availability_zones`, `aurora_mysql_availability_zones` | Optional explicit AZ selection |
| Database | `aurora_mysql_database_name`, `aurora_mysql_master_username` | Initial database and master username |
| Encryption | `aurora_mysql_storage_encrypted`, `aurora_mysql_kms_key_id`, `aurora_mysql_secret_kms_key_id` | Storage and secret encryption |
| Backups/lifecycle | `aurora_mysql_backup_retention_period`, `aurora_mysql_deletion_protection`, `aurora_mysql_skip_final_snapshot`, `aurora_mysql_final_snapshot_identifier` | Backup and deletion behavior |
| Parameter groups | `aurora_mysql_use_custom_parameter_groups`, `aurora_mysql_enable_custom_cluster_parameters`, `aurora_mysql_enable_custom_instance_parameters`, `aurora_mysql_cluster_parameters`, `aurora_mysql_instance_parameters` | Custom DB parameters |
| Monitoring/logs | `aurora_mysql_monitoring_interval`, `aurora_mysql_monitoring_role_arn`, `aurora_mysql_enabled_cloudwatch_logs_exports` | Enhanced Monitoring and CloudWatch log exports |
| Insights | `aurora_mysql_performance_insights_enabled`, `aurora_mysql_performance_insights_retention_period`, `aurora_mysql_database_insights_mode` | Performance and Database Insights |
| Network options | `aurora_mysql_network_type`, `aurora_mysql_publicly_accessible`, `aurora_mysql_allow_public_access` | IP mode and public-access controls |
| Optional features | `aurora_mysql_enable_http_endpoint`, `aurora_mysql_iam_database_authentication_enabled` | Data API and IAM DB authentication |
| Tags | `aurora_mysql_tags` | Resource tags |

Review the actual root `variables.tf` for defaults and validation rules. The child module's unprefixed variables are not the names to put in the root `terraform.tfvars`.

### Current POC example

The supplied root `terraform.tfvars` uses these Aurora MySQL test settings:

```hcl
enable_aurora_mysql = true

aurora_mysql_name           = "dev-aurora-mysql-test"
aurora_mysql_engine_version = "8.0.mysql_aurora.3.08.2"

aurora_mysql_deployment_mode       = "provisioned"
aurora_mysql_instance_class        = "db.r7g.large"
aurora_mysql_reader_instance_class = null
aurora_mysql_reader_count          = 1

aurora_mysql_vpc_id = "vpc-REPLACE_WITH_YOUR_VPC_ID"
aurora_mysql_subnet_ids = [
  "subnet-REPLACE_WITH_SUBNET_A",
  "subnet-REPLACE_WITH_SUBNET_B",
  "subnet-REPLACE_WITH_SUBNET_C"
]

aurora_mysql_ingress_rules = {}

aurora_mysql_database_name   = "devdb"
aurora_mysql_master_username = "dbadmin"

aurora_mysql_storage_encrypted = true
aurora_mysql_storage_type      = "aurora"

aurora_mysql_backup_retention_period     = 7
aurora_mysql_deletion_protection         = false
aurora_mysql_skip_final_snapshot         = false
aurora_mysql_final_snapshot_identifier   = "dev-aurora-mysql-test-final"

aurora_mysql_monitoring_interval = 60
aurora_mysql_enabled_cloudwatch_logs_exports = [
  "error",
  "slowquery"
]

aurora_mysql_performance_insights_enabled          = true
aurora_mysql_performance_insights_retention_period = 7
aurora_mysql_database_insights_mode                = "standard"

aurora_mysql_publicly_accessible = false
aurora_mysql_allow_public_access  = false

aurora_mysql_tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}
```

Replace the example VPC and subnet IDs with valid IDs in the intended account and Region. The engine version and instance class must be checked for regional availability before deployment. Do not commit environment-specific IDs if repository policy treats them as sensitive.

## 6. Deployment modes

The child Aurora MySQL module supports:

### Provisioned

```hcl
deployment_mode = "provisioned"
instance_class  = "db.r7g.large"
reader_count    = 1
```

The module creates a writer using `instance_class` and the configured number of readers. A reader uses `reader_instance_class` when supplied; otherwise it uses the writer class. `reader_count = 0` creates only the writer.

### Aurora Serverless v2

The child module documents `deployment_mode = "serverless_v2"` and capacity inputs `serverless_min_capacity` and `serverless_max_capacity`. However, the current root `main.tf` does **not** pass those capacity inputs to the MySQL child module. Therefore, Serverless v2 should not be considered fully wired through the root orchestration layer until those mappings are added and validated. The current POC uses `provisioned` mode.

## 7. Network and security

- Supply an existing VPC and at least two unique subnets in at least two Availability Zones.
- The module validates that the selected subnets belong to the supplied VPC and span the required AZs.
- Aurora MySQL uses TCP port `3306`.
- An empty `aurora_mysql_ingress_rules = {}` means this input creates no explicit inbound rules.
- When access is required, use a narrowly scoped application security group or approved IPv4 CIDR.
- Keep `publicly_accessible = false` unless public access is explicitly required and approved. The module requires both `publicly_accessible` and `allow_public_access` to be `true` before permitting public accessibility.
- Do not place passwords or secret values in `.tf` or `.tfvars` files. The module uses RDS-managed master credentials in Secrets Manager.

## 8. Parameter groups, monitoring, and logs

Custom cluster and instance parameter groups are controlled by `aurora_mysql_use_custom_parameter_groups` and the corresponding custom-parameter enablement switches. Supply only parameter names and values supported by the selected Aurora MySQL parameter group family.

Enhanced Monitoring is controlled by `aurora_mysql_monitoring_interval`. The documented valid values are `0`, `1`, `5`, `10`, `15`, `30`, and `60` seconds. When monitoring is enabled and no existing role ARN is supplied, the child module creates a monitoring role and attaches the AWS-managed `AmazonRDSEnhancedMonitoringRole` policy.

The child module documents these CloudWatch log exports: `audit`, `error`, `general`, and `slowquery`. Confirm support for the selected engine configuration.

## 9. Root outputs

The root `outputs.tf` exposes these Aurora MySQL outputs:

| Root output | Description |
|---|---|
| `aurora_mysql_cluster_identifier` | Cluster identifier |
| `aurora_mysql_cluster_arn` | Cluster ARN |
| `aurora_mysql_cluster_endpoint` | Writer/cluster endpoint |
| `aurora_mysql_reader_endpoint` | Reader endpoint |
| `aurora_mysql_port` | Database port |
| `aurora_mysql_master_user_secret_arn` | ARN of the RDS-managed master secret |
| `aurora_mysql_writer_instance_id` | Writer DB instance identifier |
| `aurora_mysql_reader_instance_ids` | Reader DB instance identifiers |
| `aurora_mysql_db_subnet_group_name` | DB subnet group name |
| `aurora_mysql_db_security_group_id` | Database security group ID |
| `aurora_mysql_cluster_parameter_group_name` | Cluster parameter group name, if created |
| `aurora_mysql_instance_parameter_group_name` | Instance parameter group name, if created |
| `aurora_mysql_parameter_group_family` | Effective parameter group family |

When Aurora MySQL is disabled, the root outputs use `try()` and return `null` (or an empty list for reader instance IDs).

## 10. Run Terraform

Run all commands below from the repository root.

### Format

```powershell
terraform fmt -recursive
```

### Initialize

```powershell
terraform init
```

### Validate

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

### Plan Aurora MySQL only

Set the switches in `terraform.tfvars`:

```hcl
enable_aurora_postgresql = false
enable_aurora_mysql      = true
```

Then run:

```powershell
terraform plan
```

For the supplied POC inputs, the reviewed MySQL-only plan reported:

```text
Plan: 11 to add, 0 to change, 0 to destroy.
```

This is the plan result from the test run, not a guarantee for other inputs or future runs. A successful plan does not prove AWS will accept every setting at apply time.

### Plan both engines

Set both switches to `true` and run `terraform plan`. Review the resources for both modules separately.

## 11. Apply and destroy safety

Do not run `terraform apply` until the complete plan, account, Region, engine version, instance class, networking, IAM permissions, estimated cost, backup settings, and lifecycle settings have been reviewed and approved.

Before a destroy operation:

1. Confirm the active root directory and Terraform state.
2. Confirm the exact cluster and DB instances targeted.
3. Review deletion protection and final snapshot settings.
4. Confirm the snapshot identifier and recovery requirements.
5. Review the complete destroy plan and obtain approval.

Do not disable deletion protection or skip a final snapshot just to make a destroy operation succeed.

## 12. Troubleshooting

| Symptom | What to check |
|---|---|
| Engine version unavailable | Verify Aurora MySQL version availability in the target Region. |
| Parameter group family error | Confirm the family matches the selected Aurora MySQL engine version. |
| Subnet validation error | Check VPC ownership, unique subnet IDs, and AZ coverage. |
| Ingress rule validation error | Each rule must specify exactly one source: CIDR or source security group. |
| Final snapshot validation error | If `skip_final_snapshot = false`, provide a valid final snapshot identifier. If true, the identifier must be null. |
| Enhanced Monitoring IAM error | Check role trust policy, role ARN, and IAM permissions to create/attach the managed policy. |
| KMS access denied | Review the key policy, IAM permissions, key status, and account/Region alignment. |
| Plan succeeds but apply fails | Check the AWS error, regional service availability, quotas, IAM permissions, and feature compatibility. |

## 13. Maintenance

Keep this guide synchronized with `modules/aurora-mysql/variables.tf`, `outputs.tf`, resource files, and the root `main.tf`, `variables.tf`, and `outputs.tf`. Update the documentation whenever inputs, defaults, validations, outputs, or root mappings change.
