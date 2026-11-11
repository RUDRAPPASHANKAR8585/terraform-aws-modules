# Terraform AWS WAF Module

A reusable Terraform module for provisioning and managing an AWS WAFv2
Web Access Control List (Web ACL), with configurable IP-based rules,
country-based rules, rate-based rules, monitoring, and logging.

This repository contains a root Terraform configuration that passes
input variables to a reusable child module under `modules/`.

> **Implementation note:** This README documents the behavior present in
> the current Terraform source. Some variables are declared for planned
> or future behavior but are not currently connected to AWS WAF
> resources. Those are explicitly identified below.


## Overview

AWS WAF is a web application firewall that helps protect web
applications and APIs by inspecting incoming HTTP(S) requests and
evaluating them against configured rules.

This Terraform module creates an AWS WAFv2 Web ACL and can configure:

-   IPv4 and IPv6 IP allowlist rules.
-   IPv4 and IPv6 IP blocklist rules.
-   Country-based allowlist rules.
-   Country-based blocklist rules.
-   Global rate-based protection.
-   GET request rate-based protection.
-   Write request rate-based protection for POST, PUT and DELETE.
-   CloudWatch metrics and sampled requests.
-   Logging to an existing CloudWatch Logs log group, S3 bucket, or
    Amazon Data Firehose delivery stream.

The module supports both `CLOUDFRONT` and `REGIONAL` Web ACL scopes.

------------------------------------------------------------------------

## Supported functionality

  -----------------------------------------------------------------------
  Feature                             Current behavior
  ----------------------------------- -----------------------------------
  Web ACL scope                       `CLOUDFRONT` or `REGIONAL`

  IP allowlist                        IPv4 and IPv6

  IP blocklist                        IPv4 and IPv6

  IP set source                       Create a new IP set or reference an
                                      existing IP set

  Country allowlist                   Optional

  Country blocklist                   Optional

  Global rate rule                    Always enabled

  GET rate rule                       Enabled when
                                      `protection_mode = "RECOMMENDED"`

  Write rate rule                     Enabled when
                                      `protection_mode = "RECOMMENDED"`

  Rate rule action                    `COUNT`

  CloudWatch metrics                  Configurable

  Sampled requests                    Configurable

  WAF logging                         Optional

  Logging destinations                Existing CloudWatch Logs, S3, or
                                      Firehose destination
  -----------------------------------------------------------------------


## Architecture and file structure

terraform-aws-waf/
├── main.tf
├── variables.tf
├── versions.tf
├── terraform.tfvars
├── outputs.tf
└── modules/
    ├── web-acl.tf
    ├── ip-sets.tf
    ├── ip-set-data.tf
    ├── ip-rules.tf
    ├── country-rules.tf
    ├── rate-based-rules.tf
    ├── logging.tf
    ├── logging-destination-data.tf
    ├── locals.tf
    ├── variables.tf
    ├── outputs.tf
    └── versions.tf


------------------------------------------------------------------------

## Important AWS considerations

### CloudFront scope

For `scope = "CLOUDFRONT"`, configure the AWS provider in `us-east-1`.
CloudFront-scoped WAF resources are managed through the US East (N.
Virginia) endpoint.

### Regional scope

For `scope = "REGIONAL"`, configure the provider in the AWS Region where
the protected regional resource is located. Examples include an
Application Load Balancer or API Gateway resource supported by AWS WAF.

### Rule priority

AWS WAF evaluates rules in ascending priority order: the lower number is
evaluated first. A terminating `ALLOW` or `BLOCK` action can stop
evaluation of later rules. A `COUNT` action is non-terminating.

All active rule priorities must be unique across IP, country and
rate-based rules. The module has a Web ACL lifecycle precondition that
checks this before the Web ACL is created or updated.

### Existing resources

The module does not create the logging destination resources. It expects
the selected destination to exist already.

For an existing IP set, provide its exact name and make sure it belongs
to the same AWS account, provider context and WAF scope used by this
deployment.

------------------------------------------------------------------------

# Input variables

The tables below describe every variable declared in the root
configuration. The child module receives the corresponding inputs
through `main.tf`.

**Required** means the variable has no default in the current
`variables.tf`. **Optional** means a default is defined.

## 1. General configuration

### `aws_region`

