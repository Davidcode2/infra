# Centralized SSM parameter path definitions
# This ensures consistency across IAM policies and makes maintenance easier
# When adding a new application, add its path to the appropriate list below

locals {
  aws_region    = "eu-central-1"
  account_id    = var.aws_account_id
  ssm_base_path = "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter"

  # Infrastructure paths - needed by terraform-ci-role and ci-role
  infra_paths = [
    "${local.ssm_base_path}/ssh/*",
    "${local.ssm_base_path}/compute/*",
  ]

  # Application paths - needed by all roles
  # Note: Patterns vary based on original implementation:
  # - ci-role uses wildcard suffix (*)
  # - terraform-ci-role and ESO use path prefix (/*)
  app_patterns = {
    immoly              = "immoly"
    joy_alemazung       = "joy_alemazung"
    schluesselmomente   = "schluesselmomente"
    umami               = "umami"
    home_at_sea         = "home_at_sea"
    teachme             = "teachme"
    message_router      = "message-router"
    mimis_kreativstudio = "mimis-kreativstudio"
    business_website    = "business-website"
    paperless           = "paperless"
    vogthof             = "vogthof"
  }

  # ci-role patterns (wildcard suffix *)
  ci_role_app_paths = [
    for app_name in values(local.app_patterns) : "${local.ssm_base_path}/${app_name}*"
  ]

  # Full paths for terraform-ci-role (path prefix /*)
  terraform_ci_infra_paths = concat(
    local.infra_paths,
    [
      "${local.ssm_base_path}/infra/terraform",
      "${local.ssm_base_path}/infra/terraform/*",
    ]
  )

  terraform_ci_app_paths = [
    for app_name in values(local.app_patterns) : "${local.ssm_base_path}/${app_name}*"
  ]

  terraform_ci_ssm_paths = concat(local.terraform_ci_infra_paths, local.terraform_ci_app_paths)

  # ESO paths (path prefix /*, uses data.aws_caller_identity.current.account_id)
  eso_ssm_paths = [
    for app_name in values(local.app_patterns) : "arn:aws:ssm:${local.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${app_name}/*"
  ]
}

