# AWS CloudFront Terraform Module

## 1. Overview

This Terraform module provisions and manages an AWS CloudFront distribution with configurable origins, cache behaviors, security, policies, logging, and pricing options.

The module is designed to support reusable CloudFront deployments for static websites and other web applications.

### Key features

- CloudFront distribution creation and configuration.
- S3 REST and custom HTTP/HTTPS origins.
- Origin Access Control (OAC) for private S3 origins.
- Per-origin connection settings, custom headers, Origin Shield, and mutual TLS options.
- Default and ordered cache behaviors.
- AWS-managed, existing, and custom cache policies.
- AWS-managed, existing, and custom origin request policies.
- AWS-managed, existing, and custom response headers policies.
- CloudFront Functions and behavior associations.
- Custom error responses.
- Custom domain names and ACM certificates.
- AWS WAFv2 Web ACL association.
- Standard logging v2 and legacy S3 access logging.
- Pay-As-You-Go and flat-rate CloudFront pricing.
- Geographic restrictions, IPv6, HTTP versions, and TLS configuration.
- Resource tagging.

## 2. Module architecture

text
CloudFront/
│
├── main.tf
├── variables.tf
├── versions.tf
├── terraform.tfvars
├── outputs.tf
├── locals.tf
│
└── modules/
    ├── distribution.tf
    ├── origin-access-control.tf
    ├── pricing-plan.tf
    ├── certificates.tf
    ├── cache-policy.tf
    ├── origin-request-policy.tf
    ├── response-headers-policy.tf
    ├── cloudfront-functions.tf
    ├── cloudfront-logging-v2.tf
    ├── managed-policies.tf
    ├── variables.tf
    ├── locals.tf
    └── outputs.tf


The root module provides the user-facing configuration and connects the child module to existing AWS resources.

## 3. Prerequisites and resource ownership

### Resources created by this module

- CloudFront distribution.
- CloudFront Origin Access Controls.
- Custom cache policies.
- Custom origin request policies.
- Custom response headers policies.
- CloudFront Functions.
- Standard logging v2 delivery source, destination, and delivery configuration.
- CloudFront flat-rate pricing subscription, when selected.
- S3 bucket policy granting the CloudFront distribution access to the configured origin bucket.

### Existing resources required

The following resources are managed outside this module and must be provided as inputs when required:

- S3 origin bucket.
- S3 logging bucket, when S3 logging is selected.
- CloudWatch Logs log group, when CloudWatch logging is selected.
- Kinesis Data Firehose delivery stream, when Firehose logging is selected.
- ACM certificate for custom domain names.
- AWS WAFv2 Web ACL.
- DNS hosted zone and DNS records.

**Important:** The module does not create S3 buckets, WAF Web ACLs, ACM certificates, Route 53 hosted zones, or DNS records.

The S3 bucket policy is managed by the root module. Review existing bucket policy statements before applying because the Terraform policy resource manages the complete bucket policy document.

## 4. Provider configuration

CloudFront is a global service, but the AWS provider requires a region.

The root module uses the following provider configuration:


terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.69.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "s3"
  region = var.s3_bucket_region
}

provider "aws" {
  alias  = "logging_s3"
  region = var.logging_s3_bucket_region
}


The provider aliases are used for the existing S3 origin bucket policy and the existing S3 logging bucket lookup.

## 5. Input variables

The following tables describe the root module's public inputs, their declared defaults, and supported values.

A `null` default means the root input is not assigned a value by default. Supply the value when required by your configuration. Optional resource attributes may be omitted when passed as null.

### 5.1 AWS and existing S3 origin configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `us-east-1` | AWS provider region. |
| `s3_bucket_name` | string | Required | Name of the existing S3 origin bucket. |
| `s3_bucket_arn` | string | Required | ARN of the existing S3 origin bucket. |
| `s3_bucket_region` | string | `ap-south-1` | Region where the origin bucket exists. |
| `origin_access_controls` | map | `null` | OAC configurations. |
| `origins` | map | `null` | CloudFront origin configurations. |
| `origin_settings` | map | `{}` | Optional per-origin settings. |

#### Origin configuration

The `origins` input accepts a map of origin configurations.

Supported origin types:

- `S3` – S3 REST origin.
- `CUSTOM` – Custom HTTP or HTTPS origin.

