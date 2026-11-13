# Configure logging for the Web ACL
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_logging ? 1 : 0

  resource_arn = aws_wafv2_web_acl.this.arn

  log_destination_configs = [
    local.logging_destination_arn
  ]
}