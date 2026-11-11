# Look up an existing CloudWatch Logs log group
data "aws_cloudwatch_log_group" "existing" {
  count = (
    var.enable_logging &&
    var.logging_destination_type == "CLOUDWATCH_LOGS"
  ) ? 1 : 0

  name = var.existing_cloudwatch_log_group_name
}

# Look up an existing Amazon Data Firehose delivery stream
data "aws_kinesis_firehose_delivery_stream" "existing" {
  count = (
    var.enable_logging &&
    var.logging_destination_type == "FIREHOSE"
  ) ? 1 : 0

  name = var.existing_firehose_stream_name
}

# Retrieve the current AWS partition
data "aws_partition" "current" {}

# Resolve the selected logging destination ARN
locals {
  logging_destination_arn = (
    !var.enable_logging
    ? null
    : var.logging_destination_type == "CLOUDWATCH_LOGS"
    ? data.aws_cloudwatch_log_group.existing[0].arn
    : var.logging_destination_type == "S3"
    ? "arn:${data.aws_partition.current.partition}:s3:::${var.existing_s3_bucket_name}"
    : data.aws_kinesis_firehose_delivery_stream.existing[0].arn
  )
}