Example:

origins = {
  s3_origin = {
    domain_name               = "my-static-site.s3.ap-southeast-2.amazonaws.com"
    origin_type               = "S3"
    origin_access_control_key = "s3_oac"
  }

  application_origin = {
    domain_name             = "origin.example.com"
    origin_type             = "CUSTOM"
    origin_protocol_policy  = "https-only"
    https_port              = 443
    origin_ssl_protocols    = ["TLSv1.2"]
  }
}

Origin attributes:

| Attribute | Default | Description |
|---|---|---|
| `domain_name` | Required | Origin DNS name. |
| `origin_type` | Required | `S3` or `CUSTOM`. |
| `origin_path` | Not set | Optional path appended to origin requests. |
| `origin_access_control_key` | Not set | Reference to an OAC map key. |
| `http_port` | `80` | Custom origin HTTP port. |
| `https_port` | `443` | Custom origin HTTPS port. |
| `origin_protocol_policy` | `https-only` | `http-only`, `https-only`, or `match-viewer`. |
| `origin_ssl_protocols` | `["TLSv1.2"]` | SSL/TLS protocols for custom origins. |
| `origin_keepalive_timeout` | `5` | Custom origin keep-alive timeout. |

#### Origin Access Control configuration

OAC provides authenticated access between CloudFront and supported origins.

origin_access_controls = {
  s3_oac = {
    name             = "cloudfront-s3-oac"
    description      = "OAC for private S3 origin"
    origin_type      = "s3"
    signing_behavior = "always"
  }
}

| Attribute | Default | Supported values |
|---|---|---|
| `name` | Required | OAC name. |
| `description` | Not set | Optional description. |
| `origin_type` | `s3` | `s3`, `mediastore`, `mediapackagev2`, `lambda`. |
| `signing_behavior` | `always` | `always`, `never`, `no-override`. |

The S3 origin's `origin_access_control_key` must reference an OAC configured with `origin_type = "s3"`.

#### Per-origin settings

The `origin_settings` map uses the same keys as `origins`.

| Attribute | Default | Description |
|---|---|---|
| `mode` | `RECOMMENDED` | `RECOMMENDED` or `CUSTOM`. |
| `mutual_tls_enabled` | `false` | Enables mutual TLS configuration. |
| `mutual_tls_certificate_arn` | Not set | Client certificate ARN when mutual TLS is enabled. |
| `custom_headers` | `{}` | Map of custom origin headers. |
| `origin_shield.enabled` | `false` | Enables Origin Shield. |
| `origin_shield.region` | Not set | AWS region for Origin Shield. |
| `connection_attempts` | `3` | Valid range: 1–3. |
| `connection_timeout` | `10` | Valid range: 1–10 seconds. |
| `response_timeout` | `30` | Valid range: 1–120 seconds. |
| `response_completion_timeout` | Not set | Must be greater than or equal to response timeout when specified. |

Example:

origin_settings = {
  s3_origin = {
    mode = "RECOMMENDED"
  }

  application_origin = {
    mode                = "CUSTOM"
    connection_attempts = 3
    connection_timeout  = 10
    response_timeout    = 60

    custom_headers = {
      X-Origin-Source = "CloudFront"
    }

    origin_shield = {
      enabled = true
      region  = "ap-southeast-2"
    }
  }
}

### 5.2 CloudFront pricing

Variable: `pricing`

Default:

pricing = {
  model = "PAY_AS_YOU_GO"
}

Supported pricing models:

| Model | Description |
|---|---|
| `PAY_AS_YOU_GO` | Standard usage-based CloudFront pricing. |
| `FLAT_RATE` | Creates a CloudFront Pricing Plan Manager subscription. |

For flat-rate pricing, provide the following configuration:

pricing = {
  model = "FLAT_RATE"

  flat_rate = {
    plan_tier     = "PRO"
    approval_mode = "MANUAL"
    usage_level   = "DEFAULT"
  }
}

Flat-rate attributes:

| Attribute | Required | Supported values |
|---|---|---|
| `plan_tier` | Yes | `FREE`, `PRO`, `BUSINESS`, `PREMIUM`. |
| `approval_mode` | No | `MANUAL`, `IMMEDIATE`, or omitted for AWS default behavior. |
| `usage_level` | No | `DEFAULT`; Premium also supports `CF_PREMIUM_L2` through `CF_PREMIUM_L6`. |

