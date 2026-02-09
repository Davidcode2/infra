
#################
#    hetzner    #
#################
locals {
  server_name = "hetzner-cloud-server-1"
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

#################
# immoly        #
#################
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

#################
# joy_alemazung #
#################
resource "aws_ssm_parameter" "joy_alemazung_strapi_api_url" {
  name        = "/joy_alemazung/strapi/api_url"
  description = "Strapi API URL for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_api_token" {
  name        = "/joy_alemazung/strapi/api_token"
  description = "Strapi API token for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_admin_jwt_secret" {
  name        = "/joy_alemazung/strapi/admin_jwt_secret"
  description = "Strapi admin JWT secret for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_api_token_salt" {
  name        = "/joy_alemazung/strapi/api_token_salt"
  description = "Strapi API token salt for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_app_keys" {
  name        = "/joy_alemazung/strapi/app_keys"
  description = "Strapi app keys for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_db_password" {
  name        = "/joy_alemazung/strapi/db/password"
  description = "Strapi database password for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_db_encryption_key" {
  name        = "/joy_alemazung/strapi/db/encryption_key"
  description = "Strapi database encryption key for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_jwt_secret" {
  name        = "/joy_alemazung/strapi/jwt_secret"
  description = "Strapi JWT secret for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "joy_alemazung_strapi_transfer_token_salt" {
  name        = "/joy_alemazung/strapi/transfer_token_salt"
  description = "Strapi transfer token salt for joy_alemazung"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

######################
# schluesselmomente  #
######################
resource "aws_ssm_parameter" "schluesselmomente_be_mailgun_api_key" {
  name        = "/schluesselmomente/be/mailgun_api_key"
  description = "Mailgun API key for schluesselmomente backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "schluesselmomente_be_schluesselmomente_sendkey" {
  name        = "/schluesselmomente/be/schluesselmomente_sendkey"
  description = "Sendkey for schluesselmomente backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "schluesselmomente_be_mail" {
  name        = "/schluesselmomente/be/mail"
  description = "Recipient email for schluesselmomente backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

#################
# umami         #
#################
resource "aws_ssm_parameter" "umami_db_password" {
  name        = "/umami/db/password"
  description = "Database password for umami"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "umami_app_secret" {
  name        = "/umami/app_secret"
  description = "Application secret for umami"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
