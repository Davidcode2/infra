#############
# vogthof   #
#############

resource "aws_ssm_parameter" "vogthof_recipient_email" {
  name        = "/vogthof/notifications/recipient_email_address"
  description = "Recipient email address for vogthof form submissions"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