Rules:

- For `PAY_AS_YOU_GO`, omit the `flat_rate` object.
- For `FLAT_RATE`, provide the `flat_rate` object.
- `FREE`, `PRO`, and `BUSINESS` support only `DEFAULT` usage level.
- `PREMIUM` supports `DEFAULT` and `CF_PREMIUM_L2` through `CF_PREMIUM_L6`.
- Flat-rate pricing requires `waf_enabled = true` and an existing WAF Web ACL ARN.

### 5.3 Distribution configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `distribution_enabled` | bool | `null` | Enables or disables the distribution. |
| `distribution_comment` | string | `null` | Distribution description. |
| `distribution_aliases` | list(string) | `null` | Alternate domain names (CNAMEs). |
| `default_root_object` | string | `null` | Default object, such as `index.html`. |
| `price_class` | string | `null` | CloudFront price class. |
| `http_version` | string | `null` | Maximum supported HTTP version. |
| `is_ipv6_enabled` | bool | `null` | Enables IPv6. |

Common supported values:

**Price class**

- `PriceClass_100`
- `PriceClass_200`
- `PriceClass_All`

**HTTP version**

- `http1.1`
- `http2`
- `http2and3`
- `http3`

Example:

distribution_enabled = true
distribution_comment = "Static website distribution"

distribution_aliases = []

default_root_object = "index.html"

price_class     = "PriceClass_100"
http_version    = "http2and3"
is_ipv6_enabled = true

### 5.4 Default cache behavior

Variable: `default_cache_behavior`

The default configuration is:

default_cache_behavior = {
  target_origin_key      = "s3_origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]
  compress               = true

  function_associations = []

  cache_policy = {
    type         = "MANAGED"
    managed_name = "CachingOptimized"
  }

  origin_request_policy = {
    type = "NONE"
  }

  response_headers_policy = {
    type = "NONE"
  }
}

| Attribute | Default | Description |
|---|---|---|
| `target_origin_key` | `s3_origin` | Key from the `origins` map. |
| `viewer_protocol_policy` | `redirect-to-https` | Viewer HTTP/HTTPS handling. |
| `allowed_methods` | `["GET", "HEAD"]` | Allowed HTTP methods. |
| `cached_methods` | `["GET", "HEAD"]` | Methods CloudFront caches. |
| `compress` | `true` | Enables compression. |
| `function_associations` | `[]` | CloudFront Function associations. |
| `cache_policy` | AWS-managed `CachingOptimized` | Cache policy selection. |
| `origin_request_policy` | `NONE` | Origin request policy selection. |
| `response_headers_policy` | `NONE` | Response headers policy selection. |

Supported viewer protocol policies:

- `allow-all`
- `redirect-to-https`
- `https-only`

#### Policy selection types

Each cache behavior supports three independent policy selections:

- `cache_policy`
- `origin_request_policy`
- `response_headers_policy`

Supported selection types:

| Type | Description |
|---|---|
| `NONE` | No additional policy association. For cache policy, the AWS managed CachingDisabled policy is used. |
| `MANAGED` | Looks up an AWS-managed policy by name. |
| `EXISTING` | Uses an existing policy ID supplied by the caller. |
| `CUSTOM` | Creates a custom policy using the supplied configuration. |

Example using AWS-managed policies:


cache_policy = {
  type         = "MANAGED"
  managed_name = "CachingOptimized"
}

origin_request_policy = {
  type         = "MANAGED"
  managed_name = "CORS-S3Origin"
}

response_headers_policy = {
  type         = "NONE"
}


Example using an existing policy:


cache_policy = {
  type      = "EXISTING"
  policy_id = "existing-policy-id"
}


For `CUSTOM`, provide the policy configuration under the `custom` attribute. The custom policy name must be unique across the default and ordered behaviors.

### 5.5 Ordered cache behaviors

Variable: `ordered_cache_behaviors`

Default:


ordered_cache_behaviors = {}


Ordered behaviors allow different paths to use different origins, methods, policies, and function associations.

Example:

