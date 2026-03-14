resource "aws_iam_role" "ci-role" {
  name = "ci-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Davidcode2/blog:ref:refs/heads/main",
              "repo:Davidcode2/immoly:ref:refs/heads/main",
              "repo:Davidcode2/joy_alemazung:ref:refs/heads/main"
            ]
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ci-policy" {
  name = "ci-policy"
  role = aws_iam_role.ci-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/ssh/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/compute/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/immoly*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/joy_alemazung*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/home_at_sea*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/teachme*"
        ]
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# Dedicated IAM role for Terraform CI/CD
resource "aws_iam_role" "terraform_ci_role" {
  name = "terraform-ci-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Davidcode2/infra:ref:refs/heads/main",
              "repo:Davidcode2/infra:pull_request"
            ]
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Terraform CI Role"
    Environment = "Infrastructure"
    Purpose     = "GitHub Actions OIDC authentication for Terraform"
  }
}

resource "aws_iam_role_policy" "terraform_ci_policy" {
  name = "terraform-ci-policy"
  role = aws_iam_role.terraform_ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/infra/terraform",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/infra/terraform/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/compute/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/ssh/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/teachme/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/immoly/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/joy_alemazung/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/schluesselmomente/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/umami/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::jakob-terraform-state",
          "arn:aws:s3:::jakob-terraform-state/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:eu-central-1:${var.aws_account_id}:table/terraform-state-lock"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:GetUser",
          "iam:GetUserPolicy"
        ]
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:role/ci-role",
          "arn:aws:iam::${var.aws_account_id}:role/terraform-ci-role",
          "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com",
          "arn:aws:iam::${var.aws_account_id}:user/external-secrets-ssm"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "external_secrets" {
  name = "external-secrets-ssm"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user_policy" "external_secrets_ssm" {
  name = "external-secrets-ssm-read"
  user = aws_iam_user.external_secrets.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/immoly/*",
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/joy_alemazung/*",
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/schluesselmomente/*",
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/umami/*",
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/home_at_sea/*",
          "arn:aws:ssm:eu-central-1:${data.aws_caller_identity.current.account_id}:parameter/teachme*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

