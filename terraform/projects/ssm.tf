locals {
  server_name   = "hetzner-cloud-server-1"
}

resource "aws_ssm_parameter" "hetzner_cloud_server_1_ipv4" {
  name        = "/compute/${local.server_name}/host"
  description = "Host ${local.server_name}"
  type        = "String"
  value       = var.hetzner_cloud_server_1_ipv4

  tags = {
    Environment = "Production"
    Project     = local.server_name
  }
}

resource "aws_ssm_parameter" "hetzner_cloud_server_1_private_ssh_key" {
  name        = "/ssh/${local.server_name}/deployment_private_ssh_key"
  description = "Private SSH key for ${local.server_name}"
  type        = "SecureString"
  value       = var.hetzner_cloud_server_1_deployment_private_ssh_key

  tags = {
    Environment = "Production"
    Project     = local.server_name
  }
}

resource "aws_ssm_parameter" "hetzner_cloud_server_1_openssl_private_ssh_key" {
  name        = "/ssh/${local.server_name}/openssl_deployment_private_ssh_key"
  description = "Private SSH key for ${local.server_name}"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Environment = "Production"
    Project     = local.server_name
  }
}