ordered_cache_behaviors = {
  api_behavior = {
    path_pattern           = "/api/*"
    target_origin_key      = "application_origin"
    viewer_protocol_policy = "https-only"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    compress = true

    cache_policy = {
      type = "NONE"
    }

    origin_request_policy = {
      type         = "MANAGED"
      managed_name = "AllViewerExceptHostHeader"
    }

    response_headers_policy = {
      type = "NONE"
    }

    function_associations = []
  }
}


Each ordered behavior must include:

- `path_pattern`
- `target_origin_key`

The other behavior settings use the same defaults and policy selection options as the default behavior.

### 5.6 Custom domains and TLS certificates

| Variable | Type | Default | Description |
|---|---|---|---|
| `use_default_certificate` | bool | `null` | Uses the default CloudFront certificate when enabled. |
| `acm_certificate_arn` | string | `null` | Existing ACM certificate ARN. |
| `minimum_protocol_version` | string | `null` | Minimum viewer TLS protocol. |

Default CloudFront certificate example:


distribution_aliases    = []
use_default_certificate = true
acm_certificate_arn     = null
minimum_protocol_version = "TLSv1.2_2021"


Custom domain example:


distribution_aliases = [
  "app.example.com"
]

use_default_certificate = false

acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

minimum_protocol_version = "TLSv1.2_2021"


Important:

- The ACM certificate must exist in `us-east-1`.
- The certificate must cover all configured alternate domain names.
- The certificate must be issued and valid.
- DNS records must be configured separately.
- The module does not create or validate ACM certificates.

### 5.7 Custom error responses

Variable: `custom_error_responses`

Default:


custom_error_responses = []


Example:


custom_error_responses = [
  {
    error_code            = 403
    response_page_path    = "/Error.HTML"
    response_code         = 403
    error_caching_min_ttl = 10
  },
  {
    error_code            = 404
    response_page_path    = "/Error.HTML"
    response_code         = 404
    error_caching_min_ttl = 10
  }
]


| Attribute | Required | Default |
|---|---|---|
| `error_code` | Yes | — |
| `response_code` | No | AWS/provider behavior |
| `response_page_path` | No | AWS/provider behavior |
| `error_caching_min_ttl` | No | `10` |

### 5.8 Geographic restrictions

| Variable | Type | Default | Supported values |
|---|---|---|---|
| `geo_restriction_type` | string | `none` | `none`, `whitelist`, `blacklist` |
| `geo_restriction_locations` | list(string) | `[]` | ISO country codes. |

Example:


geo_restriction_type = "whitelist"

geo_restriction_locations = [
  "IN",
  "US",
  "GB"
]


When the restriction type is `none`, all geographic locations are allowed.

### 5.9 CloudFront Functions

Variable: `cloudfront_functions`

Default:


cloudfront_functions = {}


Example:


cloudfront_functions = {
  url_rewrite = {
    name    = "poc-url-rewrite"
    runtime = "cloudfront-js-2.0"
    comment = "Rewrite website root requests"
    publish = true

    code = <<-EOT
      function handler(event) {
        var request = event.request;

        if (request.uri === "/") {
          request.uri = "/index.html";
        }

        return request;
      }
    EOT
  }
}


| Attribute | Default | Supported values |
|---|---|---|
| `name` | Required | 1–64 characters; letters, numbers, `_`, `-`. |
| `runtime` | `cloudfront-js-2.0` | `cloudfront-js-1.0`, `cloudfront-js-2.0`. |
| `comment` | `""` | Optional description. |
| `publish` | `true` | `true` or `false`. |
| `code` | Required | Function source code. |

Associate a function with a cache behavior using:


function_associations = [
  {
    event_type   = "viewer-request"
    function_key = "url_rewrite"
  }
]


Supported event types:

- `viewer-request`
- `viewer-response`

The `function_key` must match a key in `cloudfront_functions`. Associated functions must have `publish = true`.

### 5.10 AWS WAF association

| Variable | Type | Default | Description |
|---|---|---|---|
| `waf_enabled` | bool | `null` | Enables WAF association. |
| `waf_web_acl_arn` | string | `null` | Existing CloudFront-scope WAF Web ACL ARN. |

Example:


waf_enabled = true

waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example-web-acl/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"


The Web ACL must:

- Already exist.
- Use `CLOUDFRONT` scope.
- Be configured in `us-east-1`.

