# Aurora PostgreSQL – Terraform Module Guide

This document explains how to deploy and manage the **Aurora PostgreSQL** child module through the repository's **root Terraform configuration**.

> **Important:** Run Terraform commands from the repository root (`terraform-aws-rds/`). The root configuration owns the AWS provider configuration and Terraform state. Do not run the root deployment workflow from inside `modules/aurora-postgresql/`.

## 1. Repository structure

```text
terraform-aws-rds/
├── modules/
│   ├── aurora-mysql/
│   └── aurora-postgresql/
│       ├── cluster.tf
│       ├── iam.tf
│       ├── instances.tf
│       ├── locals.tf
│       ├── parameter-groups.tf
│       ├── security-groups.tf
│       ├── subnet-groups.tf
│       ├── validations.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
├── aurora-mysql-readme.md
└── aurora-postgresql-readme.md
```

The child module contains the reusable Aurora PostgreSQL resources. The root files provide environment inputs, provider configuration, module selection, and root outputs.

## 2. What this module creates

Depending on the selected inputs, the module can create:

- An Aurora PostgreSQL DB cluster.
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
6. The Aurora PostgreSQL engine version and DB instance class are supported in the target Region.
7. Required KMS key policies and permissions are in place if customer-managed keys are used.
8. Database ingress sources have been reviewed and approved.

The current root provider configuration in `versions.tf` selects `ap-south-1`. Change it only when the deployment target requires another Region.

## 4. Enable or disable Aurora PostgreSQL

The root module uses a Boolean switch to decide whether to instantiate Aurora PostgreSQL:

```hcl
enable_aurora_postgresql = true
```

- `true`: Terraform includes the Aurora PostgreSQL child module.
- `false`: Terraform does not instantiate the Aurora PostgreSQL child module.

For an Aurora PostgreSQL-only test, use:

```hcl
enable_aurora_postgresql = true
enable_aurora_mysql      = false
```

For a MySQL-only test, reverse the values. To plan both engines together, set both to `true`.

> **State warning:** Changing a module switch from `true` to `false` after resources have been applied can cause Terraform to plan destruction of that module's managed resources. Always inspect the plan before applying. Do not toggle a deployed module off merely to run an isolated test.

## 5. Configure root inputs

The root `variables.tf` declares prefixed inputs for this engine. The root `main.tf` maps those values to the child module's unprefixed variables.

The main inputs are grouped below.

| Input group | Root variable examples | Purpose |
|---|---|---|
| Enablement | `enable_aurora_postgresql` | Include or exclude the module |
| Cluster | `aurora_postgresql_name`, `aurora_postgresql_engine_version` | Cluster identifier and engine version |
| Deployment and instances | `aurora_postgresql_deployment_mode`, `aurora_postgresql_instance_class`, `aurora_postgresql_reader_instance_class`, `aurora_postgresql_reader_count` | Provisioned/Serverless selection and DB instance sizing |
| Serverless v2 | `aurora_postgresql_serverless_v2_min_capacity`, `aurora_postgresql_serverless_v2_max_capacity` | Minimum and maximum ACUs |
| Network | `aurora_postgresql_vpc_id`, `aurora_postgresql_subnet_ids`, `aurora_postgresql_ingress_rules` | Existing VPC, subnets, and inbound access |
| Availability Zones | `aurora_postgresql_enable_availability_zones`, `aurora_postgresql_availability_zones` | Optional explicit AZ selection |
| Database | `aurora_postgresql_database_name`, `aurora_postgresql_master_username` | Initial database and master username |
| Encryption | `aurora_postgresql_storage_encrypted`, `aurora_postgresql_kms_key_id`, `aurora_postgresql_secret_kms_key_id` | Storage and secret encryption |
| Backups/lifecycle | `aurora_postgresql_backup_retention_period`, `aurora_postgresql_deletion_protection`, `aurora_postgresql_skip_final_snapshot`, `aurora_postgresql_final_snapshot_identifier` | Backup and deletion behavior |
| Parameter groups | `aurora_postgresql_use_custom_parameter_groups`, `aurora_postgresql_enable_custom_cluster_parameters`, `aurora_postgresql_enable_custom_instance_parameters`, `aurora_postgresql_cluster_parameters`, `aurora_postgresql_instance_parameters` | Custom DB parameters |
| Monitoring/logs | `aurora_postgresql_monitoring_interval`, `aurora_postgresql_monitoring_role_arn`, `aurora_postgresql_enabled_cloudwatch_logs_exports` | Enhanced Monitoring and CloudWatch log exports |
| Insights | `aurora_postgresql_performance_insights_enabled`, `aurora_postgresql_performance_insights_retention_period`, `aurora_postgresql_database_insights_mode` | Performance and Database Insights |
| Network options | `aurora_postgresql_network_type`, `aurora_postgresql_publicly_accessible`, `aurora_postgresql_allow_public_access` | IP mode and public-access controls |
| Optional features | `aurora_postgresql_enable_http_endpoint`, `aurora_postgresql_iam_database_authentication_enabled` | Data API and IAM DB authentication |
| Tags | `aurora_postgresql_tags` | Resource tags |

