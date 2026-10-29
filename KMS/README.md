# AWS KMS Terraform Module

A reusable Terraform module for creating and managing AWS Key Management Service (AWS KMS) keys and aliases. The module provides input validation, standard or custom key policies, optional administrator and key-user permissions, rotation controls, lifecycle safeguards, tags, and deployment account/Region checks.

The repository is organized as a root module that exposes a user-friendly interface and a child module that implements the KMS resources.

> **Current scope:** The examples below describe the module interface currently implemented in this repository. Imported `EXTERNAL` key material is not supported by the current creation path; it requires a separate import-key-material workflow. Review the notes on custom key stores and key policies before using this module for production keys.


## Features

- Creates an AWS KMS key using the selected key type, key specification, key usage, and key origin.
- Supports symmetric encryption keys, HMAC keys, and supported asymmetric key specifications, subject to AWS KMS and Region capabilities.
- Supports `STANDARD` generated key policies and `CUSTOM` JSON key policies.
- Allows administrator role/user ARNs, key-user role/user ARNs, and external AWS account IDs to be configured for the generated standard policy.
- Supports optional KMS aliases.
- Supports single-Region or multi-Region key configuration where the selected options permit it.
- Supports automatic key rotation for supported AWS-managed KMS key configurations, with an optional rotation period.
- Configures whether the key is enabled after creation and the deletion waiting period.
- Adds mandatory `Name` and `ManagedBy = Terraform` tags in addition to caller-provided tags. Mandatory values take precedence over conflicting caller-provided values.
- Checks account and Region expectations when supplied.
- Uses Terraform lifecycle protection to prevent Terraform from destroying the KMS key through an ordinary destroy or replacement plan.

## Repository structure

terraform-aws-kms/
├── versions.tf
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── modules/
    └── kms/
        ├── versions.tf
        ├── variables.tf
        ├── locals.tf
        ├── policy.tf
        ├── main.tf
        ├── alias.tf
        └── output.tf


- **Root module:** Defines the user-facing variables, AWS provider, child-module call, and root outputs.
- **`modules/kms`:** Contains the KMS key, policy construction, alias, validation/preconditions, and child outputs.


## Requirements

| Requirement | Version / expectation |
|---|---|
| Terraform | `>= 1.5.0` |
| AWS provider | `>= 5.84.0, < 6.0.0` |
| AWS credentials | Configured through an AWS profile, environment variables, or an approved role-assumption mechanism |
| AWS permissions | Permission to create and manage KMS keys and aliases, plus any tagging and policy operations required by the selected configuration |

The AWS provider Region is configured through the root `aws_region` input. Credentials should not be hardcoded in Terraform files.

## How the module works

1. The caller provides root-module inputs in `terraform.tfvars`, a higher-level module, or a deployment workflow.
2. The root module configures the AWS provider and passes the inputs to `modules/kms`.
3. The child module normalizes relevant enum inputs and selects the standard generated policy or supplied custom policy.
4. Terraform evaluates input validations and resource preconditions before proposing infrastructure changes.
5. `terraform plan` shows the proposed key and optional alias changes. Review the plan before any deployment.

The root-level `key_enabled` input maps to the child module's `is_enabled` argument. This gives callers a more descriptive name without changing the tested child-module interface.

## Quick start

### 1. Configure AWS credentials

Use your organization's approved AWS authentication method. For example, if you use a named AWS CLI profile, set it in your shell before running Terraform:

```powershell
$env:AWS_PROFILE = "your-profile"
```

Do not place access keys or secret keys in `terraform.tfvars`.

### 2. Create local input values

Create `terraform.tfvars` in the repository root. This is a basic symmetric-encryption example:

key_name     = "example-kms-key"
description  = "KMS key managed by Terraform"
key_type     = "SYMMETRIC"
key_spec     = "SYMMETRIC_DEFAULT"
key_usage    = "ENCRYPT_DECRYPT"
key_origin   = "AWS_KMS"
multi_region = false

alias_name   = "alias/example-kms-key"
enable_alias = true

tags = {
  Environment = "dev"
  Purpose     = "application-encryption"
}

key_policy_mode       = "STANDARD"
key_administrator_arns = []
key_user_arns          = []
external_account_ids   = []

enable_key_deletion     = false
enable_key_rotation     = true
rotation_period_in_days = null
key_enabled             = true
deletion_window_in_days = 30

# Optional expected-account check. Set to the target 12-digit account ID
# when you want Terraform to fail if credentials point to another account.
account_id = null