The module associates the Web ACL but does not create its rules, IP sets, or Web ACL resource.

### 5.11 CloudFront access logging

Logging is disabled by default.

| Variable | Type | Default | Description |
|---|---|---|---|
| `enable_logging` | bool | `false` | Enables or disables access logging. |
| `logging_destination_type` | string | `S3` | Logging destination type. |
| `existing_s3_bucket_name` | string | `null` | Existing S3 logging bucket. |
| `logging_s3_bucket_region` | string | `us-east-1` | Region of the existing logging bucket. |
| `existing_cloudwatch_log_group_name` | string | `null` | Existing CloudWatch Logs log group. |
| `existing_firehose_stream_name` | string | `null` | Existing Firehose delivery stream. |
| `logging_source_name` | string | `cloudfront-access-logs-source` | Standard logging v2 source name. |
| `logging_destination_name` | string | `cloudfront-access-logs-destination` | Standard logging v2 destination name. |
| `logging_output_format` | string | `json` | Standard logging v2 output format. |
| `logging_s3_prefix` | string | `""` | Prefix for legacy S3 logging. |
| `logging_include_cookies` | bool | `false` | Includes cookies in legacy logs. |
| `logging_s3_suffix_path` | string | `null` | Optional custom suffix for standard logging v2 S3 delivery. |
| `logging_s3_hive_compatible_path` | bool | `false` | Enables Hive-compatible S3 paths. |

Supported destination types:

- `S3`
- `CLOUDWATCH_LOGS`
- `KINESIS_FIREHOSE`
- `LEGACY_S3`

Supported standard logging v2 output formats:

- `json`
- `plain`
- `w3c`
- `raw`
- `parquet`

`parquet` is supported only for S3 destinations.

#### Example: Standard logging v2 to S3


enable_logging           = true
logging_destination_type = "S3"

existing_s3_bucket_name  = "existing-cloudfront-logs"
logging_s3_bucket_region = "ap-southeast-2"

logging_output_format          = "json"
logging_s3_suffix_path         = "cloudfront/"
logging_s3_hive_compatible_path = false


#### Example: Standard logging v2 to CloudWatch Logs


enable_logging           = true
logging_destination_type = "CLOUDWATCH_LOGS"

existing_cloudwatch_log_group_name = "/aws/cloudfront/access-logs"


#### Example: Standard logging v2 to Kinesis Data Firehose


enable_logging           = true
logging_destination_type = "KINESIS_FIREHOSE"

existing_firehose_stream_name = "cloudfront-access-logs"


#### Example: Legacy S3 logging


enable_logging           = true
logging_destination_type = "LEGACY_S3"

existing_s3_bucket_name  = "existing-cloudfront-logs"
logging_s3_bucket_region = "ap-southeast-2"

logging_s3_prefix     = "cloudfront/"
logging_include_cookies = false


#### Disable logging


enable_logging = false


Logging destinations must exist before applying the module. The module creates the CloudFront logging delivery configuration but does not create the destination bucket, log group, or Firehose stream.

For standard logging v2, the delivery resources are configured in `us-east-1`. The destination must also have the required permissions for CloudFront log delivery.

### 5.12 Tags

Variable: `tags`

Default:


tags = null


Example:


tags = {
  Environment = "Dev"
  ManagedBy   = "Terraform"
  Project     = "CloudFront"
  Owner       = "CloudOps"
}


Tags are applied to supported resources created by the module.

## 6. Outputs

The root module exposes the following outputs.

| Output | Description |
|---|---|
| `cloudfront_distribution_id` | ID of the CloudFront distribution. |
| `cloudfront_distribution_arn` | ARN of the CloudFront distribution. |
| `cloudfront_distribution_domain_name` | CloudFront-generated distribution domain name. |
| `cloudfront_distribution_hosted_zone_id` | CloudFront hosted zone ID, useful when creating Route 53 alias records. |
| `cloudfront_distribution_status` | Current distribution status. |
| `cloudfront_waf_web_acl_arn` | ARN of the associated WAF Web ACL; null when not associated. |
| `cloudfront_pricing_model` | Selected pricing model. |

Example output usage:


output "distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "distribution_id" {
  value = module.cloudfront.cloudfront_distribution_id
}


