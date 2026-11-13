# Register the CloudFront distribution as a CloudWatch Logs delivery source.
# CloudFront standard logging v2 API calls must use us-east-1.

resource "aws_cloudwatch_log_delivery_source" "cloudfront" {
  count = var.cloudfront_logging.v2 == null ? 0 : 1

  region       = "us-east-1"
  name         = var.cloudfront_logging.v2.source_name
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.this.arn

  tags = var.tags
}

# Register the existing destination for CloudFront access logs.
# The destination itself (S3 bucket, CloudWatch log group, or Firehose stream)
# is managed outside this module.

resource "aws_cloudwatch_log_delivery_destination" "cloudfront" {
  count = var.cloudfront_logging.v2 == null ? 0 : 1

  region        = "us-east-1"
  name          = var.cloudfront_logging.v2.destination_name
  output_format = var.cloudfront_logging.v2.output_format

  delivery_destination_configuration {
    destination_resource_arn = var.cloudfront_logging.v2.destination_resource_arn
  }

  tags = var.tags
}

# Connect the CloudFront delivery source to the configured destination.

resource "aws_cloudwatch_log_delivery" "cloudfront" {
  count = var.cloudfront_logging.v2 == null ? 0 : 1

  region                   = "us-east-1"
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront[0].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront[0].arn

  field_delimiter = (
    var.cloudfront_logging.v2.output_format == "json"
    ? null
    : var.cloudfront_logging.v2.field_delimiter
  )
  record_fields = var.cloudfront_logging.v2.record_fields

  dynamic "s3_delivery_configuration" {
    for_each = (
      var.cloudfront_logging.v2.s3_delivery_configuration == null
      ? []
      : [var.cloudfront_logging.v2.s3_delivery_configuration]
    )

    content {
      suffix_path                 = s3_delivery_configuration.value.suffix_path
      enable_hive_compatible_path = s3_delivery_configuration.value.enable_hive_compatible_path
    }
  }

  tags = var.tags
}