aws_region = "us-east-1"

**Important:** The variable configures the root provider. CloudFront
scope requires `us-east-1`.

### `name`

**Purpose:** Name of the AWS WAF Web ACL. The module also uses this
value as the base for generated IP set names, rule names and metric
names.
**Accepted format:** Letters, numbers and hyphens only. Maximum length:
128 characters.

name = "application-prod-web-acl"

### `description`

**Purpose:** Optional description shown for the Web ACL in AWS.

description = "WAF protection for the production application"

### `scope`
**Purpose:** Determines whether the Web ACL is created for CloudFront or
for a regional AWS resource.

scope = "CLOUDFRONT" or "REGIONAL"


Select the scope that matches the resource you intend to protect. The
module does not create or associate the protected CloudFront
distribution, load balancer or API Gateway resource.

------------------------------------------------------------------------

## 2. Application metadata

These variables describe the application selection. In the current
implementation, the selected values are returned through the
`application_configuration` output. They do not currently create AWS
managed rule groups or change the Web ACL rules.

### `app_categories`

**Purpose:** Identifies the application category selected for the WAF
configuration.

**Allowed values:**

-   `Content & publishing systems`
-   `E-commerce & transaction platforms`
-   `Enterprise & business applications`
-   `API & integration services`
-   `Media & file processing`
-   `Other`

app_categories = [
  "Content & publishing systems",
  "API & integration services"
]

You can select one or more categories. Because the variable is a set,
duplicate values are not retained.

### `app_focus`

Allowed values   `BOTH`, `API`, `WEB`

**Purpose:** Records whether the application primarily handles web
traffic, API traffic, or both.

app_focus = "WEB"


Use `API` for API-focused applications, `WEB` for browser/web
applications, or `BOTH` when both traffic types are in scope.

**Current behavior:** This value is included in the
`application_configuration` output. It does not currently generate
separate API or web protection rules.

------------------------------------------------------------------------

## 3. Default action

### `default_action`

  Property         Value
  ---------------- ------------------
  Type             `string`
  Default          `"BLOCK"`
  Required         No
  Allowed values   `ALLOW`, `BLOCK`

**Purpose:** Defines what AWS WAF does when a request reaches the end of
the Web ACL rule evaluation without matching a terminating rule.

default_action = "BLOCK"

**ALLOW:** Requests that do not match a terminating rule are allowed.

**BLOCK:** Requests that do not match a terminating rule are blocked.

**Important:** Choose this setting carefully. With `BLOCK`, requests
need to match an applicable `ALLOW` rule to be permitted. With `ALLOW`,
requests are generally permitted unless a rule blocks them.

------------------------------------------------------------------------

## 4. IP allowlist and blocklist

The module supports IPv4 and IPv6 allowlist and blocklist
configurations.

An allowlist creates an `ALLOW` IP set reference rule. A blocklist
creates a `BLOCK` IP set reference rule.

### `enable_ip_allowlist`

enable_ip_allowlist = true

When enabled, the module can create or reference IPv4 and/or IPv6
allowlist IP sets, depending on the supplied CIDRs and source selection.

**Important:** Enabling this variable alone does not create an IP set
rule. At least one relevant CIDR must be supplied for a new IP set, or
an existing IP set must be selected.

### `enable_ip_blocklist`

**Purpose:** Enables IP blocklist rule processing.

enable_ip_blocklist = true

When enabled, the module can create or reference IPv4 and/or IPv6
blocklist IP sets.

### `allowed_ipv4_cidrs`

**Purpose:** IPv4 CIDR ranges that should match the allowlist.

allowed_ipv4_cidrs = [
  "192.0.2.10/32",
  "198.51.100.0/24"
]

Use `/32` for a single IPv4 address and a broader prefix when allowing a
network range.

The module validates IPv4 CIDR syntax and rejects duplicate entries.

**When `CREATE_NEW` is selected:** These CIDRs are used as the addresses
of the newly created IPv4 allowlist IP set.

**When `EXISTING` is selected:** The existing IP set is referenced; this
list is not used to update that existing IP set.

### `allowed_ipv6_cidrs`

**Purpose:** IPv6 CIDR ranges that should match the allowlist.

