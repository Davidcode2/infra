#################
# paperless-ngx #
#################
resource "aws_ssm_parameter" "paperless_db_password" {
  name        = "/paperless/db/password"
  description = "Database password for paperless-ngx"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "paperless_secret_key" {
  name        = "/paperless/secret-key"
  description = "Secret key for paperless-ngx session security"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
