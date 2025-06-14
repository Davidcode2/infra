locals {
  project_handle = "schluesselmomente"
}

resource "aws_ssm_parameter" "schluesselmomente_host" {
  name        = "/${local.project_handle}/host"
  description = "Host parameter for ${local.project_handle} project"
  type        = "String"
  value       = var.hetzner_cloud_server_1_ipv4

  tags = {
    Environment = "Production"
    Project     = local.project_handle
  }
}