The child module also defines outputs for created CloudFront Functions, custom policy IDs, logging delivery resources, distribution status, and pricing subscription details. These are not currently re-exported by the root module.

## 7. Complete example configuration

The following example creates a CloudFront distribution using an existing private S3 REST origin, OAC, HTTPS redirection, a managed cache policy, WAF association, and standard logging v2 to an existing S3 bucket.


# AWS Region
aws_region = "us-east-1"

# Pricing
pricing = {
  model = "PAY_AS_YOU_GO"
}

# Existing S3 Origin
s3_bucket_name   = "my-static-site-bucket"
s3_bucket_arn    = "arn:aws:s3:::my-static-site-bucket"
s3_bucket_region = "ap-southeast-2"

origin_access_controls = {
  s3_oac = {
    name             = "cloudfront-s3-oac"
    description      = "OAC for private S3 origin"
    origin_type      = "s3"
    signing_behavior = "always"
  }
}

origins = {
  s3_origin = {
    domain_name               = "my-static-site-bucket.s3.ap-southeast-2.amazonaws.com"
    origin_type               = "S3"
    origin_access_control_key = "s3_oac"
  }
}

origin_settings = {}

# Distribution
distribution_enabled = true
distribution_comment = "Static website CloudFront distribution"

distribution_aliases = []

default_root_object = "index.html"

price_class     = "PriceClass_100"
http_version    = "http2and3"
is_ipv6_enabled = true

# Default Cache Behavior
default_cache_behavior = {
  target_origin_key      = "s3_origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]
  compress               = true

  cache_policy = {
    type         = "MANAGED"
    managed_name = "CachingOptimized"
  }

  origin_request_policy = {
    type = "NONE"
  }

  response_headers_policy = {
    type = "NONE"
  }
}

ordered_cache_behaviors = {}

# Certificate
use_default_certificate  = true
minimum_protocol_version = "TLSv1.2_2021"

# Error Responses
custom_error_responses = [
  {
    error_code            = 403
    response_page_path    = "/Error.HTML"
    response_code         = 403
    error_caching_min_ttl = 10
  },
  {
    error_code            = 404
    response_page_path    = "/Error.HTML"
    response_code         = 404
    error_caching_min_ttl = 10
  }
]

# WAF
waf_enabled     = true
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Logging
enable_logging           = true
logging_destination_type = "S3"

existing_s3_bucket_name  = "existing-cloudfront-logs"
logging_s3_bucket_region = "ap-southeast-2"

logging_output_format  = "json"
logging_s3_suffix_path = "cloudfront/"

# Functions
cloudfront_functions = {}

# Tags
tags = {
  Environment = "POC"
  ManagedBy   = "Terraform"
  Project     = "CloudFront-Module"
}


## 8. Important considerations

1. Use an S3 REST endpoint for private S3 origins with OAC. S3 website endpoints are custom origins and do not use OAC.
2. The S3 origin bucket must remain private and must allow the CloudFront distribution through its bucket policy.
3. Review existing S3 bucket policy statements before applying because the root module manages the bucket policy.
4. ACM certificates for CloudFront must be provisioned in `us-east-1`.
5. Custom domain DNS records are managed separately.
6. WAF Web ACLs must use CloudFront scope and be provisioned in `us-east-1`.
7. Logging destinations must exist before enabling logging.
8. Standard logging v2 delivery resources are configured in `us-east-1`.
9. Flat-rate pricing requires an existing WAF Web ACL association and has plan-specific usage-level restrictions.
10. Review the Terraform plan before applying changes to an existing distribution.

## 10. Scope and limitations

The current module supports the features documented above.

The following are outside the current implementation scope:

- S3 bucket creation and management.
- ACM certificate creation and DNS validation.
- Route 53 hosted zone and DNS record creation.
- WAF Web ACL and rule creation.
- VPC and subnet creation.
- ALB, NLB, and API Gateway creation.
- Lambda@Edge.
- CloudFront VPC origins.
- Signed URLs and signed cookies.
- Field-level encryption.
- Continuous deployment policies.
- gRPC configuration.

**Module purpose:** Provide a reusable Terraform implementation for provisioning and configuring CloudFront distributions while integrating with existing AWS networking, storage, security, certificate, DNS, and logging resources.