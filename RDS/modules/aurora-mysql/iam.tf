
data "aws_iam_policy_document" "monitoring_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "monitoring" {
  count = (
    var.monitoring_interval > 0 &&
    var.monitoring_role_arn == null
  ) ? 1 : 0

  name               = local.monitoring_role_name
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = (
    var.monitoring_interval > 0 &&
    var.monitoring_role_arn == null
  ) ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

locals {
  effective_monitoring_role_arn = (
    var.monitoring_role_arn != null
    ? var.monitoring_role_arn
    : try(aws_iam_role.monitoring[0].arn, null)
  )
}
