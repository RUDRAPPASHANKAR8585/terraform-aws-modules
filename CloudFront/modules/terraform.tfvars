/*
pricing = {
  model = "PAY_AS_YOU_GO"
}
pricing = {
  model = "FLAT_RATE"

  flat_rate = {
    plan_tier     = "PRO"
    approval_mode = "MANUAL"
    usage_level   = "CF_PREMIUM_L6"
  }
}

# --------------------------------------------------
# Origin Access Control
# --------------------------------------------------

origin_access_controls = {
  s3_oac = {
    name             = "cloudfront-poc-s3-oac"
    description      = "OAC for private S3 origin"
    origin_type      = "s3"
    signing_behavior = "always"
  }
}

# --------------------------------------------------
# CloudFront Origins
# --------------------------------------------------

origins = {
  s3_origin = {
    domain_name               = "shankar-poc-s3-700030738273-ap-south-1.amazonaws.com"
    origin_type               = "S3"
    origin_access_control_key = "s3_oac"
  }
}

# --------------------------------------------------
# Origin Settings
# --------------------------------------------------

origin_settings = {}

# --------------------------------------------------
# Default Cache Behavior
# --------------------------------------------------

default_cache_behavior = {
  target_origin_key      = "s3_origin"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]
  compress               = true

  cache_policy = {
    type         = "CUSTOM"
    managed_name = null
    policy_id    = null

    custom = {
      name        = "poc-mixed-cache-policy"
      comment     = "Mixed policy test cache policy"
      min_ttl     = 0
      default_ttl = 3600
      max_ttl     = 86400

      cookies_config = {
        cookie_behavior = "none"
        items           = []
      }

      headers_config = {
        header_behavior = "none"
        items           = []
      }

      query_strings_config = {
        query_string_behavior = "none"
        items                 = []
      }

      enable_accept_encoding_gzip   = true
      enable_accept_encoding_brotli = true
    }
  }

  function_associations = [
    {
      event_type   = "viewer-request"
      function_key = "url_rewrite"
    }
  ]

  origin_request_policy = {
    type         = "MANAGED"
    managed_name = "CORS-S3Origin"
    policy_id    = null
    custom       = null
  }

  response_headers_policy = {
    type         = "NONE"
    managed_name = null
    policy_id    = null
    custom       = null
  }
}

# --------------------------------------------------
# Ordered Cache Behaviors
# --------------------------------------------------

ordered_cache_behaviors = {
  api_behavior = {
    path_pattern           = "/api/*"
    target_origin_key      = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy = {
      type         = "MANAGED"
      managed_name = "CachingOptimized"
      policy_id    = null
      custom       = null
    }

    origin_request_policy = {
      type         = "MANAGED"
      managed_name = "CORS-S3Origin"
      policy_id    = null
      custom       = null
    }

    response_headers_policy = {
      type         = "NONE"
      managed_name = null
      policy_id    = null
      custom       = null
    }
  }

  static_behavior = {
    path_pattern           = "/static/*"
    target_origin_key      = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy = {
      type         = "NONE"
      managed_name = null
      policy_id    = null
      custom       = null
    }

    origin_request_policy = {
      type         = "NONE"
      managed_name = null
      policy_id    = null
      custom       = null
    }

    response_headers_policy = {
      type         = "CUSTOM"
      managed_name = null
      policy_id    = null

      custom = {
        name    = "poc-custom-response-headers-policy"
        comment = "POC custom response headers policy"

        security_headers_config = {
          content_type_options = {
            override = true
          }

          frame_options = {
            frame_option = "DENY"
            override     = true
          }

          referrer_policy = {
            referrer_policy = "strict-origin-when-cross-origin"
            override        = true
          }

          strict_transport_security = {
            access_control_max_age_sec = 31536000
            include_subdomains         = true
            preload                    = true
            override                   = true
          }
        }

        custom_headers_config = {
          items = [
            {
              header   = "X-Environment"
              value    = "POC"
              override = true
            }
          ]
        }

        remove_headers_config = {
          items = [
            {
              header = "Server"
            }
          ]
        }
      }
    }
  }
}

# --------------------------------------------------
# Distribution Settings
# --------------------------------------------------

distribution_enabled = true
distribution_comment = "CloudFront policy selection POC - Mixed behavior test"
price_class          = "PriceClass_100"
http_version         = "http2and3"
is_ipv6_enabled      = true

# --------------------------------------------------
# Geo Restrictions
# --------------------------------------------------

geo_restriction_type      = "none"
geo_restriction_locations = []

# --------------------------------------------------
# Viewer Certificate
# --------------------------------------------------

use_default_certificate  = true
minimum_protocol_version = "TLSv1.2_2021"

# --------------------------------------------------
# Tags
# --------------------------------------------------

tags = {
  Environment = "POC"
  ManagedBy   = "Terraform"
  Project     = "CloudFront-Module"
}

# --------------------------------------------------
# Custom Error Responses
# --------------------------------------------------


default_root_object = "index.html"

custom_error_responses = [
  {
    error_code            = 403
    response_page_path    = "/Error.HTML"
    error_caching_min_ttl = 10
  },
  {
    error_code            = 404
    response_page_path    = "/Error.HTML"
    error_caching_min_ttl = 10
  }
]

# --------------------------------------------------
# CloudFront Functions
# --------------------------------------------------

cloudfront_functions = {
  url_rewrite = {
    name    = "poc-url-rewrite"
    runtime = "cloudfront-js-2.0"
    comment = "POC URL rewrite function"
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

# --------------------------------------------------
# CloudFront Logging
# --------------------------------------------------

cloudfront_logging = {
  legacy = {
    bucket_domain_name = "shankar-poc-s3-700030738273-ap-south-1.amazonaws.com"
    prefix             = "cloudfront/access-logs/"
    include_cookies    = false
  }

  v2 = {
    source_name              = "poc-cloudfront-log-source"
    destination_name         = "poc-cloudfront-s3-destination"
    destination_resource_arn = "arn:aws:s3:::shankar-poc-s3-700030738273-ap-south-1"

    output_format   = "json"
    field_delimiter = "\t"

    record_fields = [
      "date",
      "time",
      "x-edge-location",
      "sc-bytes",
      "c-ip",
      "cs-method",
      "cs(Host)",
      "cs-uri-stem",
      "sc-status",
      "cs(Referer)",
      "cs(User-Agent)",
      "cs-uri-query",
      "x-edge-result-type",
      "x-edge-request-id"
    ]

    s3_delivery_configuration = {
      suffix_path                 = "cloudfront-v2/"
      enable_hive_compatible_path = false
    }
  }
}

# --------------------------------------------------
# WAF Association
# --------------------------------------------------


waf_enabled     = true
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:700030738273:global/webacl/novartis-poc-web-acl/1900aec9-0789-4af3-925c-3a3dc9893a88"
*/