allowed_ipv6_cidrs = [
  "2001:db8:1234::/48",
  "2001:db8:abcd::10/128"
]
The module checks that entries look like valid IPv6 CIDRs and rejects
duplicates.

The same `CREATE_NEW` versus `EXISTING` behavior described for IPv4
applies.

### `blocked_ipv4_cidrs`

**Purpose:** IPv4 CIDR ranges that should match the blocklist.

blocked_ipv4_cidrs = [
  "203.0.113.25/32",
  "198.51.100.0/24"
]

The module validates IPv4 CIDR syntax and rejects duplicate entries.

### `blocked_ipv6_cidrs`

**Purpose:** IPv6 CIDR ranges that should match the blocklist.

blocked_ipv6_cidrs = [
  "2001:db8:ffff::/48"
]

The module validates IPv6 CIDR syntax and rejects duplicate entries.

### IP allowlist/blocklist behavior

  -----------------------------------------------------------------------
  Setting                             Result
  ----------------------------------- -----------------------------------
  `enable_ip_allowlist = false`       No allowlist rules are generated.

  `enable_ip_allowlist = true` with   A new IPv4 allowlist IP set and
  non-empty IPv4 CIDRs and IPv4       rule are generated.
  source `CREATE_NEW`                 

  `enable_ip_allowlist = true` with   The named existing IPv4 IP set is
  IPv4 source `EXISTING`              looked up and referenced.

  `enable_ip_blocklist = false`       No blocklist rules are generated.

  `enable_ip_blocklist = true` with   A new IPv4 blocklist IP set and
  non-empty IPv4 CIDRs and IPv4       rule are generated.
  source `CREATE_NEW`                 

  `enable_ip_blocklist = true` with   The named existing IPv4 IP set is
  IPv4 source `EXISTING`              looked up and referenced.
  -----------------------------------------------------------------------

The equivalent behavior applies to IPv6.

**Important:** An enabled feature with an empty CIDR list and source
`CREATE_NEW` does not create an empty IP set or an IP rule.

------------------------------------------------------------------------

## 5. IP rule priorities

### `ip_rule_priorities`

**Purpose:** Controls the evaluation order of the four possible IP-based
rules.
Default:

ip_rule_priorities = {
  block_ipv4 = 1
  block_ipv6 = 2
  allow_ipv4 = 3
  allow_ipv6 = 4
}

The map must contain exactly these four keys:

-   `block_ipv4`
-   `block_ipv6`
-   `allow_ipv4`
-   `allow_ipv6`

Each value must be a non-negative whole number.

ip_rule_priorities = {
  block_ipv4 = 1
  block_ipv6 = 2
  allow_ipv4 = 3
  allow_ipv6 = 4
}


AWS WAF evaluates lower priority numbers first. The module also checks
that priorities of all active IP, country and rate-based rules are
unique.

**Important:** Rate-based rules currently use fixed priorities `10`,
`11` and `12`. Country rule priorities are controlled separately through
`country_rule_priorities`. Do not assign an active IP or country rule
one of those rate-rule priorities.

------------------------------------------------------------------------

## 6. Protection mode and action mode

### `protection_mode`

  Allowed values   `RECOMMENDED`, `ESSENTIAL`

**Purpose in the current code:** Controls whether the GET and write
rate-based rules are included.

-   `RECOMMENDED`: Enables the global, GET and write rate-based rules.
-   `ESSENTIAL`: Keeps the global rate-based rule enabled and disables
    the GET and write rate-based rules.

protection_mode = "RECOMMENDED"

**Important:** The current implementation does not create AWS managed
rule groups for either mode. `CUSTOM` is not accepted.

### `protection_rule_action_mode`

  Allowed values   `RECOMMENDED`, `COUNT`

**Purpose:** Declared as a selection for the protection rule action

protection_rule_action_mode = "COUNT"

------------------------------------------------------------------------

## 7. Rate-based rules

The module defines three rate-based rules. All three aggregate requests
by source IP address.

### `global_rate_limit`

**Purpose:** Sets the request threshold for the global rate-based rule.

global_rate_limit = 1000

The global rule is always enabled in the current implementation,
regardless of `protection_mode`.

### `get_rate_limit`

**Purpose:** Sets the request threshold for GET requests from an
individual IP address.

get_rate_limit = 500

The GET rule is enabled only when:

