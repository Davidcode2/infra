#################
# resend        #
#################

# Resend API key with full access (for domain management)
# Note: The actual value must be set manually in AWS Console
resource "aws_ssm_parameter" "resend_api_key_full" {
  name        = "/resend/api-key-full"
  description = "Resend API key with full access for domain management"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