# Required root-module input: choose the target AWS Region.
aws_region = "ap-south-1"
```

For a production deployment, configure the appropriate administrator and usage principals, and review the policy and deletion safeguards before proceeding.

### 3. Initialize and validate

Run these commands from the repository root:

terraform init
terraform fmt -recursive
terraform validate
tflint
terraform plan
terraform apply

## Input variables

The root module exposes the following inputs. Required/default values below describe the root interface; resource compatibility and AWS Region availability still apply.

### Key configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `key_name` | `string` | **Required** | Logical name for the key. Must not be empty. Also used for the mandatory `Name` tag and, when no alias is provided, to generate an alias name. |
| `description` | `string` | `null` | Optional human-readable description of the key's purpose. |
| `key_type` | `string` | `"SYMMETRIC"` | High-level key type: `SYMMETRIC` or `ASYMMETRIC`. Must be compatible with `key_spec` and `key_usage`. |
| `key_spec` | `string` | `"SYMMETRIC_DEFAULT"` | Cryptographic specification. See [Key type, specification, and usage](#key-type-specification-and-usage). |
| `key_usage` | `string` | `"ENCRYPT_DECRYPT"` | Intended cryptographic operation: `ENCRYPT_DECRYPT`, `SIGN_VERIFY`, `GENERATE_VERIFY_MAC`, or `KEY_AGREEMENT`. |
| `key_origin` | `string` | `"AWS_KMS"` | Key material source: `AWS_KMS`, `EXTERNAL`, `AWS_CLOUDHSM`, or `EXTERNAL_KEY_STORE`. See [Key origin and custom key stores](#key-origin-and-custom-key-stores). |
| `multi_region` | `bool` | `false` | Whether to create a multi-Region key. The selected origin and key configuration must support this. |

### Key material and custom key stores

| Variable | Type | Default | Description |
|---|---|---|---|
| `confirm_external_key_material` | `bool` | `false` | Explicit acknowledgement of the additional responsibilities associated with imported key material. This acknowledgement alone does not implement the import workflow. |
| `custom_key_store_id` | `string` | `null` | ID of an existing AWS CloudHSM custom key store. Required for `AWS_CLOUDHSM`. |
| `external_key_store_id` | `string` | `null` | ID of an existing AWS KMS external key store. Required for `EXTERNAL_KEY_STORE`. |
| `xks_key_id` | `string` | `null` | Identifier of the external key in the external key manager. Required for `EXTERNAL_KEY_STORE`. |
| `confirm_external_key_store_risks` | `bool` | `false` | Acknowledges external key store availability, latency, and dependency risks. |

### Alias and tags

| Variable | Type | Default | Description |
|---|---|---|---|
| `alias_name` | `string` | `null` | Optional alias including the `alias/` prefix, for example `alias/application/prod/data-key`. When omitted, the module generates an alias from `key_name` if alias creation is enabled. |
| `enable_alias` | `bool` | `true` | Whether to create an alias for the key. |
| `tags` | `map(string)` | `{}` | Additional tags for identification, ownership, environment, and cost allocation. `Name` and `ManagedBy` are enforced by the module. |

### Policy and permissions

| Variable | Type | Default | Description |
|---|---|---|---|
| `key_policy_mode` | `string` | `"STANDARD"` | `STANDARD` generates the policy from the permission inputs. `CUSTOM` uses the supplied complete policy JSON. |
| `key_policy_json` | `string` | `null` | Complete KMS key policy as a JSON string. Required when `key_policy_mode = "CUSTOM"`. |
| `key_administrator_arns` | `list(string)` | `[]` | Existing IAM role or user ARNs that receive key-administration permissions in `STANDARD` mode. |
| `enable_key_deletion` | `bool` | `false` | Controls whether the generated standard administrator statement includes `kms:ScheduleKeyDeletion` and `kms:CancelKeyDeletion`. It does not schedule deletion by itself. |
| `key_user_arns` | `list(string)` | `[]` | Existing IAM role or user ARNs granted the cryptographic operations associated with the selected `key_usage` in `STANDARD` mode. |
| `external_account_ids` | `list(string)` | `[]` | AWS account IDs to include in the generated policy for cross-account access. Each external account must also configure suitable IAM permissions. |

### Rotation and lifecycle

| Variable | Type | Default | Description |
|---|---|---|---|
| `enable_key_rotation` | `bool` | `true` | Requests automatic rotation. The current module permits it only for AWS KMS symmetric encryption keys using `SYMMETRIC_DEFAULT` and `ENCRYPT_DECRYPT`. |
| `rotation_period_in_days` | `number` | `null` | Optional rotation period, as a whole number from 90 to 2560. `null` uses the AWS default where supported. Must be `null` or paired with `enable_key_rotation = true`. |
| `key_enabled` | `bool` | `true` | Root-level control for whether the key should be enabled after creation. It maps to the child module's `is_enabled`. Disabling a key does not delete it. |
| `deletion_window_in_days` | `number` | `30` | Waiting period before a scheduled deletion takes effect. Must be a whole number from 7 through 30 days. |

### Deployment context

| Variable | Type | Default | Description |
|---|---|---|---|
| `account_id` | `string` | `null` | Optional expected 12-digit AWS account ID. When set, the module verifies that the active AWS credentials resolve to this account. |
| `aws_region` | `string` | **Required at root** | AWS Region for the provider. The child module can also compare the configured Region with this expected value when supplied. |

## Key policy configuration

The module supports two policy modes. Choose one mode for a deployment.

### Option A: `STANDARD` policy (recommended starting point)

Use the generated policy when the module's supported permission model meets your requirements:

```hcl
key_policy_mode = "STANDARD"