protection_mode = "RECOMMENDED"

### `write_rate_limit`

**Purpose:** Sets the request threshold for write-method requests from
an individual IP address.

The methods included are:

-   `POST`
-   `PUT`
-   `DELETE`

write_rate_limit = 100

The write rule is enabled only when `protection_mode = "RECOMMENDED"`.

### `managed_ip_ddos_rate_limit`

**Purpose:** Declared as a rate threshold for managed IP DDoS
protection.

managed_ip_ddos_rate_limit = 1000

### `rate_limit_evaluation_window`

  Allowed values   `60`, `120`, `300`, `600` seconds

**Purpose:** Defines the evaluation window used by the rate-based rules.

rate_limit_evaluation_window = 300

AWS WAF evaluates the request rate over the selected time window. Use a
window that matches the application's expected traffic pattern.

### Rate-based rule behavior

  -----------------------------------------------------------------------------------------------
  Rule                   Priority Request       Enabled when                        Action
                                  matching                                          
  ------------- ----------------- ------------- ----------------------------------- -------------
  Global                       10 All requests  Always                              COUNT

  GET                          11 HTTP method   `protection_mode = "RECOMMENDED"`   COUNT
                                  `GET`                                             

  Write                        12 HTTP methods  `protection_mode = "RECOMMENDED"`   COUNT
                                  `POST`,                                           
                                  `PUT`,                                            
                                  `DELETE`                                          
  -----------------------------------------------------------------------------------------------

**COUNT behavior:** The request is counted and the rule does not
terminate Web ACL evaluation. It does not block the request when the
configured threshold is exceeded.

The current code does not expose a configurable rate-rule action such as
BLOCK.

------------------------------------------------------------------------

## 8. Existing IP set selection

For each IP address family and rule purpose, the module lets you choose
whether to create a new IP set or reference an existing one.

The accepted values are:

-   `CREATE_NEW`: Create a new IP set using the supplied CIDR list.
-   `EXISTING`: Look up an existing IP set by name and use its ARN in
    the Web ACL rule.

### IPv4 allowlist source

#### `allow_ipv4_ip_set_source`

  Allowed values   `CREATE_NEW`, `EXISTING`

allow_ipv4_ip_set_source = "CREATE_NEW"

Choose `EXISTING` when the IPv4 allowlist IP set is already present in
AWS.

#### `existing_allow_ipv4_ip_set_name`

  Required   Required when IPv4 allowlist source is `EXISTING`

**Purpose:** Name of the existing IPv4 allowlist IP set.

allow_ipv4_ip_set_source        = "EXISTING"
existing_allow_ipv4_ip_set_name = "application-prod-ipv4-allow"

### IPv6 allowlist source

#### `allow_ipv6_ip_set_source`

  Allowed values   `CREATE_NEW`, `EXISTING`

#### `existing_allow_ipv6_ip_set_name`

  Required   Required when IPv6 allowlist source is `EXISTING`

allow_ipv6_ip_set_source        = "EXISTING"
existing_allow_ipv6_ip_set_name = "application-prod-ipv6-allow"

### IPv4 blocklist source

#### `block_ipv4_ip_set_source`

  Allowed values   `CREATE_NEW`, `EXISTING`

#### `existing_block_ipv4_ip_set_name`

  Required   Required when IPv4 blocklist source is `EXISTING`

block_ipv4_ip_set_source        = "EXISTING"
existing_block_ipv4_ip_set_name = "application-prod-ipv4-block"

### IPv6 blocklist source

#### `block_ipv6_ip_set_source`

  Allowed values   `CREATE_NEW`, `EXISTING`

#### `existing_block_ipv6_ip_set_name`

  Required   Required when IPv6 blocklist source is `EXISTING`

block_ipv6_ip_set_source        = "EXISTING"
existing_block_ipv6_ip_set_name = "application-prod-ipv6-block"

### Existing IP set considerations

-   The relevant allowlist or blocklist feature must be enabled.
-   The source must be set to `EXISTING`.
-   The matching existing IP set name must be provided.
-   The IP set must exist in the selected AWS account and WAF scope.
-   IPv4 variables must reference an IPv4 IP set; IPv6 variables must
    reference an IPv6 IP set.
