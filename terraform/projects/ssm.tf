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

resource "aws_ssm_parameter" "immoly_db_user" {
  name        = "/immoly/db/user"
  description = "Database user for immoly"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "immoly_db_password" {
  name        = "/immoly/db/password"
  description = "Database password for immoly"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "immoly_db_name" {
  name        = "/immoly/db/name"
  description = "Database name for immoly"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