key_administrator_arns = [
  "arn:aws:iam::123456789012:role/KMSKeyAdminRole"
]

key_user_arns = [
  "arn:aws:iam::123456789012:role/ApplicationKMSUserRole"
]

external_account_ids = []
enable_key_deletion  = false
```

The generated policy includes:

- **Account IAM delegation:** Allows the AWS account root principal to use IAM policies to delegate KMS permissions within the account.
- **Administrator statement:** Added when `key_administrator_arns` is non-empty. Grants the generated administrative actions, with scheduling/cancel-deletion permissions included only when `enable_key_deletion = true`.
- **Key usage statement:** Added when `key_user_arns` is non-empty. Its allowed cryptographic actions depend on `key_usage`.
- **External-account statement:** Added when `external_account_ids` is non-empty. The external account must separately grant the caller the required IAM permissions.

An empty administrator or key-user list means the corresponding explicit statement is omitted. It does **not** mean the key has no access path: the account-root IAM delegation statement remains. Before using the key, ensure the intended operational administrators and recovery path are in place.

Only supply IAM role or user ARNs that already exist. The module does not create those IAM identities.

### Option B: `CUSTOM` policy

Choose this when your organization requires a complete, explicitly managed KMS key policy:

```hcl
key_policy_mode = "CUSTOM"