-   The same existing IPv4 IP set cannot be selected for both IPv4
    allowlist and IPv4 blocklist.
-   The same existing IPv6 IP set cannot be selected for both IPv6
    allowlist and IPv6 blocklist.
-   When using `EXISTING`, the module references the IP set; it does not
    update its addresses.

------------------------------------------------------------------------

## 9. Country-based rules

Country rules use AWS WAF GeoMatch statements.

Country codes must be uppercase two-letter ISO 3166-1 alpha-2 codes,
such as `IN`, `US` or `GB`. The current variable validation checks the
two-letter uppercase format and rejects duplicate entries.

### `enable_country_allowlist`

**Purpose:** Enables the country allowlist rule.

enable_country_allowlist = true

When enabled, at least one country code must be supplied in
`allowed_country_codes`.

### `allowed_country_codes`

  Property   Value
  ---------- --------------------------------------------
  Type       `list(string)`
  Default    `[]`
  Required   Required when country allowlist is enabled

**Purpose:** Country codes allowed by the country allowlist rule.

allowed_country_codes = [
  "IN",
  "GB"
]

The generated rule action is `ALLOW`.

### `enable_country_blocklist`

**Purpose:** Enables the country blocklist rule.

enable_country_blocklist = true

When enabled, at least one country code must be supplied in
`blocked_country_codes`.

### `blocked_country_codes`

**Purpose:** Country codes blocked by the country blocklist rule.

blocked_country_codes = [
  "US",
  "GB"
]


The generated rule action is `BLOCK`.

### `country_rule_priorities`

country_rule_priorities = {
  block_countries = 5
  allow_countries = 6
}

The map must contain exactly:

-   `block_countries`
-   `allow_countries`

Each priority must be a non-negative whole number.

country_rule_priorities = {
  block_countries = 5
  allow_countries = 6
}

**Priority behavior:** Lower priority numbers are evaluated first. If a
country is present in both lists, the rule evaluated first determines
the result when it takes a terminating action.

For example, with block priority `5` and allow priority `6`, a country
included in both lists is blocked first.

The module checks that active country priorities do not conflict with
active IP or rate-based rule priorities.

------------------------------------------------------------------------

## 10. Monitoring

### `enable_cloudwatch_metrics`

**Purpose:** Enables or disables CloudWatch metrics for the Web ACL and
its generated rules.

enable_cloudwatch_metrics = true

When enabled, AWS WAF publishes the configured Web ACL and rule metrics.

### `enable_sampled_requests`

**Purpose:** Enables or disables sampled request collection for the Web
ACL and its generated rules.

enable_sampled_requests = true

Sampled requests can help with troubleshooting and understanding which
requests match rules. They are not a replacement for full WAF logging.

------------------------------------------------------------------------

## 11. Logging

Logging is optional. The module can configure an existing CloudWatch
Logs log group, S3 bucket or Amazon Data Firehose delivery stream as the
WAF logging destination.

The module does not create these destinations.

### `enable_logging`

**Purpose:** Enables or disables the Web ACL logging configuration.

enable_logging = true

When set to `false`, no Web ACL logging configuration is created.

### `logging_destination_type`

  Allowed values   `CLOUDWATCH_LOGS`, `S3`, `FIREHOSE`

**Purpose:** Selects the type of existing destination that receives WAF
logs.

logging_destination_type = "CLOUDWATCH_LOGS"

Select exactly one destination type and provide the matching destination
name.

### `existing_cloudwatch_log_group_name`

  -----------------------------------------------------------------------
  Property                            Value
  ----------------------------------- -----------------------------------
  Type                                `string`

  Default                             `null`

  Required                            When logging is enabled and
                                      destination type is
                                      `CLOUDWATCH_LOGS`
  -----------------------------------------------------------------------

**Purpose:** Name of the existing CloudWatch Logs log group.

enable_logging                     = true
logging_destination_type           = "CLOUDWATCH_LOGS"
existing_cloudwatch_log_group_name = "aws-waf-logs-application-prod"


The module looks up the log group and uses its ARN.

The log group must meet AWS WAF logging requirements. In particular, use
the required `aws-waf-logs-` prefix.

### `existing_s3_bucket_name`

  Required   When logging is enabled and destination type is `S3`

**Purpose:** Name of the existing S3 bucket that receives WAF logs.

