#################
# argocd        #
#################

resource "aws_ssm_parameter" "argocd_github_app_private_key" {
  name        = "/argocd/github-app-private-key"
  description = "GitHub App private key for ArgoCD to access private repos"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