key_policy_json = <<-JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableAccountIAMDelegation",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowKeyAdministration",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/KMSKeyAdminRole"
      },
      "Action": [
        "kms:Describe*",
        "kms:Get*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Enable*",
        "kms:Disable*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:CreateGrant",
        "kms:RevokeGrant",
        "kms:RetireGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowKeyUsage",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ApplicationKMSUserRole"
      },
      "Action": [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Resource": "*"
    }
  ]
}
JSON
```

Replace the example account ID and role ARNs with the real principals for your target environment. The example is for a symmetric encryption key; change the usage actions to match the actual key type and intended use.

**When using `CUSTOM`:**

1. Set `key_policy_mode = "CUSTOM"`.
2. Supply a complete JSON policy string in `key_policy_json`.
3. Ensure the policy is valid JSON and valid for AWS KMS.
4. Include the appropriate account delegation or explicit administrative permissions and a tested recovery path. A syntactically valid policy can still lock out administrators.
5. Do not rely on `key_administrator_arns`, `key_user_arns`, or `external_account_ids` to add statements to a custom policy; those inputs are used by the generated `STANDARD` policy.
6. Run `terraform validate` and `terraform plan`, and review the rendered policy before deployment.

The module validates that the supplied custom policy is valid JSON and that a non-empty policy is provided in `CUSTOM` mode. AWS KMS performs additional policy validation when the resource is created.

## Key type, specification, and usage

`key_type`, `key_spec`, and `key_usage` must form a supported combination. The module includes preconditions to reject common incompatible combinations before AWS resource creation. Availability of some algorithms, including SM2 and newer specifications, depends on AWS Region and AWS KMS support.

| Key type | Example `key_spec` | Valid `key_usage` in this module |
|---|---|---|
| Symmetric encryption | `SYMMETRIC_DEFAULT` | `ENCRYPT_DECRYPT` |
| Symmetric HMAC | `HMAC_224`, `HMAC_256`, `HMAC_384`, `HMAC_512` | `GENERATE_VERIFY_MAC` |
| Asymmetric RSA | `RSA_2048`, `RSA_3072`, `RSA_4096` | `ENCRYPT_DECRYPT` or `SIGN_VERIFY` |
| NIST elliptic curve | `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521` | `SIGN_VERIFY` or `KEY_AGREEMENT` |
| secp256k1 | `ECC_SECG_P256K1` | `SIGN_VERIFY` |
| Edwards25519 | `ECC_NIST_EDWARDS25519` | `SIGN_VERIFY` |
| ML-DSA | `ML_DSA_44`, `ML_DSA_65`, `ML_DSA_87` | `SIGN_VERIFY` |
| SM2 | `SM2` | `ENCRYPT_DECRYPT`, `SIGN_VERIFY`, or `KEY_AGREEMENT`, where supported |

These combinations describe the module's current precondition logic; they do not override AWS KMS's Region-specific support or service-side validation. Select the key type and specification based on the cryptographic requirement, not only on the fact that Terraform accepts the input.

## Key origin and custom key stores

| `key_origin` | Required configuration | Current module behavior |
|---|---|---|
| `AWS_KMS` | No custom key-store IDs | Default and recommended path. AWS KMS creates and manages the key material. |
| `EXTERNAL` | `confirm_external_key_material = true` is an acknowledgement input | **Not supported by the current creation path.** The module intentionally fails its precondition until a dedicated import-key-material workflow is implemented. |
| `AWS_CLOUDHSM` | Existing `custom_key_store_id` | Requires an existing custom key store. The current module preconditions restrict custom-store keys to symmetric `SYMMETRIC_DEFAULT`, `ENCRYPT_DECRYPT`, single-Region configuration. |
| `EXTERNAL_KEY_STORE` | Existing `external_key_store_id`, `xks_key_id`, and `confirm_external_key_store_risks = true` | Requires an existing external key store and external key identifier. The current module preconditions restrict custom-store keys to symmetric `SYMMETRIC_DEFAULT`, `ENCRYPT_DECRYPT`, single-Region configuration. |

Custom key stores require infrastructure and operational readiness beyond this Terraform module, including appropriate connectivity and availability of the underlying key store. Confirm that the selected origin and key-store configuration are supported by AWS in the target Region.

## Rotation and lifecycle

### Automatic rotation

For the currently supported automatic-rotation path, use:

```hcl
key_origin              = "AWS_KMS"
key_type                = "SYMMETRIC"
key_spec                = "SYMMETRIC_DEFAULT"
key_usage               = "ENCRYPT_DECRYPT"
enable_key_rotation     = true
rotation_period_in_days = null
```

- `enable_key_rotation = true` requests automatic rotation.
- `rotation_period_in_days = null` leaves the rotation period at the AWS default where supported.
- To set a custom interval, provide a whole number between `90` and `2560` and keep `enable_key_rotation = true`.
- The module rejects automatic rotation for unsupported key configurations.
- Automatic rotation does not mean the key's key ID or ARN changes; AWS KMS manages the rotation of key material for supported keys.

### Enabled state

```hcl
key_enabled = true
```

Set `key_enabled = false` when you explicitly want the KMS key disabled. A disabled key cannot perform normal cryptographic operations until re-enabled. Disabling is not the same as scheduling deletion.

### Deletion protection

The child KMS key resource uses Terraform `prevent_destroy = true`. This protects against ordinary Terraform plans that would destroy or replace the key. It does not replace AWS IAM controls, backups/recovery planning, or organizational change management.

`deletion_window_in_days` sets the waiting period if key deletion is scheduled through an authorized process. `enable_key_deletion` only controls whether the generated **standard administrator policy** includes the relevant schedule/cancel permissions; it does not itself schedule deletion. The current `prevent_destroy` lifecycle rule must be considered separately when planning any intentional removal.

## Aliases and tags

### Alias behavior

```hcl
enable_alias = true
alias_name   = "alias/application/prod/data-key"
```

- Alias names must include the `alias/` prefix.
- If `alias_name` is omitted and alias creation is enabled, the module generates an alias using `key_name`.
- If `enable_alias = false`, the module should not create an alias; consumers should not assume alias outputs are populated.
- An alias is a friendly name for a key, not a separate cryptographic key.

### Tags

```hcl
tags = {
  Environment = "prod"
  Application = "billing"
  Owner       = "platform-team"
  CostCenter  = "12345"
}
```

The module adds the mandatory tags:

- `Name`: set from `key_name`
- `ManagedBy`: set to `Terraform`

These mandatory values take precedence if the caller supplies the same keys. Add any organization-specific tags through `tags`.

## Outputs

The root module currently exposes these outputs:

| Output | Description |
|---|---|
| `key_id` | Unique ID of the KMS key. |
| `key_arn` | ARN of the KMS key. |
| `key_description` | Key description. |
| `key_spec` | Cryptographic key specification. |
| `key_usage` | Cryptographic operations supported by the key. |
| `multi_region` | Whether the key is configured as multi-Region. |
| `configured_key_rotation` | Whether automatic rotation was requested in the configuration. This is a configuration value, not an independent live status check. |
| `alias_name` | Alias name, or `null` when alias creation is disabled. |
| `alias_arn` | Alias ARN, or `null` when alias creation is disabled. |
| `alias_target_key_id` | Key ID targeted by the alias, or `null` when alias creation is disabled. |
| `account_id` | AWS account ID resolved from the active provider credentials. |
| `aws_region` | AWS Region resolved from the active provider. |

The child module has additional internal outputs, but only the values explicitly re-exported by the root module are available to callers of this root module.

## Validation and testing

The recommended safe workflow is:

```powershell
terraform fmt -recursive
terraform init
terraform validate
tflint
terraform plan
terraform apply
```

Review the plan for:

- The intended AWS account and Region.
- The expected key specification and usage.
- The exact rendered key policy and intended administrators/users.
- The requested rotation and enabled settings.
- The expected alias and tags.
- Any unexpected replacements or deletions.


## Security considerations

- **Key policy is critical.** Incorrect policy statements can grant excessive access or prevent administrators from managing the key. Review custom policies carefully.
- **Do not deploy with an unreviewed access model.** Empty `key_administrator_arns` and `key_user_arns` lists omit those explicit statements in standard mode. Verify the account-level delegation and intended IAM permissions before use.
- **Use least privilege.** Grant only the cryptographic and administrative actions required by each principal.
- **Cross-account access is two-sided.** A key policy statement naming an external account does not replace the required IAM permissions in that account.
- **Protect account and credential context.** Use approved credentials/roles and set `account_id` when an expected-account guard is desired.
- **Plan before changing lifecycle settings.** Disabling a key can interrupt applications; scheduling deletion can make encrypted data unrecoverable after deletion.
- **Keep local secrets and environment-specific files out of Git.** Do not commit credentials or private `terraform.tfvars` files.
- **Understand `prevent_destroy`.** It is an additional Terraform safeguard, not a substitute for IAM permissions, change control, or key recovery procedures.

## Troubleshooting

| Symptom | Likely cause / resolution |
|---|---|
| `Invalid key_type, key_spec, and key_usage combination` | Select a combination from the supported table and confirm AWS KMS supports it in the chosen Region. |
| `Provide key_policy_json when key_policy_mode is CUSTOM` | Set `key_policy_mode = "CUSTOM"` and provide a complete, non-empty JSON policy string. |
| Custom policy JSON validation fails | Check quoting, commas, braces, and JSON syntax. The policy must also be valid for AWS KMS and preserve administrative access. |
| Account mismatch precondition fails | Confirm the active AWS credentials/assumed role and the `account_id` input refer to the intended account. |
| Region mismatch precondition fails | Ensure `aws_region` matches the Region configured for the AWS provider. |
| Automatic rotation precondition fails | Use `AWS_KMS`, `SYMMETRIC`, `SYMMETRIC_DEFAULT`, and `ENCRYPT_DECRYPT`, or disable rotation for a supported alternative key configuration. |
| External key material precondition fails | Imported `EXTERNAL` key material is not supported by the current creation path; use the supported AWS KMS origin or implement the dedicated import workflow before enabling this option. |
| CloudHSM key-store precondition fails | Provide an existing `custom_key_store_id` and use the supported symmetric, single-Region configuration. |
| External key store precondition fails | Provide an existing `external_key_store_id`, a valid `xks_key_id`, and explicitly acknowledge the external key store risks. |
| Alias output is null | Check whether `enable_alias` is false. |
| Terraform proposes key replacement or deletion | Stop and review the plan. The key has `prevent_destroy = true`; do not attempt to bypass it without an approved migration/removal plan.
