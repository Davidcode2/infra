####################
# vacation-product #
####################

resource "aws_ssm_parameter" "vacation_product_db_user" {
  name        = "/vacation-product/db/user"
  description = "PostgreSQL user for Vacation Studio"
  type        = "String"
  value       = "vacation_product"
}

resource "aws_ssm_parameter" "vacation_product_db_name" {
  name        = "/vacation-product/db/name"
  description = "PostgreSQL database name for Vacation Studio"
  type        = "String"
  value       = "vacation_product"
}

resource "aws_ssm_parameter" "vacation_product_db_password" {
  name        = "/vacation-product/db/password"
  description = "PostgreSQL password for Vacation Studio"
  type        = "SecureString"
  value       = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
