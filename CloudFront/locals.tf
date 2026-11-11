
# --------------------------------------------------
# Existing Logging Destinations
# --------------------------------------------------

data "aws_s3_bucket" "logging" {
  provider = aws.logging_s3

  count = (
    var.enable_logging &&
    contains(["S3", "LEGACY_S3"], var.logging_destination_type)
  ) ? 1 : 0

  bucket = var.existing_s3_bucket_name
}

data "aws_cloudwatch_log_group" "logging" {
  count = (
    var.enable_logging &&
    var.logging_destination_type == "CLOUDWATCH_LOGS"
  ) ? 1 : 0

  name = var.existing_cloudwatch_log_group_name
}

data "aws_kinesis_firehose_delivery_stream" "logging" {
  count = (
    var.enable_logging &&
    var.logging_destination_type == "KINESIS_FIREHOSE"
  ) ? 1 : 0

  name = var.existing_firehose_stream_name
}

# --------------------------------------------------
# CloudFront Logging Configuration
# --------------------------------------------------

locals {
  cloudfront_logging = {
    legacy = (
      var.enable_logging &&
      var.logging_destination_type == "LEGACY_S3"
      ) ? {
      bucket_domain_name = data.aws_s3_bucket.logging[0].bucket_domain_name
      prefix             = var.logging_s3_prefix
      include_cookies    = var.logging_include_cookies
    } : null

    v2 = (
      var.enable_logging &&
      var.logging_destination_type != "LEGACY_S3"
      ) ? {
      source_name      = var.logging_source_name
      destination_name = var.logging_destination_name

      destination_resource_arn = (
        var.logging_destination_type == "S3"
        ? data.aws_s3_bucket.logging[0].arn
        : var.logging_destination_type == "CLOUDWATCH_LOGS"
        ? data.aws_cloudwatch_log_group.logging[0].arn
        : data.aws_kinesis_firehose_delivery_stream.logging[0].arn
      )

      output_format = var.logging_output_format

      s3_delivery_configuration = (
        var.logging_destination_type == "S3"
        ) ? {
        suffix_path                 = var.logging_s3_suffix_path
        enable_hive_compatible_path = var.logging_s3_hive_compatible_path
      } : null
    } : null
  }
}
