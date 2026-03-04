#################
# teachme       #
#################

# Backend Database
resource "aws_ssm_parameter" "teachme_backend_db_password" {
  name        = "/teachme/backend/db_password"
  description = "Database password for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_db_username" {
  name        = "/teachme/backend/db_username"
  description = "Database username for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

# Backend Secrets
resource "aws_ssm_parameter" "teachme_backend_jwt_secret" {
  name        = "/teachme/backend/jwt_secret"
  description = "JWT secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_jwt_refresh_secret" {
  name        = "/teachme/backend/jwt_refresh_secret"
  description = "JWT refresh secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_session_secret" {
  name        = "/teachme/backend/session_secret"
  description = "Session secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_stripe_test_key" {
  name        = "/teachme/backend/stripe_test_key"
  description = "Stripe test key for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_stripe_webhook_secret" {
  name        = "/teachme/backend/stripe_webhook_secret"
  description = "Stripe webhook secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_recaptcha_secret" {
  name        = "/teachme/backend/recaptcha_secret"
  description = "Recaptcha secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_gcloud_api_key" {
  name        = "/teachme/backend/gcloud_api_key"
  description = "Google Cloud API key for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_backend_keycloak_client_secret" {
  name        = "/teachme/backend/keycloak_client_secret"
  description = "Keycloak client secret for teachme backend"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

# Keycloak
resource "aws_ssm_parameter" "teachme_keycloak_admin_username" {
  name        = "/teachme/keycloak/admin_username"
  description = "Keycloak admin username"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_keycloak_admin_password" {
  name        = "/teachme/keycloak/admin_password"
  description = "Keycloak admin password"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_keycloak_db_username" {
  name        = "/teachme/keycloak/db_username"
  description = "Keycloak database username"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_keycloak_db_password" {
  name        = "/teachme/keycloak/db_password"
  description = "Keycloak database password"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_keycloak_keystore_password" {
  name        = "/teachme/keycloak/keystore_password"
  description = "Keycloak keystore password"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

# Keycloak DB (same credentials as keycloak)
resource "aws_ssm_parameter" "teachme_keycloak_db_postgres_user" {
  name        = "/teachme/keycloak-db/postgres_user"
  description = "PostgreSQL username for keycloak database"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "teachme_keycloak_db_postgres_password" {
  name        = "/teachme/keycloak-db/postgres_password"
  description = "PostgreSQL password for keycloak database"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
