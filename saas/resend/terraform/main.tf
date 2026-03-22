terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "jakob-terraform-state"
    key          = "infra/saas/resend/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "digitalocean" {
  token = data.aws_ssm_parameter.digitalocean_token.value
}

# Load DigitalOcean token from AWS SSM
data "aws_ssm_parameter" "digitalocean_token" {
  name            = "/infra/terraform/providers/digitalocean_token"
  with_decryption = true
}

# Read the Resend configuration from JSON file
# This file is created by the Node.js script after domain creation
locals {
  resend_config = try(
    jsondecode(file("${path.module}/../resend-config.json")),
    null
  )

  has_config  = local.resend_config != null
  domain_name = local.has_config ? local.resend_config.domainName : ""
  records     = local.has_config ? local.resend_config.records : []
}

# Output warning if config is missing
resource "null_resource" "check_config" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = local.has_config ? "echo '✅ resend-config.json found'" : "echo '⚠️  Warning: resend-config.json not found. Run: npm run create-domain'"
  }
}
