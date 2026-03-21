#################
# message-router#
#################

resource "aws_ssm_parameter" "message_router_resend_api_key" {
  name        = "/message-router/resend-api-key"
  description = "Resend API key for message-router"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "message_router_api_key" {
  name        = "/message-router/api-key"
  description = "API key for message-router frontend authentication"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "message_router_from_email" {
  name        = "/message-router/from-email"
  description = "Sender email address for message-router"
  type        = "String"
  value       = "noreply@jakob-lingel.dev"
  lifecycle {
    ignore_changes = [value]
  }
}

# Resend API key with full access (for domain management)
# Note: The actual value must be set manually in AWS Console
resource "aws_ssm_parameter" "message_router_resend_api_key_full" {
  name        = "/message-router/resend-api-key-full"
  description = "Resend API key with full access for domain management"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