enable_logging           = true
logging_destination_type = "S3"
existing_s3_bucket_name  = "aws-waf-logs-application-prod"

The module constructs the S3 bucket ARN from the supplied bucket name.

**Important:** The bucket must exist and satisfy AWS WAF logging
requirements. The bucket name must start with `aws-waf-logs-`. The
bucket policy and other required permissions must allow AWS WAF to
deliver logs.

### `existing_firehose_stream_name`

  -----------------------------------------------------------------------
  Property                            Value
  ----------------------------------- -----------------------------------
  Type                                `string`

  Default                             `null`

  Required                            When logging is enabled and
                                      destination type is `FIREHOSE`
  -----------------------------------------------------------------------

**Purpose:** Name of the existing Amazon Data Firehose delivery stream.

enable_logging                = true
logging_destination_type      = "FIREHOSE"
existing_firehose_stream_name = "aws-waf-logs-application-prod"

The module looks up the delivery stream and uses its ARN.

### Logging configuration examples

CloudWatch Logs:

enable_logging                     = true
logging_destination_type           = "CLOUDWATCH_LOGS"
existing_cloudwatch_log_group_name = "aws-waf-logs-application-prod"

existing_s3_bucket_name       = null
existing_firehose_stream_name = null

S3:

enable_logging                     = true
logging_destination_type           = "S3"
existing_s3_bucket_name             = "aws-waf-logs-application-prod"

existing_cloudwatch_log_group_name = null
existing_firehose_stream_name      = null
```

Firehose:

enable_logging                = true
logging_destination_type      = "FIREHOSE"
existing_firehose_stream_name = "aws-waf-logs-application-prod"

existing_cloudwatch_log_group_name = null
existing_s3_bucket_name            = null
```

Set the destination variable for the selected destination type only. The
variable validations reject a destination name supplied for a different
destination type.

------------------------------------------------------------------------

# Example configuration

The following example demonstrates a CloudFront-scoped Web ACL with IPv4
allowlisting, country rules, rate-based rules, monitoring and S3
logging.

Use values that match resources and networks in your own AWS account.

``` hcl
aws_region = "us-east-1"

name        = "application-prod-web-acl"
description = "WAF for the production web application"
scope       = "CLOUDFRONT"

# Application metadata
app_categories = [
  "Content & publishing systems"
]
app_focus = "WEB"

# Default behavior
default_action = "BLOCK"

# IP allowlist and blocklist
enable_ip_allowlist = true
enable_ip_blocklist = false

allowed_ipv4_cidrs = [
  "192.0.2.10/32"
]
allowed_ipv6_cidrs = []

blocked_ipv4_cidrs = []
blocked_ipv6_cidrs = []

# IP rule priorities
ip_rule_priorities = {
  block_ipv4 = 1
  block_ipv6 = 2
  allow_ipv4 = 3
  allow_ipv6 = 4
}

# Create or reference IP sets
allow_ipv4_ip_set_source        = "CREATE_NEW"
existing_allow_ipv4_ip_set_name = null

allow_ipv6_ip_set_source        = "CREATE_NEW"
existing_allow_ipv6_ip_set_name = null

block_ipv4_ip_set_source        = "CREATE_NEW"
existing_block_ipv4_ip_set_name = null

block_ipv6_ip_set_source        = "CREATE_NEW"
existing_block_ipv6_ip_set_name = null

# Country protection
enable_country_blocklist = true
blocked_country_codes = [
  "US"
]

enable_country_allowlist = false
allowed_country_codes   = []

country_rule_priorities = {
  block_countries = 5
  allow_countries = 6
}

# Rate-based protection
protection_mode             = "RECOMMENDED"
protection_rule_action_mode = "RECOMMENDED"

global_rate_limit            = 1000
get_rate_limit               = 500
write_rate_limit             = 100
managed_ip_ddos_rate_limit   = 1000
rate_limit_evaluation_window = 300

# Monitoring
enable_cloudwatch_metrics = true
enable_sampled_requests   = true

# Logging
enable_logging           = true
logging_destination_type = "S3"
existing_s3_bucket_name  = "aws-waf-logs-application-prod"

existing_cloudwatch_log_group_name = null
existing_firehose_stream_name      = null