Review the actual root `variables.tf` for defaults and validation rules. The child module's unprefixed variables are not the names to put in the root `terraform.tfvars`.

### Current POC example

The supplied root `terraform.tfvars` uses these Aurora PostgreSQL test settings:

```hcl
enable_aurora_postgresql = true

aurora_postgresql_name           = "dev-aurora-pg-test"
aurora_postgresql_engine_version = "18.6"

aurora_postgresql_deployment_mode       = "serverless_v2"
aurora_postgresql_instance_class        = "db.r7g.large"
aurora_postgresql_reader_instance_class = null
aurora_postgresql_reader_count          = 1

aurora_postgresql_serverless_v2_min_capacity = 0.5
aurora_postgresql_serverless_v2_max_capacity = 2

aurora_postgresql_vpc_id = "vpc-REPLACE_WITH_YOUR_VPC_ID"
aurora_postgresql_subnet_ids = [
  "subnet-REPLACE_WITH_SUBNET_A",
  "subnet-REPLACE_WITH_SUBNET_B",
  "subnet-REPLACE_WITH_SUBNET_C"
]

aurora_postgresql_enable_availability_zones = true
aurora_postgresql_availability_zones = [
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]

aurora_postgresql_ingress_rules = {}

aurora_postgresql_database_name   = "devdb"
aurora_postgresql_master_username = "dbadmin"

aurora_postgresql_storage_encrypted = true
aurora_postgresql_storage_type      = "aurora"

aurora_postgresql_backup_retention_period     = 7
aurora_postgresql_deletion_protection         = false
aurora_postgresql_skip_final_snapshot         = false
aurora_postgresql_final_snapshot_identifier   = "dev-aurora-pg-test-final-snapshot"

aurora_postgresql_use_custom_parameter_groups       = true
aurora_postgresql_enable_custom_cluster_parameters  = true
aurora_postgresql_enable_custom_instance_parameters = true

aurora_postgresql_cluster_parameters = {
  timezone = {
    value        = "Asia/Kolkata"
    apply_method = "immediate"
  }
}

aurora_postgresql_instance_parameters = {
  log_min_duration_statement = {
    value        = "1000"
    apply_method = "pending-reboot"
  }
}

aurora_postgresql_monitoring_interval = 60
aurora_postgresql_enabled_cloudwatch_logs_exports = [
  "postgresql"
]

aurora_postgresql_performance_insights_enabled          = true
aurora_postgresql_performance_insights_retention_period = 7
aurora_postgresql_database_insights_mode                = "standard"

aurora_postgresql_network_type        = "IPV4"
aurora_postgresql_publicly_accessible = false
aurora_postgresql_allow_public_access = false

aurora_postgresql_enable_http_endpoint                = false
aurora_postgresql_iam_database_authentication_enabled = false

aurora_postgresql_tags = {
  Environment = "Dev"
  Project     = "RDS-Terraform-Module"
  ManagedBy   = "Terraform"
}
```

Replace the example VPC and subnet IDs with valid IDs in the intended account and Region. The engine version and instance class must be checked for regional availability before deployment. Do not commit environment-specific IDs if repository policy treats them as sensitive.

## 6. Deployment modes

The child Aurora PostgreSQL module supports:

### Provisioned

```hcl
deployment_mode = "provisioned"
instance_class  = "db.r7g.large"
reader_count    = 1
```

The module creates a writer using `instance_class` and the configured number of readers. A reader uses `reader_instance_class` when supplied; otherwise it uses the writer class. `reader_count = 0` creates only the writer.

### Aurora Serverless v2

```hcl
deployment_mode             = "serverless_v2"
serverless_v2_min_capacity   = 0.5
serverless_v2_max_capacity   = 2
reader_count                 = 1
```

