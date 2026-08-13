#################
# oauth2-proxy   #
#################

resource "aws_ssm_parameter" "oauth2_proxy_cookie_secret" {
  name        = "/oauth2-proxy/cookie-secret"
  description = "Cookie secret for oauth2-proxy (32+ bytes, base64-encoded)"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
