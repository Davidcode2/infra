#################
# saas/resend   #
#################

# Resend API key for domain management
# Note: The actual value is managed manually in AWS Console
resource "aws_ssm_parameter" "resend_api_key" {
  name        = "/saas/resend/api-key"
  description = "Resend API key for saas/resend domain management"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
