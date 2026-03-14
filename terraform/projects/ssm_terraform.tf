# SSM Parameters for Terraform CI/CD Secrets
# These parameters are used by the GitHub Actions workflow to authenticate
# with cloud providers and configure infrastructure

locals {
  terraform_parameters = {
    # Cloud Provider Tokens
    "/infra/terraform/providers/hcloud_token" = {
      description = "Hetzner Cloud API token"
      type        = "SecureString"
    }
    "/infra/terraform/providers/digitalocean_token" = {
      description = "DigitalOcean API token"
      type        = "SecureString"
    }

    # Server Configuration
    "/infra/terraform/servers/hetzner_server_1_ipv4" = {
      description = "Hetzner server 1 IPv4 address"
      type        = "String"
    }
    "/infra/terraform/servers/digitalocean_droplet_1_ipv4" = {
      description = "DigitalOcean droplet 1 IPv4 address"
      type        = "String"
    }
    "/infra/terraform/servers/hcloud_ssh_key" = {
      description = "Hetzner Cloud SSH public key"
      type        = "SecureString"
    }

    # DNS Configuration - Schlüsselmomente
    "/infra/terraform/dns/schluesselmomente_dkim" = {
      description = "DKIM record for schluesselmomente-freiburg.de"
      type        = "SecureString"
    }
    "/infra/terraform/dns/schluesselmomente_zmail_dkim" = {
      description = "Zoho Mail DKIM for schluesselmomente-freiburg.de"
      type        = "SecureString"
    }
    "/infra/terraform/dns/schluesselmomente_spf" = {
      description = "SPF record for schluesselmomente-freiburg.de"
      type        = "SecureString"
    }
    "/infra/terraform/dns/schluesselmomente_zoho_verification" = {
      description = "Zoho verification TXT for schluesselmomente-freiburg.de"
      type        = "SecureString"
    }

    # DNS Configuration - Portfolio
    "/infra/terraform/dns/portfolio_netlify_challenge" = {
      description = "Netlify DNS challenge for portfolio"
      type        = "SecureString"
    }

    # AWS Account
    "/infra/terraform/aws/account_id" = {
      description = "AWS Account ID"
      type        = "String"
    }

    # SSH Configuration
    "/infra/terraform/ssh_private_key_path" = {
      description = "Path to SSH private key for server access"
      type        = "String"
    }
  }
}

# Create all SSM parameters with dummy values
# Actual values must be set manually via AWS Console or CLI after creation
resource "aws_ssm_parameter" "terraform_secrets" {
  for_each = local.terraform_parameters

  name        = each.key
  description = each.value.description
  type        = each.value.type
  value       = "DUMMY_VALUE_TO_BE_UPDATED_MANUALLY"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Environment = "Production"
    Project     = "terraform-infrastructure"
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD secrets for GitHub Actions"
  }
}

# Output the parameter names for reference
output "terraform_ssm_parameters" {
  description = "List of SSM parameter paths created for Terraform CI/CD"
  value       = [for param in aws_ssm_parameter.terraform_secrets : param.name]
}