The module uses `db.serverless` for writer and reader instances and configures the cluster's Serverless v2 ACU scaling range. The documented validation range is 0.5 to 256 ACUs in increments of 0.5, with the minimum not exceeding the maximum. Confirm engine-version and Region support before deployment.

## 7. Network and security

- Supply an existing VPC and at least two unique subnets in at least two Availability Zones.
- The module validates that the selected subnets belong to the supplied VPC and span the required AZs.
- Aurora PostgreSQL uses TCP port `5432`.
- An empty `aurora_postgresql_ingress_rules = {}` means this input creates no explicit inbound rules.
- When access is required, use a narrowly scoped application security group or approved IPv4 CIDR.
- Keep `publicly_accessible = false` unless public access is explicitly required and approved. The module requires both `publicly_accessible` and `allow_public_access` to be `true` before permitting public accessibility.
- Do not place passwords or secret values in `.tf` or `.tfvars` files. The module uses RDS-managed master credentials in Secrets Manager.

## 8. Parameter groups, monitoring, and logs

Custom cluster and instance parameter groups are controlled by `aurora_postgresql_use_custom_parameter_groups` and the corresponding custom-parameter enablement switches. Supply only parameter names and values supported by the selected Aurora PostgreSQL parameter group family. Some changes require a reboot; check the selected parameter's apply method.

Enhanced Monitoring is controlled by `aurora_postgresql_monitoring_interval`. The documented valid values are `0`, `1`, `5`, `10`, `15`, `30`, and `60` seconds. When monitoring is enabled and no existing role ARN is supplied, the child module creates a monitoring role and attaches the AWS-managed `AmazonRDSEnhancedMonitoringRole` policy.

The child module documents these CloudWatch log exports: `postgresql` and `iam-db-auth-error`. Confirm support for the selected engine configuration.

## 9. Root outputs

The root `outputs.tf` currently exposes these Aurora PostgreSQL outputs:

| Root output | Description |
|---|---|
| `aurora_postgresql_cluster_identifier` | Cluster identifier |
| `aurora_postgresql_cluster_endpoint` | Writer/cluster endpoint |
| `aurora_postgresql_reader_endpoint` | Reader endpoint |
| `aurora_postgresql_cluster_arn` | Cluster ARN |

The child module itself exposes additional outputs, including port, master secret ARN, writer/reader instance IDs, subnet group, security group, parameter group names, and parameter group family. Those additional values are not currently re-exposed by the supplied root `outputs.tf`.

When Aurora PostgreSQL is disabled, the root outputs use `try()` and return `null`.

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

### Plan Aurora PostgreSQL only

Set the switches in `terraform.tfvars`:

```hcl
enable_aurora_postgresql = true
enable_aurora_mysql      = false
```

Then run:

```powershell
terraform plan
```

For the supplied POC settings, the PostgreSQL-only plan shown in the test output included the cluster, writer and reader instances, subnet/security groups, parameter groups, monitoring role, and validation resources. Always use the latest plan output as the source of truth for the exact resource count.

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
| Engine version unavailable | Verify Aurora PostgreSQL version availability in the target Region. |
| Parameter group family error | Confirm the family matches the selected PostgreSQL engine major version. |
| Subnet validation error | Check VPC ownership, unique subnet IDs, and AZ coverage. |
| Explicit AZ validation error | Ensure the AZ list is unique and each AZ is represented by a supplied subnet. |
| Custom parameter validation error | Enable the corresponding custom-parameter switch and check parameter names/values for the engine family. |
| Final snapshot validation error | If `skip_final_snapshot = false`, provide a valid final snapshot identifier. If true, the identifier must be null. |
| Advanced Database Insights validation error | Enable Performance Insights and configure retention of at least 465 days; verify AWS service requirements and costs. |
| Enhanced Monitoring IAM error | Check role trust policy, role ARN, and IAM permissions to create/attach the managed policy. |
| KMS access denied | Review the key policy, IAM permissions, key status, and account/Region alignment. |
| Plan succeeds but apply fails | Check the AWS error, regional service availability, quotas, IAM permissions, and feature compatibility. |

## 13. Maintenance

Keep this guide synchronized with `modules/aurora-postgresql/variables.tf`, `outputs.tf`, resource files, and the root `main.tf`, `variables.tf`, and `outputs.tf`. Update the documentation whenever inputs, defaults, validations, outputs, or root mappings change.
